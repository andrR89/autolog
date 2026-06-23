// Tradução do erro técnico do sync para mensagem PT-BR amigável.
//
// Pareia com auth_error_mapper: mantém a entidade no diagnóstico (útil pra
// suporte) mas troca o `StateError(...)` / `PostgrestException(...)` cru por
// frases que o usuário final consegue ler.

/// Converte qualquer erro de [SyncResult.pullError] em mensagem PT-BR.
///
/// Mantém o nome das entidades que falharam (lista crua de `vehicles, fuel,
/// ...`) — esse pedaço é útil mesmo pra leigos. Substitui só o WRAPPER do
/// erro técnico (`StateError`, `PostgrestException`, `SocketException`) por
/// frase amigável.
String mapSyncErrorToUserMessage(Object err) {
  final raw = err.toString();
  final lower = raw.toLowerCase();

  if (lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('clientexception') ||
      lower.contains('handshakeexception')) {
    return 'Sem conexão. Verifique sua internet e tente novamente.';
  }

  if (lower.contains('infinite recursion') || lower.contains('42p17')) {
    return 'Erro de configuração no servidor. A equipe foi avisada — '
        'tente novamente em alguns minutos.';
  }

  if (lower.contains('row-level security') ||
      lower.contains('rls') ||
      lower.contains('permission denied') ||
      lower.contains('not allowed') ||
      lower.contains('42501')) {
    return 'Você não tem permissão pra acessar esses dados. '
        'Faça logout e entre de novo se o problema persistir.';
  }

  if (lower.contains('jwt') ||
      lower.contains('invalid token') ||
      lower.contains('not authenticated')) {
    return 'Sua sessão expirou. Faça login de novo.';
  }

  if (lower.contains('timeout') || lower.contains('timed out')) {
    return 'O servidor demorou pra responder. Tente de novo em instantes.';
  }

  // Lista cua de entidades é informativa o suficiente — extrai e usa.
  final entitiesMatch = RegExp(
    r'sync errors?: ([\w, ]+?)(?: —|$)',
  ).firstMatch(raw);
  if (entitiesMatch != null) {
    final entities = entitiesMatch.group(1)!.trim();
    return 'Não consegui sincronizar: $entities. Tente novamente.';
  }

  return 'Não foi possível sincronizar agora. Tente novamente em instantes.';
}
