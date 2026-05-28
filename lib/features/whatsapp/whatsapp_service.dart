// whatsapp_service.dart — Integração com bot WhatsApp via Twilio.
//
// RealWhatsAppService: chama a Edge Function whatsapp-generate-code para
//   gerar o código de pareamento. Consulta whatsapp_links no Supabase para
//   verificar status de pareamento.
//   Requer Twilio + Edge Functions configurados (ver docs/whatsapp-setup.md).
//
// MockWhatsAppService: padrão ativo. Toggle de pareamento em memória.

import 'package:autolog/data/remote/supabase_client.dart';
import 'package:autolog/features/scan/edge_function_invoker.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Abstração
// ---------------------------------------------------------------------------

abstract class WhatsAppService {
  /// Retorna true se o número de WhatsApp do usuário está pareado.
  Future<bool> isPaired();

  /// Retorna o número de telefone pareado, ou null se não pareado.
  Future<String?> pairedPhoneNumber();

  /// Gera um código de pareamento de 6 dígitos e retorna o código.
  ///
  /// Lança [ScanException] em caso de falha de rede ou do backend.
  Future<String> generatePairingCode();

  /// Remove o pareamento do número WhatsApp do usuário.
  Future<void> unpair();
}

// ---------------------------------------------------------------------------
// Mock — padrão ativo enquanto Twilio não está configurado
// ---------------------------------------------------------------------------

class MockWhatsAppService implements WhatsAppService {
  bool _paired = false;
  String? _phone;
  String? _lastCode;

  @override
  Future<bool> isPaired() async => _paired;

  @override
  Future<String?> pairedPhoneNumber() async => _paired ? _phone : null;

  @override
  Future<String> generatePairingCode() async {
    _lastCode = '123456';
    return _lastCode!;
  }

  @override
  Future<void> unpair() async {
    _paired = false;
    _phone = null;
  }

  /// Simula o pareamento com um número de telefone (apenas em testes/mock).
  void simulatePairing(String phone) {
    _paired = true;
    _phone = phone;
  }

  /// Expõe o último código gerado (para testes).
  String? get lastCode => _lastCode;

  /// Reseta o estado (para testes).
  void reset() {
    _paired = false;
    _phone = null;
    _lastCode = null;
  }
}

// ---------------------------------------------------------------------------
// Real — requer Edge Function whatsapp-generate-code + Twilio configurado.
// Ver docs/whatsapp-setup.md para instruções de setup.
// ---------------------------------------------------------------------------

class RealWhatsAppService implements WhatsAppService {
  RealWhatsAppService(this._invoker, this._client);

  final EdgeFunctionInvoker _invoker;
  final SupabaseClient _client;

  @override
  Future<bool> isPaired() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _client
          .from('whatsapp_links')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> pairedPhoneNumber() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('whatsapp_links')
          .select('phone_number')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return response['phone_number'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> generatePairingCode() async {
    final result = await _invoker.invoke('whatsapp-generate-code', {});
    final code = result['code'];
    if (code is! String) {
      throw ScanException('Resposta inesperada da função whatsapp-generate-code');
    }
    return code;
  }

  @override
  Future<void> unpair() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client
          .from('whatsapp_links')
          .delete()
          .eq('user_id', userId);
    } catch (_) {
      // Falha silenciosa — o estado será atualizado no próximo isPaired().
    }
  }
}

// ---------------------------------------------------------------------------
// Provider Riverpod
// ---------------------------------------------------------------------------

/// Instância global do WhatsAppService.
/// Retorna RealWhatsAppService por padrão — não requer OAuth setup no lado Dart.
///
/// Para usar MockWhatsAppService em testes, override o provider:
///   ProviderScope(overrides: [whatsAppServiceProvider.overrideWithValue(MockWhatsAppService())])
final whatsAppServiceProvider = Provider<WhatsAppService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RealWhatsAppService(SupabaseEdgeFunctionInvoker(client), client);
});
