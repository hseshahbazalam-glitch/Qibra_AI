#!/usr/bin/env python3
# scripts/static_battery.py
# ============================================================================
# QIBRA AI — STATIC VERIFICATION BATTERY (no Flutter SDK required)
#
# Usage:
#   python3 scripts/static_battery.py [ROOT] [--check-glob PATTERN]...
#   ROOT defaults to cwd. --check-glob adds per-stage design sweeps
#   (L1 hex / L6 loop-anim / L7 emoji) as ERRORS only for files matching
#   the glob; repo-wide those are reported as counts for stage planning.
#   Exit 0 = gates pass, 1 = findings.
#
# Compile-class gates added after the owner device gate (commit 9bfe297,
# 8 errors). Back-test: fires on all four bug classes at 6ec1136, clean at
# 9bfe297:
#   G1 model-getter    `var.member` on a receiver whose type resolves to a
#                      repo model class must exist on that class. Catches
#                      API-JSON keys used as Dart getters (numberInSurah).
#   G1R red-flags      explicit incident list: keys that exist in JSON but
#                      not as getters on the model.
#   G2 import-symbols  every lib-defined top-level symbol a file references
#                      must be provided by an import/export chain (depth 2).
#                      Must be silent before ANY import removal
#                      (SearchResultModel was defined in the "unused" import).
#   G3 const-ctor      `const X(` when X is a repo class lacking a const
#                      constructor, or on the non-const flutter denylist
#                      (Transform) — Transform.translate has no const ctor.
#   G4 context-scope   bare `context` inside a method of a *Widget class
#                      (StatelessWidget/ConsumerWidget/…StatefulWidget) whose
#                      signature has no BuildContext param. Legal anywhere a
#                      State<…> provides this.context. (_buildLanguageCard.)
#                      PERMANENT LIMIT: G4 (and every static gate here) cannot
#                      see undefined identifiers — e.g. a dangling `slide.`
#                      reference after a local was stripped is a compile fail
#                      invisible to the battery; only the device gate catches
#                      that class. Same for the onboarding slide refactor.
#
# Design gates (all files): L3 dangling Amiri literal, L4
# colors.cardElevated (not a QibraColors field), L5 const QibraStatus call
# sites, L8 empty widget bodies / bracket balance (historical corruption).
# L2 alpha budget is a warning list (documented scrims/dims allowed).
#
# PROCESS RULE (owner, 2026-09-02): when a script inserts generated
# blocks into a file, anchor on a unique NAMED marker (e.g. the closing
# brace of a specific class or a sentinel comment), NEVER on raw line
# numbers or rstrip('}') file-tail position — G10/G11 exist because both
# shortcuts shipped compile-breaking code through an otherwise-green
# battery. A clean run is necessary, not sufficient.
#
# Known limits: Windows path blind spot — every test/script that walks
# `Directory(…)` MUST normalize with replaceAll(r'\', '/') before
# substring matching (phase17/19 guards do; stage_c's checks are separator-
# free — keep it that way). Plus: single-file type inference (no constants from other libs,
# no generics beyond List/Iterable/Set/Future/Stream unwrap); receivers we
# cannot type-check are skipped, never guessed. A clean run is necessary,
# not sufficient — `flutter analyze` on device remains the authority.
# ============================================================================
import fnmatch
import pathlib
import re
import sys

ROOT = pathlib.Path(".")
GLOBS = []
args = sys.argv[1:]
i = 0
while i < len(args):
    if args[i] == "--check-glob":
        i += 1
        GLOBS.append(args[i])
    else:
        ROOT = pathlib.Path(args[i]).resolve()
    i += 1

LIB = ROOT / "lib"
if not LIB.is_dir():
    sys.exit(f"no lib/ under {ROOT}")

ERRORS = []
WARNINGS = []
STAGE_PENDING = {}


def err(gate, path, line_no, msg):
    rel = str(path.relative_to(ROOT))
    ERRORS.append(f"{gate} {rel}:{line_no}: {msg}")


