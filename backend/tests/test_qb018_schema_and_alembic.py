"""QB-018 (G2-D) — the schema belongs to alembic; the app may only build one in dev.

Three separate holes, each with its own test below, and each measured rather than
assumed:

1. `backend/alembic.ini` has no `prepend_sys_path`, while `alembic/env.py:7` does
   `from app.db.models import Base`. So `app` is importable only if something else
   already put `backend/` on sys.path — which `python -m alembic …` does (runpy
   prepends the cwd) and the bare `alembic` console script does NOT. Measured on
   this tree before the fix:

       $ alembic heads                        -> 0004 (head)      # never runs env.py
       $ alembic upgrade head --sql           -> ModuleNotFoundError: No module named 'app'
       $ python -m alembic upgrade head --sql -> runs, env.py imports app fine

   That asymmetry is the whole bug: docs/DATABASE.md tells an operator to run
   `alembic upgrade head`, and `heads` works well enough to convince a human the
   wiring is sound. So the tests below assert BOTH that the ini pins the path AND
   that the console script really executes env.py — `heads` alone would have
   passed with the hole wide open.

2. `reset_engine()` ended with an unconditional `Base.metadata.create_all(bind=engine)`,
   and `main.py`'s startup hook called `reset_engine()`. A production boot therefore
   built whatever tables the ORM happened to know about, on top of whatever state
   alembic had left the database in — turning a half-applied migration from a loud
   failure into a silently wrong schema.

3. That startup hook used `@app.on_event("startup")`, deprecated by Starlette and
   emitting a DeprecationWarning on every boot (one of the three warnings the QB-014
   run printed). The replacement is a lifespan handler.

Red evidence: written before the change, run against the unmodified tree —
`5 failed, 1 passed in 0.70s` (the survivor was the chain census, which guards the
future rather than proving the present — and the future arrived: see the amendment
below). CI has no backend job at all yet
(that is QB-019), so the pytest run below is the evidence, quoted in
docs/G2_PASS_REPORT.md § QB-018.

AMENDED by the owner-ordered 0005 micro-pass (docs/G2_PASS_REPORT.md § 7): two
assertions here pinned head = 0004 and both moved to 0005, because the drift
QB-018 left open is now closed by a revision instead of by a note. The renames and
the old → new lines are listed there. Nothing else in this file changed, and the
"0004 (head)" quotes above are kept as the historical measurements they are.
"""

import ast
import os
import re
import subprocess
import sys
from pathlib import Path

import pytest

BACKEND = Path(__file__).resolve().parents[1]
INI = BACKEND / "alembic.ini"
SESSION_PY = BACKEND / "app" / "db" / "session.py"
MAIN_PY = BACKEND / "app" / "main.py"
VERSIONS = BACKEND / "alembic" / "versions"


def _ini_pins() -> dict:
    section = INI.read_text().split("[alembic]", 1)[1].split("\n[", 1)[0]
    return {
        m.group(1).strip(): m.group(2).strip()
        for m in re.finditer(r"^([a-z_]+)\s*=\s*(.*)$", section, re.M)
    }


def _alembic_console_script() -> str:
    """The console script specifically. `python -m alembic` is forbidden here: it
    fixes sys.path by accident and would hide hole (1)."""
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


# ── 1. alembic.ini owns the import path ─────────────────────────────────────


def test_alembic_ini_prepends_sys_path():
    pins = _ini_pins()
    assert pins.get("prepend_sys_path") == ".", (
        "alembic.ini must pin `prepend_sys_path = .` — env.py imports `app.*`, and "
        "without this line the console script only works if the caller happened to "
        f"use `python -m alembic` (got: {pins.get('prepend_sys_path')!r})"
    )
    # Both options are relative to the cwd, so the command has to be run from
    # backend/. Assert the coupling instead of documenting it: a future
    # `script_location` edit cannot then quietly move the goalposts.
    assert pins["script_location"] == "alembic"


