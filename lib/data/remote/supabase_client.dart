import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider que expõe o [SupabaseClient] já inicializado.
///
/// Pré-requisito: [Supabase.initialize] foi chamado em [main] antes de
/// [runApp]. Acessar este provider sem inicialização prévia lança exceção.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