def strip_noise(text):
    """Whole-file lexer pass: drops // and /* */ comments and all string
    literals (single, double, triple-quoted), replacing each string with a
    neutral placeholder. Brace-aware only at the lexical level."""
    out = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        t3 = text[i:i + 3]
        if t3 == chr(34) * 3 or t3 == chr(39) * 3:
            close = text.find(t3, i + 3)
            i = (close + 3) if close >= 0 else n
            out.append(chr(34) * 2)
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "/":
            nl = text.find("\n", i)
            i = n if nl < 0 else nl  # keep the newline for line alignment
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "*":
            close = text.find("*/", i + 2)
            i = (close + 2) if close >= 0 else n
            continue
        if c == chr(34) or c == chr(39):
            j = i + 1
            while j < n and text[j] != c and text[j] != "\n":
                if text[j] == "\\":
                    j += 1
                j += 1
            out.append(chr(34) * 2)
            i = j + 1 if j < n and text[j] == c else j
            continue
        out.append(c)
        i += 1
    return "".join(out)


def code_line(ln):
    """Single-line version: comments out, strings replaced (line-for-line)."""
    return strip_noise(ln)


COMMON_MEMBERS = {
    # Object
    "hashCode", "runtimeType", "toString", "noSuchMethod",
    # Equatable / common model API in this repo
    "props", "copyWith", "toJson",
    # enum built-ins (incl. .values on the type, tolerated here)
    "name", "index",
    # String/List/Set/Map members that can surface when a field type is
    # itself a builtin — never legitimate JSON-key mistakes
    "isEmpty", "isNotEmpty", "length", "first", "last", "reversed", "cast",
    "toList", "toSet", "map", "where", "any", "every", "contains", "join",
    "split", "trim", "elementAt", "reduce", "fold", "whereType", "entries",
    "keys", "values", "codeUnits", "runes", "hashCodeOf",
}

# ---------------------------------------------------------------- file scan
class FileInfo:
    __slots__ = ("path", "raw", "code", "defs", "imports", "exports", "parts",
                 "is_part", "rel")

    def __init__(self, path):
        self.path = path
        self.rel = str(path.relative_to(LIB)).replace("\\", "/")
        self.raw = path.read_text(encoding="utf-8", errors="replace")
        self.code = strip_noise(self.raw)
        # imports/exports must be read from RAW (strings survive only there)
        self.imports = re.findall(r"^import\s+'([^']+)'", self.raw, flags=re.M)
        self.exports = re.findall(r"^export\s+'([^']+)'", self.raw, flags=re.M)
        self.parts = re.findall(r"^part\s+'([^']+)'", self.raw, flags=re.M)
        self.is_part = bool(re.search(r"^part\s+of\s+", self.raw, flags=re.M)) and not re.search(r"^library\s", self.raw, flags=re.M)
        self.defs = set()
        for m in re.finditer(
            r"^(?:abstract\s+|final\s+|base\s+|sealed\s+|interface\s+)*"
            r"(?:class|enum|mixin|extension|typedef)\s+(_?\w+)",
            self.code, flags=re.M,
        ):
            self.defs.add(m.group(1))


FILES = {}
for p in sorted(LIB.rglob("*.dart")):
    FILES[p] = FileInfo(p)

# fold part-file defs into the parent library so G2 sees one scope per library
PART_CODE = {}  # parent path -> concatenated part code
for fi in list(FILES.values()):
    for upath in fi.parts:
        pp = (fi.path.parent / upath).resolve()
        if pp in FILES:
            fi.defs |= FILES[pp].defs
            PART_CODE.setdefault(fi.path, []).append(FILES[pp].code)

# ------------------------------------------------ class maps (members, span)
CLASS_MEMBERS = {}   # name -> fields/getters/members/const/is_enum/model
CLASS_SPANS = {}     # (file, class) -> (base, start, end)
CLASS_FILE = {}      # class name -> FileInfo defining it


def base_type(t):
    t = t.strip().replace("?", "")
    m = re.match(r"(?:List|Iterable|Set|Future|Stream)\s*<\s*([\w.]+)", t)
    if m:
        return m.group(1)
    m = re.match(r"([\w.]+)", t)
    return m.group(1) if m else None