def _code_only(path: Path) -> str:
    """Source with comments and every string literal blanked, newline-for-newline so
    positions still line up. A pin must not be satisfiable by prose — same rule the
    Dart suite's `stripCommentsForGuard` enforces, and needed here for the same
    reason: `_lifespan`'s docstring names the decorator it replaced."""
    import tokenize

    lines = path.read_text().splitlines(keepends=True)
    out = []
    for tok in tokenize.generate_tokens(iter(lines).__next__):
        if tok.type in (tokenize.COMMENT, tokenize.STRING):
            out.append("".join("\n" if ch == "\n" else " " for ch in tok.string))
        else:
            out.append(tok.string)
    return "".join(out)


def test_the_console_script_builds_the_schema_on_a_clean_database(tmp_path):
    """End to end, via the console script: `alembic upgrade head` against a fresh
    file database. This is what docs/DATABASE.md tells an operator to run, and it is
    the command that died with ModuleNotFoundError before QB-018.

    It also proves the OTHER half of the change: with create_all gone from a non-dev
    boot, alembic must still deliver every table the models declare, or "the
    migrations own the schema" would be a slogan.

    (Offline `--sql` is deliberately NOT used: revision 0004 uses
    `batch_alter_table` on sqlite, which needs a live connection to reflect
    `progress`, so `alembic upgrade head --sql` ends in "This operation cannot
    proceed in --sql mode" even when everything else is wired correctly.)
    """
    exe = _alembic_console_script()
    db = tmp_path / "fresh.db"
    stray = BACKEND / "qibra.db"
    had_stray_before = stray.exists()  # a developer's own database is not our business
    url = f"sqlite+pysqlite:///{db}"
    proc = subprocess.run(
        [exe, "upgrade", "head"],
        cwd=BACKEND,
        capture_output=True,
        text=True,
        check=False,
        env={
            **os.environ,
            # env.py boots the app's settings, which require these by design
            # (QB-001). Same values tests/helpers.py declares. QIBRA_ENV=dev keeps
            # _make_engine happy about sqlite; the alembic run itself never calls
            # create_all, which is the point.
            "QIBRA_ENV": "dev",
            "JWT_SECRET": os.environ.get(
                "JWT_SECRET", "qibra-test-only-signing-secret-32b+"
            ),
            "DATABASE_URL": url,
        },
    )
    joined = proc.stdout + proc.stderr
    assert "ModuleNotFoundError" not in joined, (
        "env.py could not import `app` — the console script needs "
        f"`prepend_sys_path = .` in alembic.ini:\n{joined[-500:]}"
    )
    assert proc.returncode == 0, f"`alembic upgrade head` failed:\n{joined[-900:]}"
    # 0003 → 0004 still runs, and so does the drift closure on top of it: a clean
    # database gets 0005 too, which is the point of the micro-pass.
    assert "Running upgrade 0003 -> 0004" in joined, joined[-900:]
    assert "Running upgrade 0004 -> 0005" in joined, joined[-900:]
    assert stray.exists() == had_stray_before, (
        "the run must use DATABASE_URL, not the ini's default "
        "sqlite+pysqlite:///./qibra.db"
    )

    import sqlite3

    con = sqlite3.connect(db)
    try:
        assert list(con.execute("select version_num from alembic_version")) == [
            ("0005",)
        ]
        built = {r[0] for r in con.execute("select name from sqlite_master where type='table'")}
    finally:
        con.close()
    from app.db import models  # noqa: F401 — register the mappers

    from app.db.session import Base

    declared = set(Base.metadata.tables)
    assert declared - built == set(), (
        f"`alembic upgrade head` did not build {sorted(declared - built)}; the "
        "migrations must cover the models now that create_all is dev-only"
    )
    assert len(built) == len(declared) + 1, (
        f"expected {len(declared)} model tables plus alembic_version, got {sorted(built)}"
    )


