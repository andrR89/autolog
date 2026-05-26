# Spec — Sprint 0.5: Login/cadastro + fluxo de sessão (Supabase Auth)

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa; André homologa em device.
> Fonte: `docs/ARCHITECTURE.md §1` (Auth) + Regras de Ouro. Depende de 0.4 (Supabase init + provider).

## Escopo
Tela de login e cadastro com **email/senha** e **"Entrar com Google"** (fluxo OAuth via navegador — o Web Client já está configurado no Supabase), mais o **fluxo de sessão** (redirect automático login↔app conforme autenticado) e o **deep link** iOS pro callback do Google.

Fora de escopo: telas internas do app (só um `/home` placeholder), recuperação de senha, edição de perfil, Google nativo (iOS client ID — melhoria futura).

## Decisões técnicas

### 1. Camada de auth abstraída (testável)
`lib/features/auth/auth_service.dart`:
- `abstract class AuthService` com: `Stream<bool> get authStateChanges` (true=logado), `bool get isLoggedIn`, `Future<void> signUpWithEmail(String email, String password)`, `Future<void> signInWithEmail(...)`, `Future<void> signInWithGoogle()`, `Future<void> signOut()`.
- `SupabaseAuthService implements AuthService` — envolve `supabase.auth`. `signInWithGoogle` chama `signInWithOAuth(OAuthProvider.google, redirectTo: 'io.supabase.autolog://login-callback/')`. (Revisado, não unit-testado — rede.)
- Provider Riverpod `authServiceProvider`.

### 2. Validadores puros (testável)
`lib/features/auth/validators.dart` — funções puras retornando `String?` (null = válido; senão mensagem PT-BR), no formato de validator de `TextFormField`:
- `validateEmail(String?)`: vazio → "Informe o email"; sem formato de email válido → "Email inválido"; ok → null.
- `validatePassword(String?)`: vazio → "Informe a senha"; menos de 6 chars → "A senha deve ter ao menos 6 caracteres"; ok → null. (6 = mínimo padrão do Supabase.)

### 3. Lógica de redirect pura (testável)
`lib/features/auth/auth_redirect.dart`:
```dart
const authRoutes = {'/login', '/signup'};
/// Destino do redirect, ou null se não deve redirecionar.
String? authRedirect({required bool isLoggedIn, required String location});
```
Regras: não-logado fora de rota de auth → `/login`; logado em rota de auth → `/home`; senão → null.

### 4. Roteamento + sessão
`go_router` (já no pubspec) com rotas `/login`, `/signup`, `/home` (placeholder PT-BR "Em breve"), usando `authRedirect` no `redirect` e ouvindo `authStateChanges` via `refreshListenable`. App passa a usar o router (em `lib/app.dart`).

### 5. UI (PT-BR)
- `lib/features/auth/login_screen.dart` e `signup_screen.dart` (ou uma tela com toggle). Campos email/senha com os validadores, botão primário (Entrar/Cadastrar), botão "Entrar com Google", link para alternar login↔cadastro. Estados de loading e erro (SnackBar/inline com mensagem PT-BR amigável; mapear erros comuns do Supabase, ex. credenciais inválidas).
- Não bloquear UI; mostrar progresso durante a chamada.

### 6. Deep link iOS
`ios/Runner/Info.plist`: registrar `CFBundleURLTypes` com scheme `io.supabase.autolog` (pro callback `io.supabase.autolog://login-callback/`).

## Critérios de aceite

**Testes (verdes):**
- `test/features/auth/validators_test.dart`:
  1. `validateEmail`: vazio→erro; "abc"→erro; "a@b.com"→null.
  2. `validatePassword`: vazio→erro; "12345"→erro; "123456"→null.
- `test/features/auth/auth_redirect_test.dart`:
  3. não-logado em `/home` → `/login`.
  4. não-logado em `/login` → null; em `/signup` → null.
  5. logado em `/login` → `/home`; em `/signup` → `/home`.
  6. logado em `/home` → null.

**Deliverables (revisão Haiku + homologação André):**
7. Login/cadastro por email/senha funcionando contra o projeto Supabase real.
8. Botão Google dispara o fluxo OAuth (testável após André adicionar o redirect URL no Supabase).
9. Sessão persiste e o redirect leva pro `/home` quando logado, `/login` quando não.

## Definition of Done
- Testes acima verdes; suíte completa verde; `dart format`; `flutter analyze` limpo.
- App builda e roda no simulador iOS com `--dart-define-from-file=dart_define.json`.
- Deep link iOS configurado.
- Mensagens de UI em PT-BR.
- Follow-ups anotados: Google nativo (iOS client ID); recuperação de senha.
