/// Lógica pura que decide se o onboarding deve ser exibido.
///
/// Separada de qualquer framework para facilitar testes unitários.
///
/// Regras:
/// - Não logado → false (a tela de auth tem precedência).
/// - Logado + já viu → false.
/// - Logado + nunca viu → true.
bool shouldShowOnboarding({required bool seen, required bool isLoggedIn}) {
  if (!isLoggedIn) return false;
  return !seen;
}
