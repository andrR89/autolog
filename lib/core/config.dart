/// Configuração do Supabase injetada via --dart-define-from-file.
/// Nunca hardcode credenciais aqui — use dart_define.json (gitignored).
class SupabaseConfig {
  /// Construtor validante. Lança [ArgumentError] com mensagem em PT-BR
  /// se [url] for vazia, não começar com "https://", ou se [anonKey] for vazia.
  SupabaseConfig({required this.url, required this.anonKey}) {
    if (url.isEmpty) {
      throw ArgumentError('A URL do Supabase não pode ser vazia.');
    }
    if (!url.startsWith('https://')) {
      throw ArgumentError(
        'A URL do Supabase deve começar com "https://". Recebido: "$url".',
      );
    }
    if (anonKey.isEmpty) {
      throw ArgumentError('A chave anon do Supabase não pode ser vazia.');
    }
  }

  /// Lê as credenciais injetadas via --dart-define-from-file e valida.
  factory SupabaseConfig.fromEnvironment() {
    return SupabaseConfig(
      url: const String.fromEnvironment('SUPABASE_URL'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
  }

  final String url;
  final String anonKey;
}
