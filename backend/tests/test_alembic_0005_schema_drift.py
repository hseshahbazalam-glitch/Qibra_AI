"""Owner-ordered pre-merge micro-pass (2026-09-01): revision 0005 makes `alembic
check` clean, so "the migrations own the schema" stops being a slogan.

WHY THIS EXISTS
---------------
QB-018 moved schema ownership to alembic (create_all became dev-only) and, while
doing so, measured that `alembic check` is NOT clean against a database built by
`upgrade head`. The finding was written down in docs/G2_PASS_REPORT.md § 3 item 1
and deliberately left open, because a pass that pins head = 0004 cannot also move
the head. The owner ordered the second half before the release candidate:

    "one migration that brings the schema to what the models already say — create
    ix_progress_user_id, and align users.updated_at nullability with the model.
    Red test first (a spec that fails on 0004, passes on 0005)."

The drift, measured on this tree with the venv's own console script:

    $ alembic upgrade head && alembic check
    INFO  [alembic.autogenerate.compare] Detected added index ''ix_progress_user_id'' on '('user_id',)'
    INFO  [alembic.autogenerate.compare] Detected NOT NULL on column 'users.updated_at'
    ERROR [alembic.util.messaging] New upgrade operations detected: [...]
    exit 255

Two facts behind those two lines, both from the model file:
`Progress.user_id` is `ForeignKey("users.id"), index=True` (app/db/models.py:75) and
no revision ever created that index — 0001 built `progress` with only the
`uq_progress_user_kind` unique constraint (added in 0003), so `PRAGMA
index_list('progress')` returns just `sqlite_autoindex_progress_1`. And
`User.updated_at` is `Mapped[datetime]` (models.py:23 — non-nullable, `default=_now`)
while 0003 added the column as `nullable=True`. Dev databases never noticed, because
`create_all` builds both from the model; production, built by the migrations, has had
a nullable column and a missing index all along.

WHAT THE TESTS BELOW PIN
------------------------
1. `alembic check` after `upgrade head` is clean (the closure, end to end).
2. the index exists on a migrations-built database, on the right column;
3. `users.updated_at` is NOT NULL on a migrations-built database;
4. the migration is honest about existing rows: it backfills before it tightens, it
   keeps every row, it preserves a value that was already there byte-for-byte, and it
   never invents a timestamp for a row that has its own `created_at`;
5. 0005 downgrades and re-upgrades (a one-way migration is a deployment hazard);
6. 0005 is written for both backends — batch alter for the nullability flip, no
   SQLite-only SQL — because production is Postgres on Render and the tests are
   SQLite.

RED EVIDENCE — measured on this tree (`2209942`, head `0004`) before any migration
existed, so all eight fail for a reason and none of them vacuously:

    $ python -m pytest tests/test_alembic_0005_schema_drift.py -q
        8 failed in 4.54s
    $ python -m pytest tests -q
        8 failed, 327 passed, 1 warning in 33.39s

The printed reasons are the drift itself: "`alembic check` still wants to change the
schema (exit 255)", "`progress` has only ['sqlite_autoindex_progress_1']",
"users.updated_at carries notnull=0", "head must be exactly 0005, got ['0004']",
"no revision file starting with `0005` exists". The green half — the same two
commands after 0005 lands — is quoted in docs/G2_PASS_REPORT.md § 7. This file is
committed ALONE, so the red belongs to one commit and the migration to the next.
"""

import ast
import os
import re
import sqlite3
import subprocess
import sys
from pathlib import Path

import pytest

BACKEND = Path(__file__).resolve().parents[1]
VERSIONS = BACKEND / "alembic" / "versions"

DRIFT_INDEX = "ix_progress_user_id"


# ── the harness: real alembic, real file database, console script only ──────


def _alembic_console_script() -> str:
    """The console script specifically, exactly as QB-018 established: `python -m
    alembic` prepends the cwd and would hide an import-path hole."""
    cand = Path(sys.executable).with_name("alembic")
    if cand.exists():
        return str(cand)
    found = subprocess.run(
        [sys.executable, "-c", "import shutil;print(shutil.which('alembic') or '')"],
        capture_output=True,
        text=True,
        check=False,
    ).stdout.strip()
    if not found:
        pytest.skip("no alembic console script in this environment")
    return found


