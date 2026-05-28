// google_calendar_service.dart — Integração com Google Calendar (one-way sync).
//
// RealGoogleCalendarService: usa google_sign_in v7 + googleapis.
//   Requer OAuth Client IDs configurados (ver docs/google-calendar-setup.md).
//   Sem credentials → falha graciosa (retorna null/false, nunca crasha).
//
// MockGoogleCalendarService: padrão ativo. Toggle de conexão pra ver UX.

import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/features/calendar/calendar_event_link_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/googleapis_auth.dart' as gauth;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Abstração
// ---------------------------------------------------------------------------

abstract class GoogleCalendarService {
  /// Retorna true se o usuário está autenticado e com Calendar conectado.
  Future<bool> isConnected();

  /// E-mail da conta Google conectada, ou null se não conectado.
  Future<String?> connectedEmail();

  /// Dispara o fluxo OAuth para conectar o Google Calendar.
  Future<void> connect();

  /// Desconecta (sign out + limpa links locais).
  Future<void> disconnect();

  /// Cria ou atualiza um evento no Calendar para o [reminder].
  /// Retorna o calendarEventId criado/atualizado, ou null em caso de falha.
  Future<String?> upsertEvent(Reminder reminder);

  /// Remove o evento [calendarEventId] do Calendar.
  Future<void> deleteEvent(String calendarEventId);
}

// ---------------------------------------------------------------------------
// Mock — padrão ativo enquanto OAuth não está configurado
// ---------------------------------------------------------------------------

class MockGoogleCalendarService implements GoogleCalendarService {
  bool _connected = false;
  String? _email;
  int upsertCallCount = 0;
  int deleteCallCount = 0;
  String? lastUpsertedReminderId;
  String? lastDeletedEventId;

  @override
  Future<bool> isConnected() async => _connected;

  @override
  Future<String?> connectedEmail() async => _connected ? _email : null;

  @override
  Future<void> connect() async {
    _connected = true;
    _email = 'mock@google.com';
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _email = null;
  }

  @override
  Future<String?> upsertEvent(Reminder reminder) async {
    if (!_connected) return null;
    upsertCallCount++;
    lastUpsertedReminderId = reminder.id;
    // Retorna um event ID simulado determinístico.
    return 'mock-event-${reminder.id}';
  }

  @override
  Future<void> deleteEvent(String calendarEventId) async {
    if (!_connected) return;
    deleteCallCount++;
    lastDeletedEventId = calendarEventId;
  }

  /// Permite resetar o estado nos testes.
  void reset() {
    _connected = false;
    _email = null;
    upsertCallCount = 0;
    deleteCallCount = 0;
    lastUpsertedReminderId = null;
    lastDeletedEventId = null;
  }
}

// ---------------------------------------------------------------------------
// Real — requer OAuth Client IDs configurados no Google Cloud Console.
// Ver docs/google-calendar-setup.md para instruções de setup.
//
// google_sign_in v7 API:
//   - GoogleSignIn() sem parâmetros no construtor.
//   - initialize(clientId: ...) antes do primeiro uso.
//   - attemptLightweightAuthentication() para silent sign-in.
//   - authenticate() para interactive sign-in.
//
// TODO (pós-setup OAuth): substituir TODOs pelas chamadas reais à Calendar API.
// ---------------------------------------------------------------------------

class RealGoogleCalendarService implements GoogleCalendarService {
  RealGoogleCalendarService(this._linkRepo);

  final CalendarEventLinkRepository _linkRepo;

  static const _calendarScopes = [gcal.CalendarApi.calendarEventsScope];

