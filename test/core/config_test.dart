import 'package:autolog/core/config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 0.4 — validação de SupabaseConfig.
/// Spec: docs/specs/sprint-0.4-supabase.md
void main() {
  group('SupabaseConfig', () {
    test('aceita url https e anonKey não-vazia', () {
      final config = SupabaseConfig(
        url: 'https://x.supabase.co',
        anonKey: 'chave-anon',
      );
      expect(config.url, 'https://x.supabase.co');
      expect(config.anonKey, 'chave-anon');
    });

    test('rejeita url vazia', () {
      expect(() => SupabaseConfig(url: '', anonKey: 'k'), throwsArgumentError);
    });

    test('rejeita url sem https://', () {
      expect(
        () => SupabaseConfig(url: 'http://x.supabase.co', anonKey: 'k'),
        throwsArgumentError,
      );
    });

    test('rejeita anonKey vazia', () {
      expect(
        () => SupabaseConfig(url: 'https://x.supabase.co', anonKey: ''),
        throwsArgumentError,
      );
    });
  });
}
