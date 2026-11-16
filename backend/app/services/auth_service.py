import hashlib
import hmac
import uuid
from datetime import datetime, timedelta, timezone

from sqlalchemy import delete, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..config import get_settings
from ..db.models import (
    Bookmark,
    Progress,
    RefreshToken,
    SyncOperation,
    SyncRecord,
    User,
    UserSession,
    UserSetting,
)
from ..security import (
    create_access_token,
    hash_password,
    hash_refresh_token,
    new_refresh_token,
    verify_password,
)


class AuthError(Exception):
    def __init__(self, message: str, status: int = 400):
        super().__init__(message)
        self.status = status


# Every table that carries a user_id. There is no ON DELETE cascade on these
# relationships, so an account deletion names each one — and the list is pinned by
# test_qb003 so a new user-owned table cannot be added without deciding what happens
# to it when the account goes.
_USER_OWNED_TABLES = (
    RefreshToken,
    SyncOperation,
    SyncRecord,
    Bookmark,
    UserSetting,
    Progress,
    UserSession,
)


def _delete_user_rows(db: Session, user_id: int) -> None:
    """Children first: refresh_tokens point at user_sessions, so they go before them."""
    for model in _USER_OWNED_TABLES:
        db.execute(delete(model).where(model.user_id == user_id))


def delete_account(db: Session, user: User) -> None:
    """QB-003 — DELETE /users/me hard-deletes the account and everything hanging off it,
    in ONE transaction.

    Retention after this call is zero: no tombstone row, no bookmark, no sync record, no
    session, no refresh-token hash. `users.email` is UNIQUE, so leaving a tombstone also
    means leaving the address claimed forever, which is the other half of why the soft
    delete was wrong.
    """
    user_id = user.id
    _delete_user_rows(db, user_id)
    db.delete(user)
    db.commit()


def register(db: Session, email: str, password: str, name: str) -> User:
    email = (email or "").strip().lower()
    existing = db.scalar(select(User).where(User.email == email))
    if existing is not None and existing.deleted_at is None:
        raise AuthError("email_taken", 409)
    if existing is not None:
        # QB-002: a soft-deleted row written before QB-003 existed. Purge it and start
        # clean. Reactivating was the other option and was rejected on purpose: the
        # person registering today must not inherit yesterday's bookmarks, sessions or
        # password_hash through a row they were told was deleted.
        _delete_user_rows(db, existing.id)
        db.delete(existing)
        db.flush()
    user = User(email=email, name=name, password_hash=hash_password(password))
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        # the race between the SELECT above and this INSERT: someone else claimed the
        # canonical email first. 409, never 500.
        db.rollback()
        raise AuthError("email_taken", 409) from None
    db.refresh(user)
    return user


def login(
    db: Session,
    email: str,
    password: str,
    *,
    device_id: str = "",
    platform: str = "",
    app_version: str = "",
) -> tuple[User, str, str]:
    user = db.scalar(select(User).where(User.email == email.lower()))
    if user is None or user.deleted_at is not None or not verify_password(password, user.password_hash):
        raise AuthError("invalid_credentials", 401)
    access, refresh = issue_tokens(
        db, user, device_id=device_id, platform=platform, app_version=app_version
    )
    return user, access, refresh


def get_user(db: Session, user_id: int) -> User | None:
    user = db.get(User, user_id)
    if user is None or user.deleted_at is not None:
        return None
    return user


def issue_tokens(
    db: Session,
    user: User,
    *,
    device_id: str = "",
    platform: str = "",
    app_version: str = "",
    session: UserSession | None = None,
    family_id: str | None = None,
    raw_refresh: str | None = None,
) -> tuple[str, str]:
    settings = get_settings()
    now = datetime.now(timezone.utc)
    if session is None:
        session = UserSession(
            user_id=user.id,
            device_id=device_id[:64],
            platform=platform[:32],
            app_version=app_version[:32],
            created_at=now,
            last_seen_at=now,
        )
        db.add(session)
        db.flush()
    else:
        session.last_seen_at = now
    # raw_refresh is set only by rotate_refresh: QB-016 needs the successor a rotation
    # produced to be reproducible from the token the client presents, so a retry can be
    # handed the same one without any plaintext token at rest.
    raw = raw_refresh or new_refresh_token()
    row = RefreshToken(
        user_id=user.id,
        session_id=session.id,
        token_hash=hash_refresh_token(raw),
        family_id=family_id or str(uuid.uuid4()),
        created_at=now,
        expires_at=now + timedelta(days=settings.refresh_token_days),
    )
    db.add(row)
    db.commit()
    return create_access_token(str(user.id)), raw


def _revoke_family(db: Session, family_id: str, now: datetime) -> None:
    if not family_id:
        return
    rows = db.scalars(select(RefreshToken).where(RefreshToken.family_id == family_id)).all()
    for row in rows:
        if row.revoked_at is None:
            row.revoked_at = now


def _revoke_user_refresh(db: Session, user_id: int, now: datetime) -> None:
    rows = db.scalars(
        select(RefreshToken).where(
            RefreshToken.user_id == user_id,
            RefreshToken.revoked_at.is_(None),
        )
    ).all()
    for row in rows:
        row.revoked_at = now
    sessions = db.scalars(
        select(UserSession).where(
            UserSession.user_id == user_id,
            UserSession.revoked_at.is_(None),
        )
    ).all()
    for session in sessions:
        session.revoked_at = now