  // google_sign_in v7: singleton via GoogleSignIn.instance.
  final _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;
  GoogleSignInAccount? _currentUser;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      // TODO (pós-setup OAuth): passar clientId correto para cada plataforma.
      // iOS: usar o REVERSED_CLIENT_ID invertido, ou deixar o Info.plist configurar.
      // Android: o SHA1 + bundle ID no Google Cloud cuida do client.
      await _googleSignIn.initialize();
      _initialized = true;
    } catch (_) {
      // Se não há credentials → marcamos como inicializado (falha graciosa).
      _initialized = true;
    }
  }

  @override
  Future<bool> isConnected() async {
    try {
      await _ensureInitialized();
      // attemptLightweightAuthentication retorna Future? (null se plataforma
      // não suporta silent sign-in — ex: web sem popup prévio).
      final future = _googleSignIn.attemptLightweightAuthentication();
      if (future == null) return false;
      final account = await future;
      _currentUser = account;
      return account != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> connectedEmail() async {
    try {
      if (_currentUser != null) return _currentUser!.email;
      final connected = await isConnected();
      return connected ? _currentUser?.email : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> connect() async {
    try {
      await _ensureInitialized();
      // authenticate() dispara o fluxo interativo de sign-in.
      final account = await _googleSignIn.authenticate(
        scopeHint: _calendarScopes,
      );
      _currentUser = account;
    } catch (_) {
      // Falha graciosa — usuário pode tentar novamente.
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
    } catch (_) {
      // Falha silenciosa.
    }
  }

  @override
  Future<String?> upsertEvent(Reminder reminder) async {
    try {
      final authClient = await _authenticatedClient();
      if (authClient == null) return null;

      final existingEventId = await _linkRepo.getEventIdFor(reminder.id);
      final event = _buildEvent(reminder);

      // TODO (pós-setup OAuth): ativar chamadas reais à Calendar API.
      // Exemplo de uso quando OAuth estiver configurado:
      //
      //   final api = gcal.CalendarApi(authClient);
      //   if (existingEventId != null) {
      //     final updated = await api.events.update(event, 'primary', existingEventId);
      //     return updated.id;
      //   } else {
      //     final created = await api.events.insert(event, 'primary');
      //     return created.id;
      //   }
      //
      // Por ora: valida construção e fecha client.
      assert(event.summary != null);
      authClient.close();

      // Retorna o eventId existente (upsert mantém o link); null para novo.
      return existingEventId;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteEvent(String calendarEventId) async {
    try {
      final authClient = await _authenticatedClient();
      if (authClient == null) return;

      // TODO (pós-setup OAuth): ativar chamadas reais à Calendar API.
      // Exemplo de uso quando OAuth estiver configurado:
      //
      //   final api = gcal.CalendarApi(authClient);
      //   await api.events.delete('primary', calendarEventId);
      //
      authClient.close();
    } catch (_) {
      // Falha silenciosa — evento pode já não existir no Calendar.
    }
  }

  /// Retorna um client HTTP autenticado com o token do GoogleSignIn v7.
  /// Usa [GoogleSignInAuthorizationClient.authorizationHeaders] para obter
  /// os headers de autenticação Bearer.
  /// Retorna null se não há sessão ativa ou as credentials não estão configuradas.
  Future<http.Client?> _authenticatedClient() async {
    try {
      if (_currentUser == null) {
        final connected = await isConnected();
        if (!connected) return null;
      }

      final account = _currentUser;
      if (account == null) return null;

      // authorizationClient é getter do GoogleSignInAccount (v7).
      final authorizationClient = account.authorizationClient;
      final headers =
          await authorizationClient.authorizationHeaders(_calendarScopes);
      if (headers == null) return null;

      // Extrai Bearer token dos headers.
      final bearerToken =
          headers['Authorization']?.replaceFirst('Bearer ', '');
      if (bearerToken == null) return null;

      final credentials = gauth.AccessCredentials(
        gauth.AccessToken(
          'Bearer',
          bearerToken,
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        _calendarScopes,
      );

      return gauth.authenticatedClient(http.Client(), credentials);
    } catch (_) {
      return null;
    }
  }

  gcal.Event _buildEvent(Reminder reminder) {
    final formatter = DateFormat('d MMM yyyy', 'pt_BR');

    final summary = reminder.title;
    final buffer = StringBuffer('Lembrete do AutoLog');

    if (reminder.dueDate != null) {
      buffer.write(' — vence em ${formatter.format(reminder.dueDate!)}');
    }
    if (reminder.dueKm != null) {
      buffer.write(' — vence em ${reminder.dueKm} km');
    }

    // Se tiver data de vencimento, usa ela; senão cria evento de hoje.
    final eventDate = reminder.dueDate?.toUtc() ?? DateTime.now().toUtc();

    return gcal.Event(
      summary: summary,
      description: buffer.toString(),
      start: gcal.EventDateTime(
        dateTime: eventDate,
        timeZone: 'America/Sao_Paulo',
      ),
      end: gcal.EventDateTime(
        dateTime: eventDate.add(const Duration(hours: 1)),
        timeZone: 'America/Sao_Paulo',
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider Riverpod
// ---------------------------------------------------------------------------

/// Instância global do GoogleCalendarService.
/// Por enquanto retorna MockGoogleCalendarService — nenhum OAuth necessário.
///
/// Para ativar o serviço real após configurar o OAuth:
///   1. Siga docs/google-calendar-setup.md.
///   2. Substitua MockGoogleCalendarService() por:
///      RealGoogleCalendarService(ref.watch(calendarEventLinkRepositoryProvider))
final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  return MockGoogleCalendarService();
});
