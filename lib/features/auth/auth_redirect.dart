// Lógica pura de redirect baseada no estado de sessão do usuário.
//
// Separa a decisão de navegação de qualquer framework, permitindo
// testes unitários sem Flutter ou Supabase.

/// Conjunto de rotas consideradas "de autenticação" (login / cadastro).
const authRoutes = {'/login', '/signup'};

/// Retorna o destino do redirect, ou `null` se não é necessário redirecionar.
///
/// Regras:
/// - Não logado **fora** de rota de auth → `/login`
/// - Não logado **em** rota de auth → null (permanece onde está)
/// - Logado **em** rota de auth → `/home`
/// - Logado em `/onboarding` → null (o onboarding está autorizado para logados)
/// - Logado **fora** de rota de auth → null (permanece onde está)
String? authRedirect({required bool isLoggedIn, required String location}) {
  final isAuthRoute = authRoutes.contains(location);

  if (!isLoggedIn && !isAuthRoute) {
    return '/login';
  }

  if (isLoggedIn && isAuthRoute) {
    return '/home';
  }

  return null;
}
