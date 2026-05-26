# Spec — Sprint 3.5: UX de cota esgotada

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> Depende de 3.1 (`QuotaExhaustedException`) e 3.3 (`ScanController` + form integration).
> **Última tarefa do Sprint 3** (3.4 ML Kit fica adiada).

## Escopo
- Novo state `ScanQuotaExhausted` no `ScanController` — separa cota da família genérica `ScanError`.
- `scanFromCamera` detecta `QuotaExhaustedException` e publica `ScanQuotaExhausted` (não `ScanError`).
- Form mostra `MaterialBanner` específico PT-BR quando cota esgota: mensagem + 2 botões: **"OK"** (dismiss → segue manual) e **"Ver Premium"** (placeholder por enquanto: `SnackBar` "Premium chega no Sprint 6").
- **Manual fallback intacto** (já é a tese do app).

Fora de escopo: paywall/checkout real (Sprint 6); rewarded ad (pós-MVP).

## Decisões técnicas

### 1. Novo state no controller
`lib/features/scan/scan_controller.dart`:
```dart
class ScanQuotaExhausted extends ScanState { const ScanQuotaExhausted(); }
```

### 2. Detecção no `scanFromCamera`
Adicionar catch específico ANTES do catch genérico de `ScanException`:
```dart
} on QuotaExhaustedException {
  state = const ScanQuotaExhausted();
  return null;
} on ScanException catch (_) {
  state = const ScanError('Não foi possível ler o cupom. Tente de novo ou preencha manualmente.');
  return null;
}
```
A ordem importa: `QuotaExhaustedException extends ScanException`, então o catch específico deve vir antes.

### 3. UI no form
Em `FuelEntryFormScreen` (`lib/features/fuel/fuel_entry_form_screen.dart`), no listener do `scanControllerProvider`:
- `ScanQuotaExhausted` → mostra `MaterialBanner` (substitui o existente se houver) com:
  - Texto: **"Sua cota mensal de scans acabou. Continue preenchendo manualmente ou assine Premium."**
  - Ação 1: **"OK"** → dismiss do banner.
  - Ação 2: **"Ver Premium"** → `SnackBar("Premium chega no Sprint 6")`.
- O form continua plenamente usável (fallback manual — não bloqueia campos).

## Critérios de aceite

**Testes em `test/features/scan/scan_controller_quota_test.dart`** (arquivo novo pra não tocar nos 5 testes existentes):

1. **Quota esgotada**: invoker do scan service lança `QuotaExhaustedException` → state final é `ScanQuotaExhausted` (NÃO `ScanError`); `scanFromCamera` retorna `null`.
2. **Outro `ScanException`** (subtipo não-Quota): state final é `ScanError` (não `ScanQuotaExhausted`) — regressão pra garantir que a ordem dos catches não derrubou o caminho genérico.

**Deliverables (Haiku + homologação visual):**
3. Form mostra banner específico PT-BR de cota; botões funcionam; manual segue funcionando.

## Definition of Done
- 2 testes verdes; suíte completa verde; `dart format`; `flutter analyze` limpo.
- `flutter build ios --simulator --debug --dart-define-from-file=dart_define.json` passa.
- Fallback manual sigue intacto.
