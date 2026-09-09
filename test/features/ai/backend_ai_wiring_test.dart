import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/source_guards.dart';

// (Rev. 3) The comment-stripper lives in test/support/source_guards.dart —
// shared with ai_responsiveness, whose negated pins need the same honesty.

/// AI level 0-1 wiring guards (source-level; the runtime battery is
/// scripts/static_battery.py). These pin the exact strings the shipped
/// backend contract (docs/DEPLOY.md) depends on — if a refactor drifts
/// from them, the app silently breaks against the live service, so they
/// fail loudly here instead.
void main() {
  group('backend base URL — single source', () {
    final constants =
        File('lib/core/constants/app_constants.dart').readAsStringSync();

    test('production base is the live Render origin', () {
      expect(
        constants.contains(
            "static const String baseUrlProduction = 'https://qibra-ai.onrender.com';"),
        isTrue,
      );
    });

    test('the old api.qibra.ai name is gone from network files', () {
      for (final path in [
        'lib/core/constants/app_constants.dart',
        'lib/core/network/api_client.dart',
        'lib/features/ai/providers/ai_provider.dart',
      ]) {
        expect(File(path).readAsStringSync().contains('api.qibra.ai'), isFalse,
            reason: path);
      }
    });

    test('routes mount at the root — no /v1 prefix anywhere', () {
      expect(constants.contains("static const String apiVersion = '';"), isTrue);
      expect(constants.contains("static const String apiUrl = baseUrl;"), isTrue);
      expect(constants.contains("'/v1'"), isFalse);
    });

    test('the /ai/ask endpoint constant exists and is what the provider uses', () {
      expect(constants.contains("static const String endpointAiAsk = '/ai/ask';"),
          isTrue);
      final provider =
          File('lib/features/ai/providers/ai_provider.dart').readAsStringSync();
      expect(provider.contains('AppApi.endpointAiAsk'), isTrue);
      expect(provider.contains('endpointAiChat'), isFalse,
          reason: 'the backend has no /ai/chat — it must not be referenced');
    });

    test('backend is enabled (owner flip 2026-09-02, abee22e)', () {
      expect(
        constants.contains('static const bool isBackendEnabled = true;'),
        isTrue,
        reason: 're-check before flipping back: the honest no-backend '
            'branches in ChatNotifier still exist for the false state',
      );
    });
  });

  group('streaming + conversation memory', () {
    final provider =
        File('lib/features/ai/providers/ai_provider.dart').readAsStringSync();

    test('SSE typewriter surface exists and is fed from deltas', () {
      expect(provider.contains("ValueNotifier<String> liveAnswer"), isTrue);
      expect(provider.contains("case 'delta':"), isTrue);
      expect(provider.contains('liveAnswer.value = acc.toString();'), isTrue);
      expect(provider.contains('ResponseType.stream'), isTrue);
      expect(provider.contains("headers: const {'Accept': 'text/event-stream'}"),
          isTrue);
    });

    test('payload is {query, corpus, history, stream} — never the Groq key', () {
      for (final needle in [
        "'query': query",
        "'corpus': corpus",
        "'history': history",
        "'stream': true",
      ]) {
        expect(provider.contains(needle), isTrue, reason: needle);
      }
      // 'groq' as a bare word appears in SECURITY COMMENTS in this file
      // (that is documentation, not a leak) — scanning for it produced a
      // false positive. What must never appear in client CODE are the
      // real secrets, checked on comment-stripped source.
      final code = stripCommentsForGuard(provider);
      for (final secret in ['gsk_', 'api.groq.com', 'GROQ_API_KEY', 'Bearer ']) {
        expect(code.contains(secret), isFalse,
            reason: 'no Groq material on the client — "$secret" in CODE '
                'means the key/prompt layer leaked client-side');
      }
      // And the security comments themselves must stay in place:
      expect(provider.contains('GROQ SECURITY'), isTrue,
          reason: 'the guard is only honest while the comment explains it');
    });

    test('conversation memory is capped and sent with each ask', () {
      expect(provider.contains('_conversationHistory.length > 20'), isTrue);
      expect(provider.contains('historyForServer'), isTrue);
    });

    test('non-stream fallback posts stream:false to the same endpoint', () {
      // Whitespace-tolerant anchor. The old exact-string indexOf went to
      // -1 (RangeError) the moment dart format reflowed the call — a
      // formatting change must fail with a CLEAR message, not a crash.
      final anchor = RegExp(
          r'final resp = await ApiClient\.instance\s*\.post\(AppApi\.endpointAiAsk');
      final m = anchor.firstMatch(provider);
      expect(m, isNotNull,
          reason: 'the non-stream fallback must call ApiClient.instance'
              '.post(AppApi.endpointAiAsk — did the call change shape?');
      final fallback = provider.substring(m!.start);
      expect(fallback.contains("'stream': false"), isTrue);
    });
  });

  group('citation chips deep-link to the reader', () {
    final screen =
        File('lib/features/ai/presentation/ai_explain_screen.dart').readAsStringSync();

    test('the [surah:ayah] regex is bounded to real ayat', () {
      expect(screen.contains(r"RegExp(r'\[(\d{1,3}):(\d{1,4})\]')"), isTrue);
      expect(screen.contains('surah >= 1 && surah <= 114 && ayah >= 1'), isTrue);
    });

    test('taps build the reader deep link', () {
      expect(screen.contains('AppRoutes.surahReader'), isTrue);
      expect(screen.contains("'surah': '\${tag.surah}'"), isTrue);
      expect(screen.contains("'ayah': '\${tag.ayah}'"), isTrue);
    });

    test('typing bubble renders live text while streaming', () {
      expect(screen.contains('chat.liveAnswer'), isTrue);
      expect(screen.contains('ValueListenableBuilder<String>'), isTrue);
    });
  });

  group('no-hits may still ask the backend (owner 2026-09-02)', () {
    test('empty retrieval falls through to the labelled backend answer', () {
      final provider =
          File('lib/features/ai/providers/ai_provider.dart').readAsStringSync();
      expect(provider.contains('final canAskBackend = AppApi.isBackendEnabled && !offline;'),
          isTrue);
      expect(provider.contains('if (!actionish && noLocalHits && !canAskBackend)'),
          isTrue);
      expect(provider.contains('_localRefusalFor(userMessage)'), isTrue);
      expect(
        provider.contains(
            'Is sawal ka koi retrieved Quran ya Hadith passage nahi mila.'),
        isTrue,
        reason: 'local refusal mirrors Roman Urdu queries',
      );
      expect(provider.contains('_finishBackendAnswer(resp.data, query: userMessage)'),
          isTrue);
      expect(provider.contains('serverText.trim().isNotEmpty'), isTrue,
          reason: 'the backend scholar-refusal text must be surfaced verbatim');
    });

    test('the app bridge is the retrieval front door', () {
      final rag =
          File('lib/features/ai/services/rag_service.dart').readAsStringSync();
      expect(rag.contains('static const Map<String, List<String>> romanUrduBridge'),
          isTrue);
      expect(rag.contains('static List<String> expandQuery(String query)'), isTrue);
      expect(rag.contains('static List<String> correctionsFor(String token)'),
          isTrue);
      expect(rag.contains('static bool looksRomanUrdu(String query)'), isTrue);
      expect(rag.contains('final primary = <String>[query, ...expandQuery(query).take(6)];'),
          isTrue);
    });

    test('backend ships the labelled general-knowledge contract', () {
      final client = File('backend/app/groq_client.py').readAsStringSync();
      expect(
        client.contains(
            '"General knowledge answer \u2014 no specific passage was retrieved. "'),
        isTrue,
      );
      expect(client.contains('def is_fatwa_query('), isTrue);
      expect(client.contains('def fatwa_refusal_message('), isTrue);
      final router = File('backend/app/routers/ai.py').readAsStringSync();
      expect(router.contains('return await _general(body)'), isTrue);
      expect(router.contains('GENERAL_LABEL'), isTrue);
    });
  });

  group('docs', () {
    test('DEPLOY.md pins the live Render origin', () {
      final doc = File('docs/DEPLOY.md').readAsStringSync();
      expect(doc.contains('https://qibra-ai.onrender.com'), isTrue);
      expect(doc.contains('GROQ_API_KEY'), isTrue);
    });
  });
}
