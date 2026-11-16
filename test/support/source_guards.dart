/// Shared source-scan helpers for the file-level guard tests.
/// (Rev. 3: extracted from test/backend_ai_wiring_test.dart — the class D
/// guard proved comment text must not trip `contains` pins, and the same
/// hazard bit the ai_responsiveness buildContextForQuery pin. One stripper,
/// two honest users.)
library;

/// Removes /* */ and // comments, preserving URL scheme literals like
/// `https://` (only `//` runs preceded by whitespace/line-start count as a
/// comment opener — the same rule the class D guard pinned).
String stripCommentsForGuard(String src) => src
    .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
    .replaceAll(RegExp(r'(?<=[\s\n])//[^\n]*'), '')
    .replaceAll(RegExp(r'^\s*//[^\n]*', multiLine: true), '');
