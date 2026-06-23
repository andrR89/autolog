// Product analytics — PostHog wrapper com fallback noop.
//
// Como ligar: passa POSTHOG_API_KEY e POSTHOG_HOST via --dart-define.
// Vazios = noop silencioso (todos os métodos retornam sem fazer nada).
//
// O que NUNCA mandamos pro PostHog:
//   - email, senha, JWT, refresh_token, placa, RENAVAM, chassi
//   - valores financeiros do usuário (litros, preço, total, despesa, FIPE)
//   - nicknames de veículo (podem ter PII tipo "Carro do Pai")
//   - mensagens livres do user (descrição de despesa, nome de posto)
//
// O que mandamos:
//   - eventos canônicos com props anônimas (counts, tipos, booleans)
//   - distinct_id estável (UUID do supabase auth — não é email)
//   - $screen_name (rota atual) via PosthogObserver
//
// Eventos canônicos — atualizar AnalyticsEvent e documentar AQUI quando
// adicionar. Cada evento tem **prop schema fixo**.

import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

const _kPosthogKey = String.fromEnvironment('POSTHOG_API_KEY');
const _kPosthogHost = String.fromEnvironment(
  'POSTHOG_HOST',
  defaultValue: 'https://us.i.posthog.com',
);

/// True se a integração está habilitada (chave injetada via build).
bool get analyticsEnabled => _kPosthogKey.isNotEmpty;

/// Inicializa o PostHog se POSTHOG_API_KEY foi injetada.
/// Chamado uma única vez em main.dart, ANTES do runApp.
Future<void> initAnalytics() async {
  if (!analyticsEnabled) return;
  final config = PostHogConfig(_kPosthogKey)
    ..host = _kPosthogHost
    ..debug = kDebugMode
    // PostHog roda capture própria de events; desativamos pra ter controle.
    ..captureApplicationLifecycleEvents = true
    // Sem session replay no MVP (custa quota + privacidade complexa).
    ..sessionReplay = false;
  await Posthog().setup(config);
}

/// Vincula o evento ao usuário autenticado. Chamado após login bem-sucedido.
/// [userId] tem que ser o UUID do supabase auth — NUNCA email ou nickname.
Future<void> analyticsIdentify(String userId) async {
  if (!analyticsEnabled) return;
  await Posthog().identify(userId: userId);
}

/// Limpa o distinct_id (chamado no logout).
Future<void> analyticsReset() async {
  if (!analyticsEnabled) return;
  await Posthog().reset();
}

/// Catálogo canônico de eventos. **Toda mudança aqui é review obrigatório**
/// — quebra dashboards e funnels já configurados.
enum AnalyticsEvent {
  // Onboarding / auth
  onboardingStart('onboarding_start'),
  onboardingComplete('onboarding_complete'),
  signupComplete('signup_complete'),
  loginSuccess('login_success'),
  logout('logout'),

  // Vehicle
  vehicleCreated('vehicle_created'),
  vehicleEdited('vehicle_edited'),
  vehicleDeleted('vehicle_deleted'),
  vehicleFipeSearchUsed('vehicle_fipe_search_used'),

  // Fuel / scan
  fuelEntryCreated('fuel_entry_created'),
  scanReceiptOpened('scan_receipt_opened'),
  scanReceiptSucceeded('scan_receipt_succeeded'),
  scanReceiptFailed('scan_receipt_failed'),
  quotaExhausted('quota_exhausted'),

  // Expenses / reminders
  expenseCreated('expense_created'),
  reminderCreated('reminder_created'),
  reminderCompleted('reminder_completed'),

  // Reports / insights
  reportsOpened('reports_opened'),
  comparePeriodOpened('compare_period_opened'),
  recapOpened('recap_opened'),

  // Export
  exportCsvUsed('export_csv_used'),
  exportPdfUsed('export_pdf_used'),

  // Premium funnel
  paywallView('paywall_view'),
  paywallCta('paywall_cta'),

  // Errors / friction (observabilidade UX)
  syncFailureShown('sync_failure_shown');

  const AnalyticsEvent(this.wire);
  final String wire;
}

/// Captura um evento canônico. [props] devem ser tipos primitivos (String, num,
/// bool) — nunca passe Decimal, DateTime cru, ou objetos de domínio.
///
/// Os valores das props passam por [_isSafeProp] — vou rejeitar silenciosamente
/// chaves suspeitas (email, password, token) pra travar contrato em runtime
/// mesmo se alguém esquecer.
Future<void> track(
  AnalyticsEvent event, {
  Map<String, Object>? props,
}) async {
  if (!analyticsEnabled) return;
  Map<String, Object>? safe;
  if (props != null) {
    safe = {};
    for (final entry in props.entries) {
      if (_isSafeProp(entry.key, entry.value)) {
        safe[entry.key] = entry.value;
      }
    }
  }
  await Posthog().capture(eventName: event.wire, properties: safe);
}

/// Marca a tela atual — alimenta `$screen_name` em todos os events seguintes.
Future<void> trackScreen(String name) async {
  if (!analyticsEnabled) return;
  await Posthog().screen(screenName: name);
}

/// Filtro de segurança: rejeita props com nome ou valor PII-suspeito.
bool _isSafeProp(String key, Object value) {
  final lower = key.toLowerCase();
  if (lower.contains('email') ||
      lower.contains('password') ||
      lower.contains('token') ||
      lower.contains('jwt') ||
      lower.contains('plate') ||
      lower.contains('placa') ||
      lower.contains('chassi') ||
      lower.contains('renavam') ||
      lower.contains('nickname') ||
      lower.contains('description') ||
      lower.contains('station_name')) {
    return false;
  }
  // Numeric/bool/short string OK. String longa = suspeita (free text).
  if (value is String && value.length > 64) return false;
  return true;
}