def _alembic(tmp_path: Path, *args: str, name: str = "drift.db") -> tuple[int, str, Path]:
    """Run the console script against one file database and hand the db back, so a
    test can chain `upgrade 0004` → poke rows → `upgrade head` the way an operator
    actually deploys."""
    db = tmp_path / name
    url = f"sqlite+pysqlite:///{db}"
    proc = subprocess.run(
        [_alembic_console_script(), *args],
        cwd=BACKEND,
        capture_output=True,
        text=True,
        check=False,
        env={
            **os.environ,
            # env.py boots the app's settings, which require these by design
            # (QB-001); QIBRA_ENV=dev keeps _make_engine happy about sqlite.
            "QIBRA_ENV": "dev",
            "JWT_SECRET": os.environ.get("JWT_SECRET", "qibra-test-only-signing-secret-32b+"),
            "DATABASE_URL": url,
        },
    )
    return proc.returncode, proc.stdout + proc.stderr, db


def _rows(db: Path, sql: str) -> list[tuple]:
    con = sqlite3.connect(db)
    try:
        return list(con.execute(sql))
    finally:
        con.close()


def _upgrade(tmp_path: Path, target: str, name: str = "drift.db") -> Path:
    rc, out, db = _alembic(tmp_path, "upgrade", target, name=name)
    assert rc == 0, f"`alembic upgrade {target}` failed:\n{out[-900:]}"
    return db


def _revision_files() -> dict[str, str | None]:
    chain: dict[str, str | None] = {}
    for path in sorted(VERSIONS.glob("*.py")):
        fields: dict[str, object] = {}
        for node in ast.parse(path.read_text()).body:
            if isinstance(node, ast.Assign) and isinstance(node.targets[0], ast.Name):
                if node.targets[0].id in {"revision", "down_revision"} and isinstance(
                    node.value, ast.Constant
                ):
                    fields[node.targets[0].id] = node.value.value
        chain[str(fields.get("revision"))] = fields.get("down_revision")
    return chain


# ── 1. the closure: check is clean after upgrade head ───────────────────────


def test_alembic_check_is_clean_on_a_database_built_by_upgrade_head(tmp_path):
    """The one command that says "the migrations describe the models". It exits 255
    and prints `New upgrade operations detected` while the drift exists, which is
    why QB-018 refused to wire it into CI: the owner's paste has to be green on
    arrival, and after 0005 it is."""
    rc, out, _db = _alembic(tmp_path, "upgrade", "head")
    assert rc == 0, out[-900:]
    rc, out, _db = _alembic(tmp_path, "check")
    assert not re.search(r"New upgrade operations detected", out), (
        f"`alembic check` still wants to change the schema (exit {rc}):\n{out[-1200:]}"
    )
    assert rc == 0, f"`alembic check` exited {rc}:\n{out[-1200:]}"
    assert "No new upgrade operations detected" in out, out[-600:]


# ── 2 + 3. the two facts, on the schema the migrations actually build ───────


def test_progress_user_id_index_exists_and_covers_exactly_user_id(tmp_path):
    db = _upgrade(tmp_path, "head")
    names = {r[1]: r for r in _rows(db, "pragma index_list('progress')")}
    assert DRIFT_INDEX in names, (
        f"`progress` has only {sorted(names)}; the model says index=True on "
        "Progress.user_id (app/db/models.py:75) and every per-user progress lookup "
        "was paying for it"
    )
    cols = [r[2] for r in _rows(db, f"pragma index_info('{DRIFT_INDEX}')")]
    assert cols == ["user_id"], f"{DRIFT_INDEX} covers {cols}, expected ['user_id']"


def test_users_updated_at_is_not_null_where_the_model_says_it_is(tmp_path):
    db = _upgrade(tmp_path, "head")
    col = {r[1]: r for r in _rows(db, "pragma table_info('users')")}["updated_at"]
    # pragma table_info row: (cid, name, type, notnull, dflt_value, pk)
    assert col[3] == 1, (
        f"users.updated_at carries notnull={col[3]} in the migration-built schema "
        "(0 means the column is nullable); User.updated_at is `Mapped[datetime]` "
        "(app/db/models.py:23), i.e. NOT NULL. 0003 added it as nullable=True and "
        "nothing ever tightened it."
    )


# ── 4. the migration must not lose or invent data ───────────────────────────


