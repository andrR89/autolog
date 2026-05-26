# Sprint 6.T — Chat livre com histórico (IA)

> Onda 2, sprint 8/10. Edge function nova + nova tabela local + tela de chat.
> Maior sprint da Onda 2.

## Decisões pragmáticas
- **Sem tool use complexo** no MVP — edge function carrega histórico do veículo (36 meses, igual `analyze-history`) e injeta no prompt como contexto. Mais simples, mais rápido. Tool use vira otimização futura.
- **Conversation history** enviada pelo client (até 5 últimos turns) pra dar contexto à IA. Server não persiste.
- **Persistência local** do chat: nova tabela `chat_messages` (local-only, não sincroniza no MVP).
- **Cota nova `chat_count`**: 10 mensagens/mês free, ilimitado premium.
- Acessível na `InsightsScreen` como 4ª seção: "💬 Pergunte ao histórico".

## Mudanças

### 1. Tabela Drift `ChatMessages` (local-only)
`lib/data/local/tables.dart`:
```dart
@DataClassName('ChatMessageRow')
class ChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get role => text()();           // 'user' | 'assistant'
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

Schema v8 → v9:
```dart
@override
int get schemaVersion => 9;

// onUpgrade:
if (from < 9) {
  await m.createTable(chatMessages);
}
```

Adicionar `ChatMessages` ao `@DriftDatabase`.

### 2. Modelo `ChatMessage` (freezed)
`lib/features/chat/chat_message.dart`:
```dart
enum ChatRole { user, assistant }

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String vehicleId,
    required ChatRole role,
    required String content,
    required DateTime createdAt,
  }) = _ChatMessage;
  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
```

### 3. Repository
`lib/features/chat/chat_message_repository.dart`:
```dart
abstract class ChatMessageRepository {
  Future<void> append(ChatMessage message);
  Future<List<ChatMessage>> listByVehicle(String vehicleId);
  Stream<List<ChatMessage>> watchByVehicle(String vehicleId);
  Future<void> clearVehicle(String vehicleId); // botão "Limpar conversa"
}
```

Provider Riverpod no padrão.

### 4. Service Dart
`lib/features/chat/chat_service.dart`:
```dart
class ChatAnswer {
  const ChatAnswer({required this.content});
  final String content;
}

abstract class ChatService {
  Future<ChatAnswer> ask({
    required String vehicleId,
    required String userMessage,
    required List<ChatMessage> recentHistory, // últimos 5 turns
  });
}

class RealChatService implements ChatService {
  RealChatService(this._invoker);
  final EdgeFunctionInvoker _invoker;
  @override
  Future<ChatAnswer> ask({...}) async {
    try {
      final body = await _invoker.invoke('chat-history', {
        'vehicle_id': vehicleId,
        'user_message': userMessage,
        'recent_history': recentHistory.map((m) => {
          'role': m.role.name, 'content': m.content,
        }).toList(),
      });
      return ChatAnswer(content: body['content'] as String);
    } on QuotaExhaustedException { rethrow; }
    on ScanException { rethrow; }
    catch (e) {
      throw ScanException('Falha ao consultar o assistente', cause: e);
    }
  }
}

class MockChatService implements ChatService {
  // callCount, fixedResult, throwOnCall, delay.
  // default: ChatAnswer(content: 'Você gastou R\$ 1.250 com combustível em 2026.')
}
```

### 5. Edge function `supabase/functions/chat-history/index.ts`
Espelha `analyze-history` com mudanças:
- Body: `{ vehicle_id, user_message, recent_history: [{role,content}] }`.
- Cota nova `chat_count` (limit 10/mês free).
- Carrega vehicle + 36 meses de fuel + 36 meses de expenses + reminders ativos.
- Constrói mensagens pro Haiku:
  - system: "Você é um assistente do AutoLog. Responda em PT-BR baseando-se no histórico do veículo {make/model/year} fornecido abaixo. Seja direto e útil. Se não tiver dado pra responder, diga 'Não tenho dados pra responder isso'.\n\n# Contexto\n{vehicle, stats agregadas, recent fuel entries, recent expenses, reminders}"
  - `recent_history` mapeada pra mensagens user/assistant.
  - última mensagem user com `user_message`.
- Claude `claude-haiku-4-5`, `max_tokens: 800`.
- Response: `{ content: string }`.
- Incrementa `chat_count` em qualquer resposta bem-sucedida (não só "útil") — diferente do analyze.

### 6. UI — Tela de chat
`lib/features/chat/chat_screen.dart`:
- AppBar: "Pergunte ao histórico" + ações ("Limpar conversa" → confirma → `repo.clearVehicle`).
- Body: ListView reversed das mensagens (mais recentes embaixo).
  - User: bubble à direita, fundo brand-soft.
  - Assistant: bubble à esquerda, fundo surfaceRaised.
  - Cada bubble: texto + timestamp pequeno.
- Bottom: TextField + botão enviar (`Icons.send`).
- Estados: enviando (spinner no botão), cota esgotada (banner PT-BR), erro (snackbar).
- Sugestões iniciais (chips) na tela vazia: "Quanto gastei esse mês?", "Quando vence meu IPVA?", "Qual meu posto preferido?", "Meu consumo está piorando?"

Fluxo `_send`:
1. User digita e envia.
2. `repo.append(userMsg)` (otimista).
3. `chatService.ask(vehicleId, userMessage, recentHistory.takeLast(5))`.
4. `repo.append(assistantMsg)`.
5. Erros: `QuotaExhaustedException` → MaterialBanner; outros → snackbar + remove a userMsg otimista da lista? Não — mantém e mostra "Tente de novo" inline.

### 7. Botão na InsightsScreen
Adicionar 4ª seção "ASSISTENTE" com card "💬 Pergunte ao histórico" → navega pra `/vehicles/:id/insights/chat`.

### 8. Rota
`lib/core/router.dart`: `/vehicles/:vehicleId/insights/chat` → `ChatScreen(vehicle)`.

### 9. Migration Supabase
`supabase/migrations/0009_chat_quota.sql`:
```sql
ALTER TABLE public.usage_quota ADD COLUMN IF NOT EXISTS chat_count integer NOT NULL DEFAULT 0;
```

## Testes RED

### `test/features/chat/chat_message_test.dart`
- Parse JSON (vazio, completo, role inválida → erro).
- Roundtrip.

### `test/features/chat/chat_service_test.dart`
- Invoca `chat-history` com `vehicle_id`/`user_message`/`recent_history`.
- Retorna `ChatAnswer` do `body['content']`.
- 429 → QuotaExhaustedException.
- ScanException propaga sem wrap.
- Erro genérico → ScanException contendo "assistente".
- Mock: callCount, fixedResult, throwOnCall.

### `test/features/chat/chat_message_repository_test.dart`
- append insere.
- listByVehicle ordena por createdAt ASC.
- watchByVehicle emite ao append.
- clearVehicle apaga só do veículo informado.

### `test/data/local/chat_schema_v9_test.dart`
- schemaVersion == 9.
- Tabela chat_messages aceita CRUD.
- Migration v8 → v9 cria tabela, preserva existentes.

## Critérios de aceite
- [ ] Todos testes verdes (713+ + ~25 novos)
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Tela de chat funcional com mocks (sem precisar deploy)
- [ ] Persistência local funciona

## Não-objetivos
- Sync da conversa entre devices (futuro).
- Tool use (futuro).
- Streaming token-a-token (futuro).
- Anexos (foto/áudio) na conversa.
