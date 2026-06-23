// Sentry crash reporting — bootstrap + privacy scrubbing.
//
// Como ligar: passa SENTRY_DSN via --dart-define ou dart_define.json. Vazio
// (default em dev/staging) vira no-op silencioso — nada sobe pra Sentry,
// nenhum overhead, nenhum erro de runtime.
//
// O que NUNCA pode ir pro Sentry:
//   - email do usuário, senha, JWT, refresh_token
//   - URL completa do Supabase (revela o subdomínio do projeto)
//   - chave Anthropic ou qualquer Authorization header
//   - dados financeiros do usuário (litros/preço/total)
//
// O que VAI:
//   - stack traces
//   - tipo da exceção + mensagem (após scrubbing)
//   - tela atual (route name)
//   - versão do app / plataforma / SDK

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// DSN injetado via --dart-define. Vazio = Sentry desligado.
const _kSentryDsn = String.fromEnvironment('SENTRY_DSN');

/// Roda [appRunner] dentro do escopo do Sentry quando habilitado.
///
/// Quando `SENTRY_DSN` é vazio, apenas executa `appRunner()` direto — útil
/// pra dev local e pra CI sem precisar bypassar nada.
Future<void> runWithSentry(Future<void> Function() appRunner) async {
  if (_kSentryDsn.isEmpty) {
    await appRunner();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = _kSentryDsn;
      // Sampling de erros = 100% (free tier aguenta 5k/mês; ajustar se
      // explodir). Performance tracing OFF por enquanto — overhead +
      // consome quota de "performance events" separada.
      options.tracesSampleRate = 0.0;
      // PII control: NUNCA envia IP, device-id, etc. Sentry default já é
      // false, mas explícito pra evitar regressão futura.
      options.sendDefaultPii = false;
      // Anexa breadcrumbs de navegação automaticamente. Útil pra ver "o
      // user passou em /vehicles → /vehicles/:id → crash em /fuel/new".
      options.attachStacktrace = true;
      // Ambiente — dev/debug builds são marcados pra não poluir métricas.
      options.environment = kDebugMode ? 'debug' : 'production';
      // Scrubber agressivo aplicado em todo evento antes do upload.
      options.beforeSend = _scrubEvent;
    },
    appRunner: appRunner,
  );
}

/// Remove qualquer pedaço suspeito do payload antes do envio.
///
/// Estratégia: regex sobre o JSON serializado do evento. Caro em CPU? Sim
/// (~ms por erro), mas só roda em crashes — não é hot path. Em troca,
/// elimina vazamento via campos que ainda não conhecemos (ex.: o Supabase
/// SDK adicionar um novo header amanhã).
SentryEvent? _scrubEvent(SentryEvent event, Hint hint) {
  // 1. Mensagem da exceção crua: troca qualquer URL Supabase pelo placeholder.
  final exceptions = event.exceptions
      ?.map((e) => e.copyWith(value: _scrubText(e.value ?? '')))
      .toList();

  // 2. Breadcrumbs: scrub message + data.
  final breadcrumbs = event.breadcrumbs
      ?.map(
        (b) => b.copyWith(
          message: b.message == null ? null : _scrubText(b.message!),
          data: b.data == null ? null : _scrubMap(b.data!),
        ),
      )
      .toList();

  // 3. Contexts: scrub recursivo de qualquer map (mut in place — Contexts é
  // um MapView). Maps em entry.value são opcionais; outros tipos passam.
  for (final entry in event.contexts.entries.toList()) {
    final value = entry.value;
    if (value is Map<String, dynamic>) {
      event.contexts[entry.key] = _scrubMap(value);
    }
  }

  return event.copyWith(
    exceptions: exceptions,
    breadcrumbs: breadcrumbs,
    // Force null no campo user — nunca queremos email/id/IP indo pro Sentry.
    user: null,
  );
}

/// Regex de scrubbing aplicada em qualquer string que vai pro Sentry.
String _scrubText(String input) {
  return input
      // URL Supabase completa: vaza subdomínio + endpoint.
      .replaceAll(
        RegExp(r'https://[a-z0-9]+\.supabase\.co[^\s]*'),
        '[supabase-url]',
      )
      // Bearer tokens / JWT.
      .replaceAll(
        RegExp(
          r'eyJ[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*',
        ),
        '[jwt]',
      )
      // Authorization headers — captura tudo até newline/end pra não
      // deixar o token escapar quando vem como "Authorization: Bearer XXX"
      // (o `\S+` antigo parava no espaço entre Bearer e o token real).
      .replaceAllMapped(
        RegExp(
          r'(authorization|apikey|bearer)\s*[:=]\s*[^\r\n]+',
          caseSensitive: false,
        ),
        (m) => '${m.group(1)}: [redacted]',
      )
      // Email — match básico.
      .replaceAll(
        RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'),
        '[email]',
      );
}

Map<String, dynamic> _scrubMap(Map<String, dynamic> input) {
  final out = <String, dynamic>{};
  for (final entry in input.entries) {
    final key = entry.key.toLowerCase();
    // Chaves sensíveis — apaga valor inteiro, mantém só o nome.
    if (key.contains('password') ||
        key.contains('token') ||
        key.contains('email') ||
        key.contains('apikey') ||
        key.contains('authorization') ||
        key.contains('dsn')) {
      out[entry.key] = '[redacted]';
      continue;
    }
    final v = entry.value;
    if (v is String) {
      out[entry.key] = _scrubText(v);
    } else if (v is Map<String, dynamic>) {
      out[entry.key] = _scrubMap(v);
    } else {
      out[entry.key] = v;
    }
  }
  return out;
}
