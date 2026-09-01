"""Entitlement derivation. Unverified snapshots never grant premium."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Optional

NONE = "none"
PENDING = "pending"
ACTIVE = "active"
IN_GRACE = "in_grace"
CANCELLED = "cancelled"
EXPIRED = "expired"
REFUNDED = "refunded"
REVOKED = "revoked"


@dataclass(frozen=True)
class Entitlement:
    is_premium: bool
    source: str
    state: str = NONE
    product_id: str = ""
    store: str = "unconfigured"
    server_validated: bool = False
    expires_at: Optional[datetime] = None
    grace_ends_at: Optional[datetime] = None
    reason: str = ""


def derive(
    *,
    verified: bool,
    now: datetime,
    state: str = NONE,
    source: str = "unconfigured",
    product_id: str = "",
    store: str = "unconfigured",
    expires_at: Optional[datetime] = None,
    grace_ends_at: Optional[datetime] = None,
) -> Entitlement:
    if not verified:
        return Entitlement(
            is_premium=False,
            source=source,
            state=state if state else NONE,
            product_id=product_id,
            store=store,
            server_validated=False,
            expires_at=expires_at,
            grace_ends_at=grace_ends_at,
            reason="unverified",
        )
    if state in {REFUNDED, REVOKED}:
        return Entitlement(
            is_premium=False,
            source=source,
            state=state,
            product_id=product_id,
            store=store,
            server_validated=True,
            expires_at=expires_at,
            grace_ends_at=grace_ends_at,
            reason=state,
        )
    if state == PENDING:
        return Entitlement(
            is_premium=False,
            source=source,
            state=PENDING,
            product_id=product_id,
            store=store,
            server_validated=True,
            reason="pending",
        )
    if state == IN_GRACE:
        if grace_ends_at is not None and now < grace_ends_at:
            return Entitlement(
                is_premium=True,
                source=source,
                state=IN_GRACE,
                product_id=product_id,
                store=store,
                server_validated=True,
                expires_at=expires_at,
                grace_ends_at=grace_ends_at,
            )
        return Entitlement(
            is_premium=False,
            source=source,
            state=EXPIRED,
            product_id=product_id,
            store=store,
            server_validated=True,
            expires_at=expires_at,
            grace_ends_at=grace_ends_at,
            reason="grace_elapsed",
        )
    if state in {ACTIVE, CANCELLED}:
        if expires_at is not None and now >= expires_at:
            if grace_ends_at is not None and now < grace_ends_at:
                return Entitlement(
                    is_premium=True,
                    source=source,
                    state=IN_GRACE,
                    product_id=product_id,
                    store=store,
                    server_validated=True,
                    expires_at=expires_at,
                    grace_ends_at=grace_ends_at,
                )
            return Entitlement(
                is_premium=False,
                source=source,
                state=EXPIRED,
                product_id=product_id,
                store=store,
                server_validated=True,
                expires_at=expires_at,
                reason="expired",
            )
        return Entitlement(
            is_premium=True,
            source=source,
            state=state,
            product_id=product_id,
            store=store,
            server_validated=True,
            expires_at=expires_at,
            grace_ends_at=grace_ends_at,
        )
    return Entitlement(
        is_premium=False,
        source=source,
        state=state or NONE,
        product_id=product_id,
        store=store,
        server_validated=True,
        reason="not_entitled",
    )