def collect_members(body):
    fields, getters, members, has_const, is_enum = {}, {}, set(), False, False
    head = body.split("{", 1)[0]
    if re.match(r"^enum\b", head):
        is_enum = True
        names = re.findall(r"^\s{4}(\w+)[,;]", body, flags=re.M)
        members.update(names)
    for m in re.finditer(r"^\s*final\s+([\w<>,?\s.]+?)\s+(\w+)\s*[;=]", body, flags=re.M):
        fields[m.group(2)] = m.group(1).strip()
        members.add(m.group(2))
    for m in re.finditer(r"^\s*([\w<>,?\s.]+?)\s+get\s+(\w+)\s*(?:=>|\{)", body, flags=re.M):
        getters[m.group(2)] = m.group(1).strip()
        members.add(m.group(2))
    for m in re.finditer(r"^\s*(?:static\s+)?[\w<>,?\s.]+\s+(\w+)\s*\(", body, flags=re.M):
        members.add(m.group(1))
    for m in re.finditer(r"^\s*_?\w+\s*\(.*?\)\s*(?:;|\{|=>)", body, flags=re.M):
        members.add(m.group(0).strip().split("(")[0])  # named/ctor-ish
    has_const = bool(re.search(r"^\s*const\s+\w+\s*\(", body, flags=re.M))
    return fields, getters, members, has_const, is_enum


for fi in FILES.values():
    lines = fi.raw.splitlines()
    open_class = None
    depth = 0
    for i, ln in enumerate(lines):
        m = re.match(
            r"^(?:abstract\s+|final\s+|base\s+|sealed\s+|interface\s+)*"
            r"(class|enum)\s+(\w+)(?:\s+extends\s+(\w+))?", ln)
        if m and depth == 0:
            open_class = (m.group(2), m.group(3), i, m.group(1))
            CLASS_MEMBERS.setdefault(m.group(2), {"fields": {}, "getters": {}, "members": set(), "const": False, "enum": False, "model": False})
            CLASS_SPANS.setdefault((fi, m.group(2)), (m.group(3), i, None))
            CLASS_FILE.setdefault(m.group(2), fi)
        c = code_line(ln)
        depth += c.count("{") - c.count("}")
        if open_class and depth <= 0 and i > open_class[2]:
            body = "\n".join(lines[open_class[2]: i + 1])
            f, g, mem, hc, en = collect_members(body)
            cur = CLASS_MEMBERS[open_class[0]]
            cur["fields"].update(f)
            for k, v in g.items():
                cur["getters"][k] = v
            cur["members"] |= mem
            cur["const"] |= hc
            cur["enum"] |= en
            cur["model"] = fi.rel.startswith(("features/", "core/")) and (
                "/data/models/" in fi.rel or open_class[0].endswith("Model"))
            CLASS_SPANS[(fi, open_class[0])] = (open_class[1], open_class[2], i)
            open_class = None

# extension members folded into their target type
for fi in FILES.values():
    for m in re.finditer(r"^extension\s+(?:\w+\s+)?on\s+(\w+)\s*\{", fi.raw, flags=re.M):
        target = m.group(1)
        start = fi.raw[: m.start()].count("\n")
        tail = "\n".join(fi.raw.splitlines()[start:])
        end = tail.find("\n}")
        ext_body = tail[: end if end > 0 else len(tail)]
        f, g, mem, _, _ = collect_members(ext_body)
        cur = CLASS_MEMBERS.get(target)
        if cur is not None:  # never fabricate a repo class for framework types
            cur["fields"].update(f)
            cur["getters"].update(g)
            cur["members"] |= mem

MODEL_TYPES = {t for t, cm in CLASS_MEMBERS.items() if cm["model"]}

# ---------------------------------------------------------------- G1 gates
DECL = re.compile(r"\b(?:final|const|var)?\s*([A-Z]\w*(?:<[^=;)]*>)?)\s+(\w+)\s*=")
PARAM = re.compile(r"\b([A-Z]\w*(?:<[^(),]*>)?)\s+(\w+)\s*[,)]")
CALLBACK = re.compile(r"([\w.]+)\s*\.\s*(?:map|where|firstWhere|indexWhere|any|every|forEach|followedBy|expand|singleWhere|maxBy|minBy)\(\(\s*(\w+)\b")
FOR_IN = re.compile(r"for\s*\(\s*(?:final\s+|var\s+)?(\w+)\s+in\s+([\w.]+)\s*\)")
PROP = re.compile(r"\b(\w+)\.([a-z_]\w*)(?!\s*[=(\w])")
CHAIN = re.compile(r"\b(\w+)\.(\w+)\.([a-z_]\w*)(?!\s*[=(\w])")
ASSIGN = re.compile(r"\.\w+\s*=[^=]")  # setter: skip member existence claim


