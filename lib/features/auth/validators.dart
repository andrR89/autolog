// Validadores puros para formulários de autenticação.
//
// Retornam `null` quando o valor é válido, ou uma mensagem de erro em PT-BR.
// Projetados para uso com [TextFormField.validator].

/// Valida o campo de e-mail.
///
/// - Vazio ou null → "Informe o email"
/// - Sem formato de e-mail válido → "Email inválido"
/// - Válido → null
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Informe o email';
  }
  // Regex simples mas suficiente: local@domínio.tld, sem espaços.
  final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  if (!emailRegex.hasMatch(value)) {
    return 'Email inválido';
  }
  return null;
}

/// Valida o campo de senha.
///
/// - Vazio ou null → "Informe a senha"
/// - Menos de 6 caracteres → "A senha deve ter ao menos 6 caracteres"
/// - Válido → null
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Informe a senha';
  }
  if (value.length < 6) {
    return 'A senha deve ter ao menos 6 caracteres';
  }
  return null;
}
