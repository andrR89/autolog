// Lógica pura de redirect baseada no estado de sessão do usuário.
//
// Separa a decisão de navegação de qualquer framework, permitindo
// testes unitários sem Flutter ou Supabase.

/// Conjunto de rotas consideradas "de autenticação" (login / cadastro).
const authRoutes = {'/login', '/signup'};

/// Rotas acessíveis sem autenticação (além das authRoutes).
///
/// `/onboarding` está aqui porque o onboarding é marketing pré-login —
/// ele aparece ANTES de o usuário ter uma conta (fix caso B, 04/06/2026).
const publicRoutes = {'/onboarding'};

/// Retorna o destino do redirect, ou `null` se não é necessário redirecionar.
///
/// Regras:
/// - Não logado **fora** de rota pública ou de auth → `/login`
/// - Não logado **em** rota de auth ou pública → null (permanece onde está)
/// - Logado **em** rota de auth → `/home`
/// - Logado em rota pública → null (permanece onde está)
/// - Logado **fora** de rota de auth/pública → null (permanece onde está)
String? authRedirect({required bool isLoggedIn, required String location}) {
  final isAuthRoute = authRoutes.contains(location);
  final isPublicRoute = publicRoutes.contains(location);

  if (!isLoggedIn && !isAuthRoute && !isPublicRoute) {
    return '/login';
  }

  if (isLoggedIn && isAuthRoute) {
    return '/home';
  }

  return null;
}