def unwrap_type(expr, line_decls_i, fields_of):
    parts = expr.split(".")
    cur = line_decls_i.get(parts[0]) or fields_of.get(parts[0])
    for seg in parts[1:]:
        cm = CLASS_MEMBERS.get(cur or "", {})
        raw = cm.get("fields", {}).get(seg) or cm.get("getters", {}).get(seg)
        if not raw:
            return None
        cur = base_type(raw)
    return cur


for fi in FILES.values():
    lines = fi.raw.splitlines()
    fields_of = {}
    for (f, name), (base, s, e) in [(k, v) for k, v in CLASS_SPANS.items() if k[0] is fi]:
        cm = CLASS_MEMBERS.get(name, {})
        for k, v in cm.get("fields", {}).items():
            fields_of.setdefault(k, base_type(v))
        if base and base.startswith("State"):
            wm = re.match(r"State\s*<\s*(\w+)", base)
            if wm:
                wcm = CLASS_MEMBERS.get(wm.group(1), {})
                for k, v in wcm.get("fields", {}).items():
                    fields_of.setdefault(f"widget.{k}", base_type(v))
    decls = {}
    line_decls = []
    for i, ln in enumerate(lines):
        d = dict(decls)
        sc = code_line(ln)
        for m in PARAM.finditer(sc):
            t, v = m.group(1), m.group(2)
            if t in CLASS_MEMBERS or t in MODEL_TYPES:
                d[v] = base_type(t)
        for m in DECL.finditer(sc):
            d[m.group(2)] = base_type(m.group(1))
        for m in FOR_IN.finditer(sc):
            rt = unwrap_type(m.group(2), d, fields_of)
            if rt:
                d[m.group(1)] = rt
        line_decls.append(d)
        decls = d
    for i, ln in enumerate(lines):
        sc = code_line(ln)
        for m in CALLBACK.finditer(sc):
            rt = unwrap_type(m.group(1), line_decls[i], fields_of)
            if rt:
                line_decls[i][m.group(2)] = rt

    def check(var, member, t, lineno):
        if t not in MODEL_TYPES or t not in CLASS_MEMBERS:
            return
        cm = CLASS_MEMBERS[t]
        if member in cm["members"] or member in cm["fields"] or member in cm["getters"] or member in COMMON_MEMBERS:
            return
        err("G1", fi.path, lineno, f"{t}.{member} not a field/getter/method of the model — API JSON key used as a getter?")

    for i, ln in enumerate(lines):
        sc = code_line(ln)
        for m in PROP.finditer(sc):
            if ASSIGN.search(sc, m.start(), m.end() + 3):
                continue
            var, member = m.group(1), m.group(2)
            t = line_decls[i].get(var) or fields_of.get(var)
            if t is None:
                continue
            check(var, member, t, i + 1)
        for m in CHAIN.finditer(sc):
            basev, mid, member = m.groups()
            key = ".".join((basev, mid))
            t2 = fields_of.get(key)
            if t2 is None:
                t1 = line_decls[i].get(basev)
                if t1 in CLASS_MEMBERS:
                    raw = CLASS_MEMBERS[t1]["fields"].get(mid) or CLASS_MEMBERS[t1]["getters"].get(mid)
                    t2 = base_type(raw) if raw else None
            check(basev, member, t2, i + 1)

RED_FLAGS = {"numberInSurah": "AyahModel exposes `number`; `numberInSurah` is an API JSON key only"}
for fi in FILES.values():
    for i, ln in enumerate(fi.raw.splitlines()):
        # RAW scan, then exempt JSON-key forms; flag only dot access —
        # including inside ${interpolations}, which the lexer pass erases.
        for k, msg in RED_FLAGS.items():
            if f".{k}" in ln and not re.search(rf"\[\\?'{k}'\\?\]|'{k}'\s*:", ln):
                err("G1R", fi.path, i + 1, msg)

# ---------------------------------------------------------------- G2 imports
DEF_INDEX = {}
for fi in FILES.values():
    for d in fi.defs:
        DEF_INDEX.setdefault(d, set()).add(fi.rel)


