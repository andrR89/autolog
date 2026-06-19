import 'package:supabase_flutter/supabase_flutter.dart';

String mapAuthErrorToUserMessage(AuthException e) {
  if (e is AuthRetryableFetchException) {
    return 'Sem conexão. Verifique sua internet e tente novamente.';
  }
  final msg = e.message.toLowerCase();
  if (msg.contains('socketexception') ||
      msg.contains('failed host lookup') ||
      msg.contains('clientexception')) {
    return 'Sem conexão. Verifique sua internet e tente novamente.';
  }
  if (msg.contains('invalid login credentials') ||
      msg.contains('invalid email or password')) {
    return 'E-mail ou senha incorretos.';
  }
  if (msg.contains('email not confirmed')) {
    return 'Confirme seu e-mail antes de entrar.';
  }
  if (msg.contains('too many requests')) {
    return 'Muitas tentativas. Aguarde alguns minutos.';
  }
  return 'Erro de autenticação. Tente novamente.';
}
