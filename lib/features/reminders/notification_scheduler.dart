import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/reminder.dart';

/// Interface para agendamento de notificações locais de lembretes.
///
/// Apenas lembretes do tipo [ReminderType.porData] geram notificação.
/// [ReminderType.porKm] é no-op aqui (Sprint 4.4 cuida).
abstract class NotificationScheduler {
  /// Inicializa o plugin (canais, timezone). Chamado uma vez no boot do app.
  /// Idempotente. NÃO solicita permissão — use [requestPermissionIfNeeded].
  Future<void> init();

  /// Solicita permissão de notificação ao SO. Chamado on-demand (ex.: antes
  /// de salvar o primeiro lembrete por data) — NÃO no boot, pra evitar
  /// popup fora de contexto. Idempotente em iOS.
  Future<bool> requestPermissionIfNeeded();

  /// Agenda/atualiza a notificação do reminder. No-op se:
  /// - reminder.type != porData
  /// - reminder.isDone == true
  /// - reminder.dueDate == null
  /// - reminder.dueDate.isBefore(now()) (data já passada)
  /// - reminder.deletedAt != null
  ///
  /// Substitui silenciosamente qualquer notificação anterior com o mesmo id.
  Future<void> scheduleReminder(Reminder reminder);

  /// Cancela a notificação pendente do reminder, se existir. Idempotente.
  Future<void> cancelReminder(String reminderId);

  /// Dispara uma notificação imediata (não-agendada). [id] é usado para evitar
  /// duplicatas se chamado em rápida sucessão.
  Future<void> showNow({
    required String id,
    required String title,
    required String body,
  });
}

/// Implementação fake de [NotificationScheduler] para testes e desenvolvimento.
///
/// Vive em `lib/` (não em `test/`) para que os testes possam importá-la,
/// seguindo o mesmo padrão de [FakeImageSource].
class FakeNotificationScheduler implements NotificationScheduler {
  final Map<String, Reminder> scheduled = {};
  final List<String> cancelled = [];
  final List<({String id, String title, String body})> fired = [];
  int initCalls = 0;
  int permissionRequests = 0;
  bool permissionGranted = true;

  @override
  Future<void> init() async => initCalls++;

  @override
  Future<bool> requestPermissionIfNeeded() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> scheduleReminder(Reminder r) async {
    if (r.type != ReminderType.porData) return;
    if (r.isDone) return;
    if (r.dueDate == null) return;
    if (r.dueDate!.isBefore(DateTime.now())) return;
    if (r.deletedAt != null) return;
    scheduled[r.id] = r;
  }

  @override
  Future<void> cancelReminder(String id) async {
    scheduled.remove(id);
    cancelled.add(id);
  }

  @override
  Future<void> showNow({
    required String id,
    required String title,
    required String body,
  }) async {
    fired.add((id: id, title: title, body: body));
  }
}