def resolve_uri(fi, uri):
    if uri.startswith("package:qibra_ai/"):
        p = LIB / uri[len("package:qibra_ai/"):]
    elif uri.startswith("package:") or uri.startswith("dart:"):
        return None
    else:
        p = (fi.path.parent / uri).resolve()
    p = p if p.exists() else pathlib.Path("/nonexistent")
    for k, v in FILES.items():
        if k == p:
            return v
    return None


for fi in FILES.values():
    if fi.is_part:
        continue  # part files share the parent library scope
    provided = set(fi.defs)
    queue = [(fi, uri, 0) for uri in fi.imports]
    seen = set()
    while queue:
        src, uri, hop = queue.pop()
        tgt = resolve_uri(src, uri)
        if tgt is None or (src.rel, uri) in seen or hop > 2:
            continue
        seen.add((src.rel, uri))
        provided |= tgt.defs
        for e in tgt.exports:
            queue.append((tgt, e, hop + 1))
    used_src = fi.code + "\n" + "\n".join(PART_CODE.get(fi.path, []))
    used = set(re.findall(r"\b([A-Z]\w+)\b", used_src))
    for sym in sorted(used):
        providers = DEF_INDEX.get(sym)
        if not providers or sym in provided:
            continue
        err("G2", fi.path, 1, f"'{sym}' referenced but not provided by imports (defined in {sorted(providers)[:3]}) — before REMOVING an import, confirm it provides nothing in use")

# ---------------------------------------------------------------- G3 const
NON_CONST_FLUTTER = {"Transform"}
for fi in FILES.values():
    for i, ln in enumerate(fi.raw.splitlines()):
        s = code_line(ln)
        for m in re.finditer(r"\bconst\s+([A-Z]\w*)(?:\.(\w+))?\s*\(", s):
            name, member = m.group(1), m.group(2)
            if name in NON_CONST_FLUTTER:
                err("G3", fi.path, i + 1, f"const {name}.{member}(...) — {name} has no const constructor")
            elif member is None and name in CLASS_MEMBERS and not CLASS_MEMBERS[name]["const"]:
                err("G3", fi.path, i + 1, f"const {name}(...) — class has no const constructor")

# ---------------------------------------------------------------- G4 context
WIDGET_BASES = ("StatelessWidget", "ConsumerWidget", "StatefulWidget", "ConsumerStatefulWidget")
for fi in FILES.values():
    lines = fi.raw.splitlines()
    for (f, name), (base, s, e) in [(k, v) for k, v in CLASS_SPANS.items() if k[0] is fi]:
        if not base or not base.endswith(WIDGET_BASES):
            continue
        end = e if e is not None else len(lines) - 1
        method_starts = []
        mstart = re.compile(
            r"^  (?:static\s+|const\s+|final\s+|factory\s+)*"
            r"(?:\w+(?:<[^>]*>)?\??\s+)+([A-Za-z_]\w*)\s*(?:<[^>]*>)?\(")
        for j in range(s + 1, end + 1):
            mm = mstart.match(lines[j])
            if mm and "class " not in lines[j]:
                method_starts.append((j, mm.group(1)))
        for idx, (j, mname) in enumerate(method_starts):
            stop = method_starts[idx + 1][0] if idx + 1 < len(method_starts) else end
            win = lines[j: min(j + 16, stop)]
            sig_end = len(win)
            for w, wl in enumerate(win):
                if re.search(r"\)\s*(\{|=>)", wl):
                    sig_end = w + 1
                    break
            sig_txt = "\n".join(win[:sig_end])
            if (mname == "build" or "BuildContext" in sig_txt
                    or re.search(r"[\s({]context[\s,:)]", sig_txt)):
                continue
            body = "\n".join(lines[j: stop])
            for off, ln in enumerate(lines[j: stop]):
                if re.search(r"\bcontext\b", code_line(ln)) and not re.search(r"\bBuildContext\b", code_line(ln)):
                    err("G4", fi.path, j + off + 1, f"bare `context` in {name}.{mname} — {base} has no context field; add a BuildContext param")
                    break