def test_a_row_that_never_changed_gets_created_at_and_keeps_its_siblings(tmp_path):
    """Upgrade to 0004 the way a live database did, put a NULL updated_at in front
    of the migration, then upgrade head. Three promises: the row count survives, the
    NULL becomes its own created_at (the only defensible answer — a row that never
    changed was last changed when it was made), and the row that had a value keeps
    that exact value."""
    db = _upgrade(tmp_path, "0004")
    con = sqlite3.connect(db)
    try:
        con.executescript(
            """
            insert into users (id, email, name, password_hash, created_at, deleted_at,
                               preferred_locale, timezone, updated_at)
            values (1, 'stale@example.test', 'Stale', 'x',
                    '2026-08-01 09:00:00', NULL, 'en', '', NULL),
                   (2, 'kept@example.test', 'Kept', 'x',
                    '2026-08-02 09:00:00', NULL, 'en', '', '2026-08-05 11:11:11');
            insert into progress (id, user_id, kind, payload, updated_at)
            values (1, 1, 'quran', '{}', '2026-08-01 09:00:00');
            """
        )
        con.commit()
    finally:
        con.close()

    rc, out, _ = _alembic(tmp_path, "upgrade", "head")
    assert rc == 0, f"`alembic upgrade head` over a live-shaped database failed:\n{out[-900:]}"

    rows = {r[0]: r for r in _rows(db, "select id, created_at, updated_at from users order by id")}
    assert sorted(rows) == [1, 2], f"the migration lost or invented rows: {sorted(rows)}"
    assert rows[1][2] == rows[1][1], (
        f"user 1 keeps updated_at={rows[1][2]!r} while created_at={rows[1][1]!r}; the "
        "backfill must copy created_at, not now() — a mass timestamp rewrite would "
        "make every migrated account look freshly active"
    )
    assert rows[2][2] == "2026-08-05 11:11:11", (
        f"user 2's real updated_at was overwritten with {rows[2][2]!r}"
    )
    assert _rows(db, "select count(*) from users where updated_at is null")[0][0] == 0
    # the progress table must survive too — the index is built over its rows
    assert _rows(db, "select count(*) from progress")[0][0] == 1


# ── 5. it goes backwards as well as forwards ────────────────────────────────


def test_0005_downgrades_to_0004_and_reupgrades(tmp_path):
    """A migration nobody can roll back is a deployment hazard, and the two changes
    here are both cheap to undo: drop the index, relax the column. The re-upgrade
    proves the migration is idempotent from a partially-rolled-back state."""
    db = _upgrade(tmp_path, "head")
    assert "alembic_version" in [r[0] for r in _rows(db, "select name from sqlite_master where type='table'")]
    assert _rows(db, "select version_num from alembic_version") == [("0005",)]

    rc, out, _ = _alembic(tmp_path, "downgrade", "0004")
    assert rc == 0, f"`alembic downgrade 0004` failed:\n{out[-900:]}"
    assert _rows(db, "select version_num from alembic_version") == [("0004",)]
    assert DRIFT_INDEX not in {r[1] for r in _rows(db, "pragma index_list('progress')")}, (
        "downgrade left the index behind"
    )
    col = {r[1]: r for r in _rows(db, "pragma table_info('users')")}["updated_at"]
    assert col[3] == 0, "downgrade did not restore the nullable column it tightened"
    assert _rows(db, "select count(*) from users")[0][0] == 0  # table still there, no data loss

    rc, out, _ = _alembic(tmp_path, "upgrade", "head")
    assert rc == 0, f"re-applying 0005 failed:\n{out[-900:]}"
    assert _rows(db, "select version_num from alembic_version") == [("0005",)]
    assert DRIFT_INDEX in {r[1] for r in _rows(db, "pragma index_list('progress')")}


# ── 6. written for both backends, code-only inspection ──────────────────────


def _func_source(path: Path, name: str) -> str:
    """The un-parsed-free way to read a migration: the function's own code, with the
    docstring and comments out, so prose cannot satisfy a structural pin. Same rule
    QB-018's `_code_only` enforces on the Dart side."""
    tree = ast.parse(path.read_text())
    for node in tree.body:
        if isinstance(node, ast.FunctionDef) and node.name == name:
            node.body = [
                stmt for stmt in node.body if not _is_docstring(stmt)
            ]
            return ast.unparse(node)
    raise AssertionError(f"{path.name} has no def {name}()")


