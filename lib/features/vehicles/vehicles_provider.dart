import 'package:autolog/data/remote/supabase_client.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream reativo da lista de veículos do usuário autenticado.
///
/// Deriva o userId do SupabaseClient diretamente (fonte de verdade de sessão).
/// Lança [StateError] se chamado sem sessão ativa — o router garante que
/// o usuário está logado antes de chegar nessa tela.
final vehiclesProvider = StreamProvider<List<Vehicle>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;
  if (session == null) {
    throw StateError(
      'vehiclesProvider: nenhuma sessão ativa. '
      'O router deveria ter redirecionado para /login.',
    );
  }
  final userId = session.user.id;
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.watchByUser(userId);
});

/// Expõe o userId do usuário autenticado atualmente.
///
/// Lança [StateError] se não houver sessão — não deve acontecer nas telas
/// protegidas pelo authRedirect.
final currentUserIdProvider = Provider<String>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;
  if (session == null) {
    throw StateError('currentUserIdProvider: nenhuma sessão ativa.');
  }
  return session.user.id;
});