# ------------------------------------------------------------------- G5
# G5a (owner device gate, Home crash): `Row(` whose DIRECT argument list
# contains `crossAxisAlignment: CrossAxisAlignment.stretch`. A horizontal
# Flex stretching its cross axis inside scrollable/unbounded parents throws
# BoxConstraints(h: Infinity) at layout — always a bug in this codebase.
# (Column-stretch is legal and untouched; the scan is per-Row, depth-aware.)
# G5b (Inter font storm): any surviving `GoogleFonts.` reference. Inter and
# Amiri are bundled pubspec families and the package was dropped, so a call
# site cannot even compile. Expected: zero, config line included.
STRETCH_ARG = re.compile(r"crossAxisAlignment:\s*CrossAxisAlignment\.stretch")
for fi in FILES.values():
    for m in re.finditer(r"\bRow\s*\(", fi.code):
        depth, i, hit = 1, m.end(), False
        while i < len(fi.code):
            c = fi.code[i]
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    break
            elif depth == 1 and STRETCH_ARG.match(fi.code, i):
                hit = True
                break
            i += 1
        if hit:
            err("G5a", fi.path, fi.code.count("\n", 0, m.start()) + 1,
                "Row with crossAxisAlignment.stretch — horizontal Flex cannot "
                "stretch inside scrollables (use mainAxisSize/self-sizing children)")
    for m in re.finditer(r"\bGoogleFonts\s*\.", fi.code):
        err("G5b", fi.path, fi.code.count("\n", 0, m.start()) + 1,
            "GoogleFonts call site — fonts are bundled families; remove the "
            "reference (and keep the package out of pubspec)")

# ------------------------------------------------------------------- G6
# G6 duplicate top-level declarations (owner device gate, today:
# `class HabitTemplate` declared twice in habit_defaults.dart — an
# invisible-in-diff compile error). Type names at column 0 per FILE;
# then cross-FILE within each library (file + its `part`s share one
# namespace; a name declared in both parent and part is also a dup).
TOPLEVEL_DECL = re.compile(
    r"^(?:abstract\s+|sealed\s+|final\s+|base\s+|interface\s+|utility\s+)*"
    r"(?:class|enum|mixin|extension|typedef)\s+([A-Za-z_]\w*)", re.M)


def toplevel_decls(text):
    return [(m.group(1), text.count("\n", 0, m.start()) + 1)
            for m in TOPLEVEL_DECL.finditer(text)]


for fi in FILES.values():
    seen = {}
    for name, ln in toplevel_decls(fi.code):
        if name in seen:
            err("G6", fi.path, ln,
                f"duplicate top-level declaration '{name}' "
                f"(also line {seen[name]} in this file)")
        else:
            seen[name] = ln
for fi in FILES.values():
    if fi.is_part or not fi.parts:
        continue
    byname = {}
    for name, ln in toplevel_decls(fi.code):
        byname.setdefault(name, []).append((fi.path, ln))
    for upath in fi.parts:
        pf = FILES.get((fi.path.parent / upath).resolve())
        if pf is None:
            continue
        for name, ln in toplevel_decls(pf.code):
            byname.setdefault(name, []).append((pf.path, ln))
    for name, locs in byname.items():
        if len(locs) < 2:
            continue
        distinct_files = {p for p, _ in locs}
        if len(distinct_files) < 2:
            continue  # same-file dups already reported above
        first_f, first_l = locs[0]
        for p, l in locs[1:]:
            err("G6", p, l, f"top-level '{name}' also declared at "
                f"{pathlib.Path(first_f).name}:{first_l} — one library, "
                f"one namespace (part files count)")

# ------------------------------------------------------------------- G7
# G7 const-with-runtime-colors (owner device gate, today: 9 sites).
# `const Widget(... color: colors.x ...)` cannot compile: the local
# `colors` is `QibraColors.of(context)` — runtime. Any `const <Ident>(`
# whose argument span contains `colors.` is flagged (strings/comments are
# already stripped; `QibraColors.light…` consts are legitimate and do not
# match the lowercase `colors.` token).
CONST_INV = re.compile(r"\bconst\s+[A-Z]\w*\s*\(")
for fi in FILES.values():
    code = fi.code
    skip_to = 0
    for m in CONST_INV.finditer(code):
        if m.start() < skip_to:
            continue
        d, i = 1, m.end()
        while i < len(code):
            c = code[i]
            if c == "(":
                d += 1
            elif c == ")":
                d -= 1
                if d == 0:
                    break
            i += 1
        if re.search(r"\bcolors\.", code[m.end():i]):
            err("G7", fi.path, code.count("\n", 0, m.start()) + 1,
                "const invocation with runtime `colors.` in its arguments — "
                "drop the const")
            skip_to = i  # don't double-report nested consts

