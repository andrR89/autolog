// lib/features/auth/account_deletion/account_deletion_service.dart
//
// Sprint 7.3 — LGPD: exclusão de conta (Art. 18, VI LGPD).
//
// Contrato de domínio + implementações real e mock.
// Fluxo pós-sucesso:
//   1. Chama Edge Function delete-account (hard delete no servidor)
//   2. Limpa todos os dados Drift locais via raw SQL (customStatement)
//   3. Faz signOut do Supabase (sessão já inválida no servidor)
//   4. O router detecta auth null e redireciona para /login

import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/remote/supabase_client.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Exceção de domínio
// ---------------------------------------------------------------------------

/// Lançada quando a exclusão de conta falha no backend ou na limpeza local.
class AccountDeletionException implements Exception {
  const AccountDeletionException(this.message);

  final String message;

  @override
  String toString() => 'AccountDeletionException: $message';
}

// ---------------------------------------------------------------------------
// Contrato abstrato
// ---------------------------------------------------------------------------

/// Serviço de exclusão de conta.
///
/// Responsabilidades:
///   - Chamar a Edge Function `delete-account` autenticada
///   - Limpar o banco Drift local via SQL puro
///   - Fazer signOut do Supabase Auth
///
/// Lança [AccountDeletionException] em caso de falha.
abstract class AccountDeletionService {
  Future<void> deleteAccount();
}

// ---------------------------------------------------------------------------
// Tabelas locais a limpar (ordered por dependência lógica)
// ---------------------------------------------------------------------------

/// Tabelas a deletar no SQLite local.
/// Ordem: filhos de vehicles antes de vehicles; tabelas de user antes das de auth.
/// O SQLite local não enforça FKs por padrão, mas a ordem é semanticamente correta.
const _kLocalTables = [
  'fuel_entries',
  'expenses',
  'reminders',
  'fines',
  'insurances',
  'trips',
  'vehicle_members',
  'chat_messages',
  'notifications_log',
  'calendar_event_links',
  'fipe_history',
  'fipe_cache',
  'fiscal_lookup_cache',
  'vehicles',
  'user_profile',
  'usage_quota',
  'user_settings',
];

// ---------------------------------------------------------------------------
// Implementação real
// ---------------------------------------------------------------------------

class RealAccountDeletionService implements AccountDeletionService {
  const RealAccountDeletionService({
    required SupabaseClient supabase,
    required DatabaseConnectionUser db,
  }) : _supabase = supabase,
       _db = db;

  final SupabaseClient _supabase;

  /// Tipado como [DatabaseConnectionUser] (base do Drift) para usar apenas
  /// [customStatement], sem depender de acessores gerados por code-gen.
  final DatabaseConnectionUser _db;

  @override
  Future<void> deleteAccount() async {
    // 1. Chama a Edge Function com o JWT do usuário autenticado
    try {
      final response = await _supabase.functions.invoke(
        'delete-account',
        method: HttpMethod.post,
      );

      // A Edge Function retorna 200 em ambos os casos (success e already_deleted)
      if (response.status != 200) {
        final data = response.data;
        final errorMsg = (data is Map && data['error'] != null)
            ? data['error'] as String
            : 'Erro desconhecido ao excluir a conta.';
        throw AccountDeletionException(errorMsg);
      }
    } on AccountDeletionException {
      rethrow;
    } catch (_) {
      throw const AccountDeletionException(
        'Não foi possível conectar ao servidor. Verifique sua conexão.',
      );
    }

    // 2. Limpa dados locais do Drift via raw SQL
    await _clearLocalData();

    // 3. SignOut do Supabase (sessão já foi invalidada no servidor)
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // Ignora erros de signOut — sessão já foi destruída no servidor.
      // O router redireciona para /login assim que o stream de auth emite null.
    }
  }

  Future<void> _clearLocalData() async {
    // Usa customStatement (raw SQL) para independência do código gerado.
    // Deleta todas as tabelas locais; tabelas que não existirem são ignoradas
    // silenciosamente pelo SQLite (IF EXISTS).
    for (final table in _kLocalTables) {
      await _db.customStatement('DELETE FROM "$table"');
    }
  }
}

// ---------------------------------------------------------------------------
// Mock para testes
// ---------------------------------------------------------------------------

/// Implementação mock de [AccountDeletionService] para testes unitários.
///
/// Permite configurar se deve ter sucesso ou lançar exceção, e rastreia
/// chamadas para verificação de comportamento.
class MockAccountDeletionService implements AccountDeletionService {
  MockAccountDeletionService({
    this.shouldThrow = false,
    this.exceptionMessage = 'Erro simulado de exclusão.',
    this.delayMs = 0,
  });

  final bool shouldThrow;
  final String exceptionMessage;
  final int delayMs;

  int callCount = 0;

  @override
  Future<void> deleteAccount() async {
    callCount++;
    if (delayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
    if (shouldThrow) {
      throw AccountDeletionException(exceptionMessage);
    }
  }
}

// ---------------------------------------------------------------------------
// Provider Riverpod
// ---------------------------------------------------------------------------

/// Provider que expõe o [AccountDeletionService] para uso no app.
final accountDeletionServiceProvider = Provider<AccountDeletionService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return RealAccountDeletionService(supabase: supabase, db: db);
});
