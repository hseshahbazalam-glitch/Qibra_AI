from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..config import get_settings
from ..db.models import RefreshToken, User, UserSession
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


def register(db: Session, email: str, password: str, name: str) -> User:
    existing = db.scalar(select(User).where(User.email == email.lower()))
    if existing and existing.deleted_at is None:
        raise AuthError("email_taken", 409)
    user = User(email=email.lower(), name=name, password_hash=hash_password(password))
    db.add(user)
    db.commit()
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
    raw = new_refresh_token()
    row = RefreshToken(
        user_id=user.id,
        session_id=session.id,
        token_hash=hash_refresh_token(raw),
        created_at=now,
        expires_at=now + timedelta(days=settings.refresh_token_days),
    )
    db.add(row)
    db.commit()
    return create_access_token(str(user.id)), raw


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


def rotate_refresh(db: Session, raw_token: str) -> tuple[User, str, str]:
    now = datetime.now(timezone.utc)
    digest = hash_refresh_token(raw_token)
    row = db.scalar(select(RefreshToken).where(RefreshToken.token_hash == digest))
    if row is None:
        raise AuthError("invalid_refresh", 401)
    if row.revoked_at is not None:
        _revoke_user_refresh(db, row.user_id, now)
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
    access, refresh = issue_tokens(db, user, session=session)
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