# ------------------------------------------------------------------- G8
# G8 icon-name validation (owner: 3 hallucination strikes so far —
# elderhood_rounded, campground_rounded, campground). Every `Icons.<name>`
# must exist in the bundled Flutter metadata scripts/data/
# flutter_icons_stable.txt (see README-icons.md there: the npm
# material-icons set alone is insufficient — base-only, 250 false
# positives on _rounded/_outlined names).

ICON_META = pathlib.Path(__file__).resolve().parent / "data" / "flutter_icons_stable.txt"
if ICON_META.exists():
    ICON_SET = set(ICON_META.read_text(encoding="utf-8").split())
    for fi in FILES.values():
        for m in re.finditer(r"\bIcons\.([A-Za-z0-9_]+)", fi.code):
            if m.group(1) not in ICON_SET:
                err("G8", fi.path, fi.code.count("\n", 0, m.start()) + 1,
                    f"Icons.{m.group(1)} is not a Flutter Material icon "
                    f"(not in bundled icons.dart metadata)")
else:
    ERRORS.append("G8 metadata missing: scripts/data/flutter_icons_stable.txt "
                  "(regenerate — see scripts/data/README-icons.md)")

# --------------------------------------------------- L design sweeps
def in_stage(rel):
    return any(fnmatch.fnmatch(rel, g) for g in GLOBS)


for fi in FILES.values():
    rel = fi.rel
    design_allow = rel.startswith(("core/design_system/", "core/theme/"))
    presentation = (("/presentation/" in rel or rel.startswith("features/tools/screens/"))
                    and not design_allow)
    counts = {"L1": 0, "L6": 0, "L7": 0}
    for i, ln in enumerate(fi.raw.splitlines()):
        s = code_line(ln)
        if not s.strip():
            continue
        if presentation and not design_allow:
            if "Color(0x" in s:
                counts["L1"] += 1
                if in_stage(rel):
                    err("L1", fi.path, i + 1, "raw Color(0x…) in presentation file")
            m = re.search(r"withValues\(alpha:\s*([0-9.]+)\)", s)
            if m and float(m.group(1)) > 0.16 and "onPrimary" not in s:
                WARNINGS.append(f"L2 {rel}:{i + 1}: alpha {m.group(1)} — needs scrim/wash exception")
            if ".repeat(" in s and "LinearProgressIndicator" not in s and "Indeterminate" not in s:
                counts["L6"] += 1
                if in_stage(rel):
                    err("L6", fi.path, i + 1, "looping animation controller")
            for ch in re.findall(r"[\U0001F300-\U0001FAFF\u2600-\u27BF\u2B00-\u2BFF\uFE0F]", ln):
                counts["L7"] += 1
                if in_stage(rel):
                    err("L7", fi.path, i +1 , f"emoji {ch!r}")
        if "colors.cardElevated" in s:
            err("L4", fi.path, i + 1, "QibraColors has no cardElevated field (use cardMuted)")
        if "const QibraStatus(" in s and rel != "shared/widgets/qibra_status.dart":
            err("L5", fi.path, i + 1, "QibraStatus must never be const at call sites")
        if "/data/" not in rel and not design_allow and 'fontFamily: \'Amiri\'' in s:
            err("L3", fi.path, i + 1, "dangling fontFamily:'Amiri' literal — use AppArabicStyles")
    for k, v in counts.items():
        if v:
            STAGE_PENDING.setdefault(rel, {})[k] = v

def balanced_scan(text):
    s = strip_noise(text)
    return {"parens": s.count("(") - s.count(")"),
            "braces": s.count("{") - s.count("}"),
            "brackets": s.count("[") - s.count("]")}


# empty bodies + balance
for fi in FILES.values():
    if re.search(r"Widget \w+\(\{[^)]*\}\)\s*\{\s*\}", fi.code):
        err("L8", fi.path, 0, "EMPTY WIDGET BODY (historical corruption guard)")
    bal = balanced_scan(fi.raw)
    for nm, d in bal.items():
        if d != 0:
            err("L8", fi.path, 0, f"unbalanced {nm} ({d:+d} in code text)")

