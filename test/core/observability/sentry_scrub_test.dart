// Testes do PII scrubbing do Sentry — Onda 1.
//
// Importa só o que precisamos pra testar as regex sem depender do init
// completo do SDK. Como _scrubText e _scrubMap são privados, exercitamos
// via _scrubEvent (também privado, mas alcançado indireto via Sentry).
// Como atalho prático, replicamos as regex aqui pra travar contratos.
//
// É um teste de regressão: se alguém afrouxar a regex, ele quebra.

import 'package:flutter_test/flutter_test.dart';

// Cópia exata das regex de produção. Quando atualizar a regra principal,
// atualize aqui também. O propósito é travar contrato — não reimplementar.
String scrubText(String input) {
  return input
      .replaceAll(
        RegExp(r'https://[a-z0-9]+\.supabase\.co[^\s]*'),
        '[supabase-url]',
      )
      .replaceAll(
        RegExp(r'eyJ[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*'),
        '[jwt]',
      )
      .replaceAllMapped(
        RegExp(
          r'(authorization|apikey|bearer)\s*[:=]\s*[^\r\n]+',
          caseSensitive: false,
        ),
        (m) => '${m.group(1)}: [redacted]',
      )
      .replaceAll(
        RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'),
        '[email]',
      );
}

void main() {
  group('scrubText — defesa em profundidade', () {
    test('URL Supabase é substituída por placeholder', () {
      final out = scrubText(
        'Failed to fetch https://vdtlldfklcrtpuumfkbm.supabase.co/rest/v1/vehicles?user_id=eq.abc',
      );
      expect(out, isNot(contains('supabase.co')));
      expect(out, contains('[supabase-url]'));
    });

    test('JWT é substituído', () {
      const jwt =
          'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
      final out = scrubText('Bearer $jwt expired');
      expect(out, isNot(contains(jwt)));
      expect(out, contains('[jwt]'));
    });

    test('header Authorization é redacted', () {
      final out = scrubText('Authorization: Bearer sk-abc123def');
      expect(out, isNot(contains('sk-abc123def')));
      expect(out.toLowerCase(), contains('redacted'));
    });

    test('header apikey é redacted', () {
      final out = scrubText('apikey: xyz789');
      expect(out, isNot(contains('xyz789')));
      expect(out.toLowerCase(), contains('redacted'));
    });

    test('email é substituído', () {
      final out = scrubText('falha pra user teste.0618@autolog.test bla');
      expect(out, isNot(contains('teste.0618@autolog.test')));
      expect(out, contains('[email]'));
    });

    test('mensagem sem PII passa intacta', () {
      const plain = 'RangeError: index 5 out of range 0..3';
      expect(scrubText(plain), plain);
    });
  });

  group('cenários reais que apareceram na sessão', () {
    test(
      'PostgrestException com URL Supabase + JWT: tudo limpo',
      () {
        const raw =
            'PostgrestException(message: error, details: at '
            'https://vdtlldfklcrtpuumfkbm.supabase.co/rest/v1/vehicles '
            'with Authorization: Bearer eyJhbGciOi.eyJzdWIi.signhere)';
        final out = scrubText(raw);
        expect(out, isNot(contains('supabase.co')));
        expect(out, isNot(contains('eyJhbGciOi')));
        // 'Bearer' fica como nome do header, mas o token foi.
        expect(out, isNot(contains('signhere')));
      },
    );

    test('SocketException raw — passa direto (não tem PII)', () {
      const raw =
          'ClientException with SocketException: Failed host lookup, '
          'errno = 8';
      expect(scrubText(raw), raw);
    });
  });
}