def _rotated_successor_secret(previous_raw: str, previous_id: int, family_id: str) -> str:
    """The refresh secret a rotation of `previous_raw` always produces.

    HMAC-SHA256 over a 256-bit uniformly-random parent, with the row identity as
    context — so it is indistinguishable from a fresh draw to anyone who has not seen
    the parent token, and it is reproducible for the one request that needs it. The
    alternative (store the successor in plaintext for 30 seconds so a retry can be
    served it) was rejected: bearer tokens at rest is the worse trade.
    """
    context = f"qibra-rotation-v1|{previous_id}|{family_id}".encode("utf-8")
    return hmac.new(previous_raw.encode("utf-8"), context, hashlib.sha256).hexdigest()


def _grace_replay(db: Session, row: RefreshToken, raw_token: str):
    """QB-016: the SAME successor, handed out again inside the grace window.

    Returns (user, refresh_raw) when the presented token is a rotation the client
    probably never received an answer for, else None so the caller falls through to the
    family revoke. Three conditions must all hold: the row was rotated (a logout is not
    a rotation and can never be replayed), the stamp is inside the window, and the
    successor is still unused — if it has already been rotated or revoked, this is
    reuse, not a lost response.
    """
    settings = get_settings()
    grace = settings.refresh_reuse_grace_seconds
    if grace <= 0 or row.rotated_at is None or not row.replaced_by_id:
        return None
    rotated_at = row.rotated_at
    if rotated_at.tzinfo is None:
        rotated_at = rotated_at.replace(tzinfo=timezone.utc)
    if (datetime.now(timezone.utc) - rotated_at).total_seconds() > grace:
        return None
    successor = db.get(RefreshToken, row.replaced_by_id)
    if successor is None or successor.revoked_at is not None or successor.rotated_at is not None:
        return None
    expires = successor.expires_at
    if expires.tzinfo is None:
        expires = expires.replace(tzinfo=timezone.utc)
    if expires < datetime.now(timezone.utc):
        return None
    if successor.token_hash != hash_refresh_token(
        _rotated_successor_secret(raw_token, row.id, row.family_id or "")
    ):
        # Not a row this code rotated (written before the derivation existed): fail
        # closed into the normal reuse path rather than guessing.
        return None
    user = get_user(db, successor.user_id)
    if user is None:
        return None
    return user, _rotated_successor_secret(raw_token, row.id, row.family_id or "")


def rotate_refresh(db: Session, raw_token: str) -> tuple[User, str, str]:
    now = datetime.now(timezone.utc)
    digest = hash_refresh_token(raw_token)
    # QB-016: take the row. Without it two concurrent rotates both read
    # `revoked_at IS NULL` and both issue a successor, so the family silently forks.
    # SQLite has no FOR UPDATE (the dialect drops it); PostgreSQL locks the row, which
    # is where this matters — Render.
    row = db.scalar(
        select(RefreshToken).where(RefreshToken.token_hash == digest).with_for_update()
    )
    if row is None:
        raise AuthError("invalid_refresh", 401)
    if row.revoked_at is not None:
        replay = _grace_replay(db, row, raw_token)
        if replay is not None:
            user, refresh = replay
            return user, create_access_token(str(user.id)), refresh
        _revoke_family(db, row.family_id, now)
        db.commit()
        raise AuthError("refresh_reuse", 401)
    expires = row.expires_at
    if expires.tzinfo is None:
        expires = expires.replace(tzinfo=timezone.utc)
    if expires < now:
        row.revoked_at = now
        db.commit()
        raise AuthError("invalid_refresh", 401)
    user = get_user(db, row.user_id)
    if user is None:
        raise AuthError("invalid_refresh", 401)
    session = db.get(UserSession, row.session_id) if row.session_id else None
    if session is not None and session.revoked_at is not None:
        raise AuthError("invalid_refresh", 401)
    row.revoked_at = now
    row.rotated_at = now
    family_id = row.family_id or str(uuid.uuid4())
    # deterministic so a retry inside the window can be answered with THIS successor
    successor_secret = _rotated_successor_secret(raw_token, row.id, family_id)
    access, refresh = issue_tokens(
        db,
        user,
        session=session,
        family_id=family_id,
        raw_refresh=successor_secret,
    )
    new_row = db.scalar(
        select(RefreshToken).where(RefreshToken.token_hash == hash_refresh_token(refresh))
    )
    if new_row is not None:
        row.replaced_by_id = new_row.id
        db.commit()
    return user, access, refresh


def revoke_refresh(db: Session, raw_token: str) -> None:
    digest = hash_refresh_token(raw_token)
    row = db.scalar(select(RefreshToken).where(RefreshToken.token_hash == digest))
    if row is None:
        return
    now = datetime.now(timezone.utc)
    if row.revoked_at is None:
        row.revoked_at = now
    if row.session_id:
        session = db.get(UserSession, row.session_id)
        if session is not None and session.revoked_at is None:
            session.revoked_at = now
    db.commit()


def logout_all(db: Session, user_id: int) -> None:
    _revoke_user_refresh(db, user_id, datetime.now(timezone.utc))
    db.commit()


def list_sessions(db: Session, user_id: int) -> list[UserSession]:
    return list(
        db.scalars(select(UserSession).where(UserSession.user_id == user_id)).all()
    )


def revoke_session(db: Session, user_id: int, session_id: int) -> bool:
    session = db.get(UserSession, session_id)
    if session is None or session.user_id != user_id:
        return False
    now = datetime.now(timezone.utc)
    if session.revoked_at is None:
        session.revoked_at = now
    tokens = db.scalars(
        select(RefreshToken).where(
            RefreshToken.session_id == session.id,
            RefreshToken.revoked_at.is_(None),
        )
    ).all()
    for token in tokens:
        token.revoked_at = now
    db.commit()
    return True