# ------------------------------------------------------------------- G9
# G9 sync-queue due() retry reachability (owner device gate 2026-09-02:
# SyncQueue.due() delegated to the pending-only getter, so failed ops
# carrying a nextRetryAt were never re-attempted — a silent offline-queue
# deadlock no compile/test/battery gate caught, and no gate can reason
# about reachability the types allow. Static approximation: in any file
# that declares retry semantics (`RetryAt`), a `due(...)` filter that
# mentions `pending` without `failed`/`Retry`/`retry` is a finding.
DUE_M = re.compile(r"\bdue\s*\([^)]*\)\s*(?:=>|\{)")
for fi in FILES.values():
    code = fi.code
    if not re.search(r"RetryAt|retryAt", code):
        continue
    for m in DUE_M.finditer(code):
        seg = code[m.end():m.end() + 300]
        depth, cut = 0, 0
        for i, c in enumerate(seg):
            if c in "([{":
                depth += 1
            elif c in ")]}":
                depth -= 1
            elif c == ";" and depth <= 0:
                cut = i
                break
        seg = seg[:cut] if cut else seg
        if re.search(r"\bpending\b", seg) and not re.search(
                r"failed|Retry|retry", seg):
            err("G9", fi.path, code.count("\n", 0, m.start()) + 1,
                "due() filters pending-only while this file declares retry "
                "semantics — failed ops with a retry date never become due "
                "(offline queue deadlock)")

# ------------------------------------------------------------------- G10/G11
# G10 double-comma (owner device gate 2026-09-02, lean pass: two `,,` in
# nikah_guide_data.dart survived a `color:`-line deletion in a generated
# data file — balance scans balance-blind to it, Dart does not compile
# it). Any `,,` in comment/string-stripped code is a finding.
for fi in FILES.values():
    for mm in re.finditer(r",,", fi.code):
        err("G10", fi.path, fi.code.count("\n", 0, mm.start()) + 1,
            "double comma `,` `,` — dangling entry from an edit that "
            "deleted a list item body but not its trailing comma")

# G11 accidental nesting (owner device gate 2026-09-02, lean pass: the
# two Ramadan calendar classes landed INSIDE _IslamicEvent because a
# generated block was appended before the file's final `}` anchored on
# raw position. Dart forbids nested classes; note the bug sat at column
# ZERO, so an indent-only check would miss it — brace-depth catches it).
# Rule: a class/enum/mixin declaration at brace depth > 0 is a finding.
NESTED_DECL = re.compile(
    r"^(?:\s*)(?:abstract\s+|final\s+|base\s+|sealed\s+|interface\s+)*"
    r"(?:class|enum|mixin)\s+(_?\w+)", re.M)
for fi in FILES.values():
    code = fi.code
    depth = 0
    starts = [m.start() for m in NESTED_DECL.finditer(code)]
    pos = 0
    for i, c in enumerate(code):
        if i in (0,):
            continue
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
        while pos < len(starts) and starts[pos] <= i:
            if depth > 0:
                ln = code.count("\n", 0, starts[pos]) + 1
                err("G11", fi.path, ln,
                    "class/enum/mixin declared inside braces — Dart "
                    "forbids nested classes (generated-block insertion "
                    "anchor bug)")
            pos += 1

# ------------------------------------------------------------------- report
print(f"static battery: {len(FILES)} dart files under {LIB}")
if GLOBS:
    print(f"stage globs: {GLOBS}")
if STAGE_PENDING and not GLOBS:
    print(f"--- design sweeps pending (file counts, gate only via --check-glob) ---")
    tot = {"L1": 0, "L6": 0, "L7": 0}
    for rel, d in STAGE_PENDING.items():
        for k, v in d.items():
            tot[k] += v
    print(f"    files with findings: {len(STAGE_PENDING)}  L1(hex)={tot['L1']} L6(loop)={tot['L6']} L7(emoji)={tot['L7']}")
if WARNINGS:
    print("--- L2 alpha warnings ---")
    for w in WARNINGS[:40]:
        print(" ", w)
    if len(WARNINGS) > 40:
        print(f"   …{len(WARNINGS) - 40} more")
if ERRORS:
    print(f"--- {len(ERRORS)} FINDINGS ---")
    for e in ERRORS:
        print(" ", e)
    sys.exit(1)
print("ALL GATES PASS (static; device compile remains the authority)")
