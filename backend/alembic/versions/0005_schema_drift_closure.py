"""close the schema drift QB-018 measured: progress.user_id index + users.updated_at

Revision ID: 0005
Revises: 0004
Create Date: 2026-09-01

Owner-ordered pre-merge micro-pass (docs/G2_PASS_REPORT.md § 7). This migration
changes nothing the models do not already say; it makes the database match them so
that `alembic check` is clean and "the migrations own the schema" stops being a
slogan. Two facts, both quoted from the model file:

* `ix_progress_user_id` — `Progress.user_id` carries `index=True`
  (app/db/models.py:75), while 0001 created `progress` with no index and 0003 only
  added the `uq_progress_user_kind` unique constraint. `PRAGMA index_list('progress')`
  returned just `sqlite_autoindex_progress_1`, so every per-user progress lookup was
  scanning.
* `users.updated_at NOT NULL` — 0003 added the column `nullable=True`, but
  `User.updated_at` is `Mapped[datetime]` with `default=_now` (models.py:23): the app
  has never been allowed to create a row with it empty. Databases built by the
  dev-only `create_all` always had the constraint; databases built by these
  revisions did not. That is exactly the half-migrated state QB-018 removed
  `create_all` from boot to expose.

The backfill is scoped and boring on purpose:

    UPDATE users SET updated_at = created_at WHERE updated_at IS NULL

A row that never changed was last changed when it was created — the only value this
migration can defend. `now()` (or a `COALESCE(..., now())` fallback) would stamp
every migrated account as freshly active, which is a lie about data the app wrote
correctly. No fallback branch is needed because `created_at` has been NOT NULL since
0001. Rows that already had a value are left byte-for-byte alone: the WHERE clause is
the whole point of doing this in a migration rather than in a model default.

Portability: `batch_alter_table` is what lets one migration serve both backends.
`recreate="auto"` is resolved through `requires_recreate_in_batch`: the base
implementation returns False (alembic/ddl/impl.py:139-149), so Postgres issues a
plain `ALTER TABLE users ALTER COLUMN updated_at SET NOT NULL` with no table copy;
the SQLite override returns True for any batch operation that is not
create_index/drop_index (alembic/ddl/sqlite.py:46-70), so SQLite recreates `users`
and copies the data — after the backfill, never before, which is why the UPDATE is
the first statement in `upgrade()`. No PRAGMA, no dialect branch, no `datetime()`
call in the code path.

DISCLOSED rather than verified: the SQLite half is executed by
`tests/test_alembic_0005_schema_drift.py` (recreate, backfill, downgrade, re-upgrade).
The Postgres half is source inspection only — there is no Postgres in the sandbox that
wrote this revision, the same limit `docs/DEPLOY.md` records. The first real
`alembic upgrade head` against the managed database is that check.

`downgrade` drops the index and relaxes the column. It deliberately does not re-null
the backfilled timestamps: there is no honest way to un-fill a value, and an operator
rolling back should not lose data to gain a nullable column.
"""

from alembic import op
import sqlalchemy as sa

revision = "0005"
down_revision = "0004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. fill the NULLs first: tightening before this line would make a live
    #    database refuse the migration outright.
    op.execute(
        sa.text("UPDATE users SET updated_at = created_at WHERE updated_at IS NULL")
    )
    # 2. the index the model has always asked for.
    op.create_index("ix_progress_user_id", "progress", ["user_id"])
    # 3. the constraint the model has always had.
    with op.batch_alter_table("users") as batch_op:
        batch_op.alter_column(
            "updated_at",
            existing_type=sa.DateTime(timezone=True),
            nullable=False,
        )


def downgrade() -> None:
    with op.batch_alter_table("users") as batch_op:
        batch_op.alter_column(
            "updated_at",
            existing_type=sa.DateTime(timezone=True),
            nullable=True,
        )
    op.drop_index("ix_progress_user_id", table_name="progress")
