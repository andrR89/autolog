// Testes da função pura `mapAuthErrorToUserMessage`.
//
// Motivação (Homologação 2026-06-18, bug MÉDIO no login):
//   Quando o backend Supabase estava inacessível (DNS quebrado), a UI mostrava
//   a exception crua na SnackBar:
//
//   "Erro de autenticação: ClientException with SocketException: Failed host
//    lookup: 'vdtlldfklcrtpuumfkbm.supabase.co' (OS Error: ... errno = 8),
//    uri=https://vdtlldfklcrtpuumfkbm.supabase.co/auth/v1/token?grant_type=password"
//
//   Além de horrível pra UX, **vaza o subdomínio do projeto Supabase**.
//
// A função pura `mapAuthErrorToUserMessage` deve transformar qualquer
// `AuthException` (incluindo `AuthRetryableFetchException`) em uma mensagem
// PT-BR amigável SEM expor URL, stack ou detalhes do backend.

import 'package:autolog/features/auth/auth_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('credenciais e estados conhecidos (regression do mapeamento atual)', () {
    test('"invalid login credentials" → mensagem PT-BR de senha errada', () {
      final result = mapAuthErrorToUserMessage(
        const AuthException('Invalid login credentials', statusCode: '400'),
      );
      expect(result, 'E-mail ou senha incorretos.');
    });

    test('"email not confirmed" → mensagem PT-BR de confirmação', () {
      final result = mapAuthErrorToUserMessage(
        const AuthException('Email not confirmed', statusCode: '400'),
      );
      expect(result, 'Confirme seu e-mail antes de entrar.');
    });

    test('"too many requests" → mensagem PT-BR de rate limit', () {
      final result = mapAuthErrorToUserMessage(
        const AuthException('Too many requests', statusCode: '429'),
      );
      expect(result, 'Muitas tentativas. Aguarde alguns minutos.');
    });
  });

  group('erro de rede (caso do bug)', () {
    test(
      'AuthRetryableFetchException (DNS quebrado) → "Sem conexão"',
      () {
        final result = mapAuthErrorToUserMessage(
          AuthRetryableFetchException(
            message:
                "ClientException with SocketException: Failed host lookup: 'vdtlldfklcrtpuumfkbm.supabase.co' (OS Error: nodename nor servname provided, or not known, errno = 8), uri=https://vdtlldfklcrtpuumfkbm.supabase.co/auth/v1/token?grant_type=password",
          ),
        );
        expect(result, 'Sem conexão. Verifique sua internet e tente novamente.');
      },
    );

    test('message contém "SocketException" → "Sem conexão"', () {
      final result = mapAuthErrorToUserMessage(
        const AuthException('SocketException: connection refused'),
      );
      expect(result, 'Sem conexão. Verifique sua internet e tente novamente.');
    });

    test('message contém "Failed host lookup" → "Sem conexão"', () {
      final result = mapAuthErrorToUserMessage(
        const AuthException('Failed host lookup: example.com'),
      );
      expect(result, 'Sem conexão. Verifique sua internet e tente novamente.');
    });

    test('message contém "ClientException" → "Sem conexão"', () {
      final result = mapAuthErrorToUserMessage(
        const AuthException('ClientException with HandshakeException'),
      );
      expect(result, 'Sem conexão. Verifique sua internet e tente novamente.');
    });
  });

  group('default genérico (nunca vaza message)', () {
    test('AuthException desconhecida → mensagem genérica PT-BR sem detalhes', () {
      final result = mapAuthErrorToUserMessage(
        const AuthException(
          'some unexpected backend boom at https://example.com/foo',
          statusCode: '500',
        ),
      );
      expect(result, 'Erro de autenticação. Tente novamente.');
      // Não pode vazar URL nem texto cru da exception.
      expect(result, isNot(contains('https://')));
      expect(result, isNot(contains('boom')));
    });

    test('AuthException com message vazia → mensagem genérica PT-BR', () {
      final result = mapAuthErrorToUserMessage(
        const AuthException('', statusCode: '500'),
      );
      expect(result, 'Erro de autenticação. Tente novamente.');
    });
  });

  group('garantia de não-vazamento (defesa em profundidade)', () {
    // Cobre regressões futuras: se alguém adicionar um caso novo que volte a
    // concatenar a message crua, este teste pega.
    test(
      'NENHUMA saída vaza "supabase.co", "uri=" ou "SocketException"',
      () {
        const leakyA =
            'ClientException with SocketException: Failed host lookup:'
            " 'vdtlldfklcrtpuumfkbm.supabase.co' (OS Error: ... errno = 8),"
            ' uri=https://vdtlldfklcrtpuumfkbm.supabase.co/auth/v1/token';
        const leakyInputs = [
          leakyA,
          'something random with https://vdtlldfklcrtpuumfkbm.supabase.co inside',
          'unknown error uri=https://supabase.co/auth/v1/foo',
        ];
        for (final input in leakyInputs) {
          final result = mapAuthErrorToUserMessage(
            AuthException(input, statusCode: null),
          );
          expect(
            result,
            isNot(contains('supabase.co')),
            reason: 'vazou supabase.co em "$input" → "$result"',
          );
          expect(
            result,
            isNot(contains('uri=')),
            reason: 'vazou uri= em "$input" → "$result"',
          );
          expect(
            result,
            isNot(contains('SocketException')),
            reason: 'vazou SocketException em "$input" → "$result"',
          );
        }
      },
    );
  });
}
