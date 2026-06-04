/// Lógica pura que decide se o onboarding deve ser exibido.
///
/// Separada de qualquer framework para facilitar testes unitários.
///
/// Regras NOVAS (fix caso B — onboarding é marketing pré-login):
/// - Já viu → false (nunca mais, independente do estado de auth).
/// - Logado → false (já é usuário; passou da fase de conversão).
/// - Nunca viu E não logado → true (fluxo pré-login é exatamente o ponto de exibição).
bool shouldShowOnboarding({required bool seen, required bool isLoggedIn}) {
  if (seen) return false;
  // Já é usuário — onboarding é marketing pré-login, não tutorial pós-login.
  if (isLoggedIn) return false;
  return true;
}
