import 'package:autolog/data/remote/supabase_client.dart';
import 'package:autolog/features/scan/edge_function_invoker.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exceção lançada quando o email informado não corresponde a nenhum usuário
/// cadastrado no sistema.
class ShareEmailNotFoundException implements Exception {
  ShareEmailNotFoundException(this.email);

  final String email;

  @override
  String toString() => 'ShareEmailNotFoundException: email não encontrado ($email)';
}

/// Contrato do serviço de compartilhamento de veículo.
abstract class ShareVehicleService {
  /// Compartilha [vehicleId] com o usuário de [memberEmail].
  ///
  /// Retorna o `user_id` do membro adicionado.
  /// Lança [ShareEmailNotFoundException] se o email não for encontrado (404).
  /// Lança [ScanException] em outros erros de rede/backend.
  Future<String> shareWith({
    required String vehicleId,
    required String memberEmail,
  });
}

/// Implementação real que invoca a Edge Function `share-vehicle`.
class RealShareVehicleService implements ShareVehicleService {
  RealShareVehicleService(this._invoker);

  final EdgeFunctionInvoker _invoker;

  @override
  Future<String> shareWith({
    required String vehicleId,
    required String memberEmail,
  }) async {
    try {
      final body = await _invoker.invoke('share-vehicle', {
        'vehicle_id': vehicleId,
        'member_email': memberEmail,
      });
      return body['member_user_id'] as String;
    } on ScanException catch (e) {
      // O EdgeFunctionInvoker mapeia 404 para ScanException com mensagem
      // contendo o status. Verificamos a mensagem para detectar email_not_found.
      // Pattern: "Erro ao chamar função (404)"
      if (e.message.contains('404')) {
        throw ShareEmailNotFoundException(memberEmail);
      }
      rethrow;
    } catch (e) {
      if (e is ShareEmailNotFoundException) rethrow;
      throw ScanException('Falha ao compartilhar veículo', cause: e);
    }
  }
}

/// Implementação mock para testes.
class MockShareVehicleService implements ShareVehicleService {
  MockShareVehicleService({
    this.fixedMemberUserId = 'mock-user-id',
    this.throwEmailNotFound = false,
    this.throwGenericError = false,
    this.delay = const Duration(milliseconds: 300),
  });

  final String fixedMemberUserId;
  final bool throwEmailNotFound;
  final bool throwGenericError;
  final Duration delay;

  int callCount = 0;
  String? lastVehicleId;
  String? lastMemberEmail;

  @override
  Future<String> shareWith({
    required String vehicleId,
    required String memberEmail,
  }) async {
    callCount++;
    lastVehicleId = vehicleId;
    lastMemberEmail = memberEmail;
    await Future<void>.delayed(delay);
    if (throwEmailNotFound) throw ShareEmailNotFoundException(memberEmail);
    if (throwGenericError) {
      throw ScanException('Erro simulado pelo MockShareVehicleService');
    }
    return fixedMemberUserId;
  }
}

/// Provider do serviço de compartilhamento de veículo.
final shareVehicleServiceProvider = Provider<ShareVehicleService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RealShareVehicleService(SupabaseEdgeFunctionInvoker(client));
});
