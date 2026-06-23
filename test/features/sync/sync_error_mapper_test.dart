// Testes de mapSyncErrorToUserMessage — pareia com auth_error_mapper_test.
//
// Critério: NUNCA vaza StateError(...), PostgrestException(...), uri=,
// supabase.co, SocketException nem stack trace pro usuário final.

import 'package:autolog/features/sync/sync_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('rede', () {
    test('SocketException → Sem conexão', () {
      final r = mapSyncErrorToUserMessage(
        StateError(
          'sync errors: vehicles — vehicles: ClientException with '
          'SocketException: Failed host lookup',
        ),
      );
      expect(
        r,
        'Sem conexão. Verifique sua internet e tente novamente.',
      );
    });

    test('Failed host lookup → Sem conexão', () {
      final r = mapSyncErrorToUserMessage(
        Exception('Failed host lookup: example.supabase.co'),
      );
      expect(
        r,
        'Sem conexão. Verifique sua internet e tente novamente.',
      );
    });

    test('HandshakeException → Sem conexão', () {
      final r = mapSyncErrorToUserMessage(
        Exception('HandshakeException: TLS handshake failed'),
      );
      expect(
        r,
        'Sem conexão. Verifique sua internet e tente novamente.',
      );
    });
  });

  group('servidor', () {
    test('infinite recursion (42P17) → mensagem genérica de servidor', () {
      final r = mapSyncErrorToUserMessage(
        StateError(
          'sync errors: vehicles — vehicles: PostgrestException(message: '
          'infinite recursion detected in policy, code: 42P17)',
        ),
      );
      expect(
        r,
        'Erro de configuração no servidor. A equipe foi avisada — '
        'tente novamente em alguns minutos.',
      );
    });

    test('row-level security → sem permissão', () {
      final r = mapSyncErrorToUserMessage(
        Exception(
          'PostgrestException(message: new row violates row-level security '
          'policy, code: 42501)',
        ),
      );
      expect(r, startsWith('Você não tem permissão'));
    });

    test('JWT expirado → sessão expirou', () {
      final r = mapSyncErrorToUserMessage(
        Exception('JWT expired'),
      );
      expect(r, 'Sua sessão expirou. Faça login de novo.');
    });

    test('timeout → mensagem específica', () {
      final r = mapSyncErrorToUserMessage(
        Exception('Operation timed out after 30s'),
      );
      expect(r, 'O servidor demorou pra responder. Tente de novo em instantes.');
    });
  });

  group('fallback', () {
    test('lista de entidades é preservada como informação útil', () {
      final r = mapSyncErrorToUserMessage(
        StateError(
          'sync errors: vehicles, fuel, expenses — vehicles: Some random '
          'PostgrestException blah blah',
        ),
      );
      expect(r, 'Não consegui sincronizar: vehicles, fuel, expenses. Tente novamente.');
    });

    test('erro totalmente desconhecido → genérico', () {
      final r = mapSyncErrorToUserMessage(
        Exception('Boom unexpected something at https://example.com/foo'),
      );
      expect(
        r,
        'Não foi possível sincronizar agora. Tente novamente em instantes.',
      );
    });
  });

  group('defesa em profundidade — nunca vaza ruído técnico', () {
    test('NENHUMA saída contém supabase.co, uri= ou PostgrestException', () {
      const leakyA =
          'PostgrestException(message: error, details: error at '
          "'vdtlldfklcrtpuumfkbm.supabase.co')";
      const leaky = [
        leakyA,
        'uri=https://vdtlldfklcrtpuumfkbm.supabase.co/rest/v1/vehicles',
        'StateError: stack trace at #0 Object.foo',
        'Boom random with https://supabase.co inside',
      ];
      for (final input in leaky) {
        final r = mapSyncErrorToUserMessage(Exception(input));
        expect(
          r,
          isNot(contains('supabase.co')),
          reason: 'vazou supabase.co em "$input" → "$r"',
        );
        expect(
          r,
          isNot(contains('uri=')),
          reason: 'vazou uri= em "$input" → "$r"',
        );
        expect(
          r,
          isNot(contains('PostgrestException')),
          reason: 'vazou PostgrestException em "$input" → "$r"',
        );
        expect(
          r,
          isNot(contains('StateError')),
          reason: 'vazou StateError em "$input" → "$r"',
        );
      }
    });
  });
}
