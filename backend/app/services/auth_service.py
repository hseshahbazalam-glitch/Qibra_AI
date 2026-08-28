from sqlalchemy import select
from sqlalchemy.orm import Session

from ..db.models import User
from ..security import create_access_token, hash_password, verify_password


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


def login(db: Session, email: str, password: str) -> tuple[User, str]:
    user = db.scalar(select(User).where(User.email == email.lower()))
    if user is None or user.deleted_at is not None or not verify_password(password, user.password_hash):
        raise AuthError("invalid_credentials", 401)
    return user, create_access_token(str(user.id))


def get_user(db: Session, user_id: int) -> User | None:
    user = db.get(User, user_id)
    if user is None or user.deleted_at is not None:
        return None
    return user
