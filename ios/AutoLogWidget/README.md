# AutoLogWidget — Configuração Manual no Xcode

> **IMPORTANTE:** O build do app **NÃO quebra** sem este target configurado.
> O pacote `home_widget` tolera ausência de Widget Extension — as chamadas
> `HomeWidget.saveWidgetData` e `HomeWidget.updateWidget` simplesmente falham
> silenciosamente no app sem o target registrado.
>
> Siga os passos abaixo quando quiser ativar o widget de verdade no dispositivo/TestFlight.

---

## Pré-requisito

Abra o workspace (não o `.xcodeproj`):

```
open ios/Runner.xcworkspace
```

---

## Passo 1 — Criar o Widget Extension Target

1. No Xcode, menu **File → New → Target…**
2. Selecione a categoria **Application Extension**
3. Escolha **Widget Extension**
4. Clique em **Next**

**Configurações do target:**

| Campo | Valor |
|---|---|
| Product Name | `AutoLogWidget` |
| Team | (sua Apple Team) |
| Organization Identifier | `com.oddcar` |
| Bundle Identifier | `com.oddcar.autolog.AutoLogWidget` |
| Language | Swift |
| Include Configuration Intent | **Desmarcado** (widget estático) |

5. Clique em **Finish**
6. Quando perguntar *"Activate AutoLogWidget scheme?"*, clique **Activate**

---

## Passo 2 — Configurar App Group (compartilhar UserDefaults)

O Dart escreve dados via `HomeWidget.saveWidgetData` usando o App Group Id
`group.com.oddcar.autolog`. O Swift lê os mesmos dados com
`UserDefaults(suiteName: "group.com.oddcar.autolog")`.

### 2a — App Group no target **Runner** (o app principal)

1. Selecione o projeto no navigator (raiz da árvore)
2. Selecione o target **Runner**
3. Aba **Signing & Capabilities**
4. Clique em **+ Capability** (botão `+` no canto superior esquerdo da aba)
5. Adicione **App Groups**
6. Clique em **+** dentro do painel App Groups e adicione:
   ```
   group.com.oddcar.autolog
   ```

### 2b — App Group no target **AutoLogWidget**

Repita os mesmos passos acima com o target **AutoLogWidget** selecionado.
O mesmo group id `group.com.oddcar.autolog` deve aparecer marcado nos dois targets.

---

## Passo 3 — Substituir o código Swift do widget

Abra o arquivo `AutoLogWidget/AutoLogWidget.swift` (criado automaticamente pelo
Xcode com código placeholder) e **substitua todo o conteúdo** pelo código abaixo:

```swift
import WidgetKit
import SwiftUI

struct AutoLogEntry: TimelineEntry {
  let date: Date
  let headline: String
  let sub: String
}

struct AutoLogProvider: TimelineProvider {
  func placeholder(in context: Context) -> AutoLogEntry {
    AutoLogEntry(date: Date(), headline: "AutoLog", sub: "Carregando…")
  }

  func getSnapshot(in context: Context, completion: @escaping (AutoLogEntry) -> ()) {
    let defaults = UserDefaults(suiteName: "group.com.oddcar.autolog")
    let headline = defaults?.string(forKey: "headline") ?? "AutoLog"
    let sub = defaults?.string(forKey: "sub") ?? ""
    completion(AutoLogEntry(date: Date(), headline: headline, sub: sub))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<AutoLogEntry>) -> ()) {
    getSnapshot(in: context) { entry in
      completion(Timeline(entries: [entry], policy: .atEnd))
    }
  }
}

struct AutoLogWidgetView: View {
  var entry: AutoLogEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(entry.headline)
        .font(.system(size: 14, weight: .semibold))
        .lineLimit(2)
      Text(entry.sub)
        .font(.system(size: 12))
        .foregroundColor(.secondary)
    }
    .padding()
  }
}

@main
struct AutoLogWidget: Widget {
  let kind: String = "AutoLogWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: AutoLogProvider()) { entry in
      AutoLogWidgetView(entry: entry)
    }
    .configurationDisplayName("AutoLog")
    .description("Próximo lembrete do seu veículo.")
    .supportedFamilies([.systemSmall])
  }
}
```

---

## Passo 4 — Verificar entitlements gerados

Após configurar os App Groups via UI, o Xcode cria automaticamente:

- `ios/Runner/Runner.entitlements` — com a chave `com.apple.security.application-groups`
- `ios/AutoLogWidget/AutoLogWidget.entitlements` — idem

Confirme que ambos contêm:

```xml
<key>com.apple.security.application-groups</key>
<array>
  <string>group.com.oddcar.autolog</string>
</array>
```

---

## Passo 5 — Inicialização do App Group no Dart (já feito)

O serviço Dart `RealHomeWidgetService` já chama `HomeWidget.setAppGroupId('group.com.oddcar.autolog')`
antes de qualquer `saveWidgetData`. Nenhuma alteração necessária no Dart.

---

## Passo 6 — Build e teste

1. Selecione o scheme **Runner** (não AutoLogWidget)
2. Escolha um **device físico** ou **Simulator iOS 16+**
3. **Product → Run** (⌘R)
4. Abra o app, salve um abastecimento ou lembrete
5. Volte para a tela inicial, adicione o widget "AutoLog" (toque longo → Editar tela inicial → +)
6. Verifique que o headline/sub mostram o próximo lembrete

---

## Diagrama de fluxo de dados

```
Dart (FuelEntrySaver.create)
  → HomeWidgetService.refresh()
    → HomeWidget.setAppGroupId("group.com.oddcar.autolog")
    → HomeWidget.saveWidgetData("headline", "Revisão anual")
    → HomeWidget.saveWidgetData("sub", "15/07")
    → HomeWidget.updateWidget(iOSName: "AutoLogWidget")
        ↓
      WidgetKit agenda reload do timeline
        ↓
      AutoLogProvider.getTimeline()
        → UserDefaults(suiteName: "group.com.oddcar.autolog")
            .string(forKey: "headline") → "Revisão anual"
        → AutoLogWidgetView renderiza
```

---

## Troubleshooting

| Sintoma | Causa provável | Solução |
|---|---|---|
| Widget mostra "AutoLog / Carregando…" sempre | App Group não configurado ou IDs diferentes | Verifique que Runner e AutoLogWidget têm o mesmo group id |
| Build falha com "Provisioning profile doesn't include the com.apple.security.application-groups entitlement" | Provisioning profile desatualizado | Regenere o profile no Apple Developer Portal |
| `HomeWidget.updateWidget` não dispara reload | Widget Extension não instalada | Confirme que o target AutoLogWidget existe e foi compilado |
| Widget não aparece na galeria | Bundle ID errado | Deve ser `com.oddcar.autolog.AutoLogWidget` |