def _is_docstring(stmt: ast.stmt) -> bool:
    return (
        isinstance(stmt, ast.Expr)
        and isinstance(stmt.value, ast.Constant)
        and isinstance(stmt.value.value, str)
    )


def test_0005_is_portable_sqlalchemy_not_sqlite_flavoured_sql():
    files = {p.name: p for p in VERSIONS.glob("*.py")}
    mine = [n for n in files if n.startswith("0005")]
    assert mine, (
        "no revision file starting with `0005` exists — the drift has to be closed "
        "by a migration, not by create_all or by hand"
    )
    path = files[mine[0]]
    up = _func_source(path, "upgrade")
    down = _func_source(path, "downgrade")

    assert "batch_alter_table" in up, (
        "the nullability flip must go through op.batch_alter_table: SQLite cannot "
        f"ALTER COLUMN, and recreate='auto' leaves Postgres on a plain ALTER (code: {up[:220]})"
    )
    assert "nullable=False" in up, "the whole point is NOT NULL; it is not in upgrade()"
    assert DRIFT_INDEX in up, f"upgrade() never creates {DRIFT_INDEX}"
    assert DRIFT_INDEX in down, f"downgrade() never drops {DRIFT_INDEX}"
    for blob, label in ((up, "upgrade"), (down, "downgrade")):
        assert "PRAGMA" not in blob.upper(), f"{label}() uses SQLite-only PRAGMA SQL"
        assert "sqlite" not in blob.lower(), f"{label}() names sqlite in its code path"
    for forbidden in ("CURRENT_TIMESTAMP", "NOW()", "FUNC.NOW"):
        assert forbidden not in up.upper(), (
            f"upgrade() must not invent a clock ({forbidden}); the backfill copies "
            "created_at, so a migrated row keeps the timestamp it earned"
        )
    assert re.search(r"UPDATE\s+users\s+SET", up, re.I | re.S), (
        "upgrade() must backfill existing rows before tightening them, or a live "
        "database with a NULL updated_at refuses the migration outright"
    )
    assert re.search(r"updated_at\s+IS\s+NULL", up, re.I), (
        "the backfill must be scoped to the NULL rows only — a blanket UPDATE "
        "rewrites every user's last-touched timestamp"
    )


def test_the_chain_now_ends_at_0005_and_stays_linear():
    chain = _revision_files()
    parents = {d for d in chain.values() if d}
    heads = [r for r in chain if r not in parents]
    assert heads == ["0005"], f"head must be exactly 0005, got {heads}"
    order, cur = [], "0005"
    while cur is not None:
        assert cur in chain, f"{cur} is a down_revision with no file"
        order.append(cur)
        cur = chain[cur]
    assert order == ["0005", "0004", "0003", "0002", "0001"], order
    assert len(chain) == 5, f"expected exactly 5 revisions, found {sorted(chain)}"


def test_the_models_and_the_migrations_now_agree_by_construction(tmp_path):
    """The belt to `alembic check`'s braces: compare the two schemas this repo can
    actually build — the migration-built file db and a create_all db from the models —
    on the two columns this pass is about. If someone later edits the model without a
    revision, this is the test that says so in plain words."""
    db = _upgrade(tmp_path, "head")

    from sqlalchemy import create_engine, inspect

    mig_engine = create_engine(f"sqlite+pysqlite:///{db}")
    mig = inspect(mig_engine)
    assert any(
        idx["column_names"] == ["user_id"] and not idx["unique"]
        for idx in mig.get_indexes("progress")
    ), f"migration-built progress has no non-unique user_id index: {mig.get_indexes('progress')}"
    assert {c["name"]: c["nullable"] for c in mig.get_columns("users")}[
        "updated_at"
    ] is False, "users.updated_at is still nullable where the model says NOT NULL"

    model_db = tmp_path / "from_models.db"
    from app.db.session import Base  # noqa: PLC0415 — the models are the reference

    model_engine = create_engine(f"sqlite+pysqlite:///{model_db}")
    Base.metadata.create_all(model_engine)
    mod = inspect(model_engine)
    assert any(
        idx["column_names"] == ["user_id"] and not idx["unique"]
        for idx in mod.get_indexes("progress")
    ), "the model lost its index=True; then 0005 is the drift, not the fix"
    assert {c["name"]: c["nullable"] for c in mod.get_columns("users")}[
        "updated_at"
    ] is False
    mig_engine.dispose()
    model_engine.dispose()
