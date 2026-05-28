# Google Calendar Setup — AutoLog

Guia passo-a-passo para ativar a integração real com o Google Calendar.
Por padrão, o app usa `MockGoogleCalendarService` — nenhum OAuth é necessário.
Quando quiser ligar a integração real, siga os passos abaixo.

---

## Pré-requisitos

- Conta Google Cloud Console com acesso ao projeto do AutoLog.
- Acesso ao arquivo `ios/Runner/Info.plist`.
- SHA1 do keystore de debug Android (veja abaixo).

---

## 1. Google Cloud Console — criar projeto e ativar API

1. Acesse [console.cloud.google.com](https://console.cloud.google.com).
2. Crie um projeto (ou use o existente do AutoLog).
3. No menu lateral: **APIs e Serviços → Biblioteca**.
4. Pesquise **Google Calendar API** e clique em **Ativar**.

---

## 2. OAuth Consent Screen

1. **APIs e Serviços → Tela de consentimento OAuth**.
2. Tipo de usuário: **Externo** (ou Interno se for workspace privado).
3. Preencha: nome do app (`AutoLog`), e-mail de suporte, logo (opcional).
4. **Escopos**: adicione `https://www.googleapis.com/auth/calendar.events`.
   - Esse escopo restringe o acesso APENAS a eventos criados pelo app.
5. Usuários de teste: adicione o e-mail que vai testar.
6. Salve e continue.

---

## 3. Criar OAuth Client IDs

### iOS

1. **APIs e Serviços → Credenciais → Criar credencial → ID do cliente OAuth**.
2. Tipo de aplicativo: **iOS**.
3. Bundle ID: `com.autolog.app` (ou o bundle ID do seu `Info.plist`).
4. Clique em **Criar**.
5. Anote o **Client ID** e o **REVERSED_CLIENT_ID** (formato `com.googleusercontent.apps.XXXX`).

### Android

1. Repita o processo acima, tipo: **Android**.
2. Package name: `com.autolog.app` (ou o do `AndroidManifest.xml`).
3. SHA1 do debug keystore:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore \
     -alias androiddebugkey -storepass android -keypass android \
     | grep SHA1
   ```
4. Cole o SHA1 e clique em **Criar**.

---

## 4. iOS — configurar Info.plist

Abra `ios/Runner/Info.plist` e adicione dentro de `<dict>`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>REVERSED_CLIENT_ID_AQUI</string>
    </array>
  </dict>
</array>
```

Substitua `REVERSED_CLIENT_ID_AQUI` pelo valor do passo 3 iOS
(ex: `com.googleusercontent.apps.1234567890-abcdef`).

---

## 5. Android — nenhuma configuração extra de arquivo

O google_sign_in v7 no Android usa o SHA1 + package name registrado no
Google Cloud. Não é necessário adicionar `google-services.json` para apenas
Calendar OAuth — mas se o projeto já usa Firebase, mantenha o arquivo.

---

## 6. Ativar o serviço real no app

Em `lib/features/calendar/google_calendar_service.dart`, no final do arquivo,
troque o provider de Mock para Real (1 linha):

```dart
// ANTES (mock padrão):
final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  return MockGoogleCalendarService();
});

// DEPOIS (real — só ativar após configurar OAuth):
final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  return RealGoogleCalendarService(
    ref.watch(calendarEventLinkRepositoryProvider),
  );
});
```

---

## 7. Ligar o bridge nos forms de reminder

Quando o OAuth estiver ativo, ligue `ReminderCalendarBridge` nos pontos de
save/delete do reminder. Em `lib/features/reminders/` (no saver ou na tela
de criação/edição):

```dart
// Após salvar o reminder:
final bridge = ref.read(reminderCalendarBridgeProvider);
bridge.syncReminder(savedReminder); // fire-and-forget

// Após soft-deletar o reminder:
bridge.unsyncReminder(reminderId);  // fire-and-forget
```

O bridge é silencioso — se o Calendar não estiver conectado, é no-op.

---

## 8. Custos e quotas

A **Google Calendar API é gratuita** para uso típico:

| Operação | Quota |
|----------|-------|
| Leitura (não usada neste app) | 1.000.000 req/dia |
| Escrita (insert/update/delete) | 10.000 req/dia por usuário |

AutoLog faz 1 write por reminder criado/editado. Para uso normal (dezenas de
reminders por mês por usuário), o custo é zero.

---

## 9. Testes com Mock

Para testar a UX de conectado/desconectado sem configurar OAuth:

1. Mantenha `MockGoogleCalendarService` no provider (padrão).
2. Em Settings → Google Calendar, o botão "Conectar" toggle o mock.
3. `upsertCallCount` e `deleteCallCount` ficam disponíveis no serviço para
   inspecionar em testes.

---

## Troubleshooting

| Problema | Causa provável | Solução |
|----------|---------------|---------|
| `PlatformException: sign_in_failed` | REVERSED_CLIENT_ID errado no Info.plist | Confira o valor copiado do Cloud Console |
| `ApiException: 10` | SHA1 não registrado | Registre o SHA1 no client OAuth Android |
| `error: access_denied` | Escopo não adicionado no consent screen | Adicione `calendar.events` e republique |
| App crasha no `initialize()` | `google-services.json` ausente | Não necessário; verifique se GoogleSignIn está correto |