def test_head_is_0005_and_the_chain_is_linear():
    revisions = {}
    for path in sorted(VERSIONS.glob("*.py")):
        fields = {}
        for node in ast.parse(path.read_text()).body:
            if isinstance(node, ast.Assign) and isinstance(node.targets[0], ast.Name):
                name = node.targets[0].id
                if name in {"revision", "down_revision"} and isinstance(
                    node.value, ast.Constant
                ):
                    fields[name] = node.value.value
        assert "revision" in fields, f"{path.name} declares no `revision`"
        revisions[fields["revision"]] = fields.get("down_revision")

    assert len(revisions) == 5, f"expected 5 revisions, found {sorted(revisions)}"
    parents = {d for d in revisions.values() if d}
    heads = [r for r in revisions if r not in parents]
    assert heads == ["0005"], f"head must be exactly 0005, got {heads}"
    chain, cur = [], "0005"
    while cur is not None:
        assert cur in revisions, f"{cur} is a down_revision with no file"
        chain.append(cur)
        cur = revisions[cur]
    assert chain == ["0005", "0004", "0003", "0002", "0001"], chain


# ── 2. create_all is a dev convenience, nothing more ───────────────────────


def _create_all_calls(tree):
    for node in ast.walk(tree):
        if (
            isinstance(node, ast.Call)
            and isinstance(node.func, ast.Attribute)
            and node.func.attr == "create_all"
        ):
            yield node


def test_session_py_gates_create_all_on_dev_mode():
    tree = ast.parse(SESSION_PY.read_text())
    calls = list(_create_all_calls(tree))
    assert len(calls) == 1, f"expected exactly one create_all in session.py, got {len(calls)}"
    target = ast.unparse(calls[0])
    guarded_by = {
        ast.unparse(ifnode.test)
        for ifnode in ast.walk(tree)
        if isinstance(ifnode, ast.If)
        and any(ast.unparse(c) == target for c in _create_all_calls(ifnode))
    }
    assert guarded_by and all("dev_mode" in g for g in guarded_by), (
        "create_all must sit inside an `if dev_mode():` guard — that gate is the "
        f"only thing keeping a production boot from building tables. Found: "
        f"{sorted(guarded_by) or 'no enclosing if at all'}"
    )


def test_main_py_has_no_on_event_and_defers_to_reset_engine():
    src = _code_only(MAIN_PY)  # comments/docstrings blanked: prose may not satisfy a pin
    assert "on_event" not in src, "@app.on_event is deprecated; use a lifespan handler"
    assert "asynccontextmanager" in src and "lifespan" in src
    assert re.search(r"FastAPI\([^)]*lifespan=", src, re.S), "FastAPI(… lifespan=…) missing"
    # The rule must have exactly one home: the lifespan may not create tables of
    # its own, or the dev gate in session.py becomes bypassable.
    assert "create_all" not in src, (
        "main.py must not call create_all itself — reset_engine() owns the dev gate"
    )


def test_a_non_dev_boot_creates_no_tables(tmp_path):
    """Behavioural, not textual: point the session module at a file database under a
    non-dev QIBRA_ENV and prove nothing is built; then flip to dev and prove the
    convenience path still works — the whole suite depends on that half."""
    from sqlalchemy import create_engine, inspect

    from app.config import dev_mode
    from app.db import session as session_mod

    assert dev_mode() is True, "the suite itself must run in dev for this to mean anything"
    url = f"sqlite+pysqlite:///{tmp_path / 'bootlike.db'}"
    saved = os.environ.get("QIBRA_ENV")
    try:
        os.environ["QIBRA_ENV"] = "staging"  # not dev, and not prod+sqlite (rejected)
        assert dev_mode() is False
        session_mod.reset_engine(url)
        probe = create_engine(url)
        with probe.connect() as conn:
            tables = sorted(inspect(conn).get_table_names())
        probe.dispose()
        assert tables == [], (
            f"a non-dev boot created {tables}; alembic owns the production schema"
        )

        os.environ["QIBRA_ENV"] = "dev"
        session_mod.reset_engine(url)
        probe = create_engine(url)
        with probe.connect() as conn:
            dev_tables = sorted(inspect(conn).get_table_names())
        probe.dispose()
        assert "users" in dev_tables, f"dev convenience mode stopped working: {dev_tables}"
    finally:
        os.environ["QIBRA_ENV"] = saved if saved is not None else "dev"
        # Leave the module pointing where the rest of the suite expects: an
        # in-memory database, freshly built.
        session_mod.reset_engine("sqlite+pysqlite:///:memory:")
