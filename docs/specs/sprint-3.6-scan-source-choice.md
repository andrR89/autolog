# Spec — Sprint 3.6: Escolha de fonte no scan (câmera ou galeria)

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> Depende de 3.3 (form) + 3.5 (states).
> **Motivação**: simulador iOS não tem câmera real, e usuário real pode querer escanear cupom recebido por WhatsApp/foto antiga (caso de uso legítimo). Não é gambiarra — é UX completa.

## Escopo
- `ScanController.scanFromCamera()` é renomeado pra `scan({ImageOrigin origin = ImageOrigin.camera})`.
- Form: ao tocar no botão de scan, abre um `showModalBottomSheet` PT-BR com 2 opções:
  - **Tirar foto** (câmera) → `scan(origin: ImageOrigin.camera)`.
  - **Escolher da galeria** → `scan(origin: ImageOrigin.gallery)`.
- O sheet pode ser dispensado (tap fora / botão "Cancelar") sem disparar nada.

Fora de escopo: outras mudanças no fluxo de scan; rewarded ad; ML Kit.

## Decisões técnicas

### 1. Rename + parametrização do controller
`lib/features/scan/scan_controller.dart`:
- Renomear `scanFromCamera()` → `scan({ImageOrigin origin = ImageOrigin.camera})`.
- Default `camera` preserva compatibilidade semântica das chamadas sem param.
- Internamente: `imageSource.obtainReceiptImage(origin: origin)` — passa adiante.

### 2. Bottom sheet no form
`lib/features/fuel/fuel_entry_form_screen.dart`:
- Tap no icon button de scan → `showModalBottomSheet(...)` com:
  - `ListTile(leading: Icon(Icons.photo_camera), title: Text('Tirar foto'), onTap: ...)` → `Navigator.pop(context); _runScan(ImageOrigin.camera);`
  - `ListTile(leading: Icon(Icons.photo_library), title: Text('Escolher da galeria'), onTap: ...)` → `Navigator.pop(context); _runScan(ImageOrigin.gallery);`
  - `ListTile(leading: Icon(Icons.close), title: Text('Cancelar'), onTap: () => Navigator.pop(context));`
- `_runScan(ImageOrigin origin)` chama `ref.read(scanControllerProvider.notifier).scan(origin: origin)` (lógica de prefill/banner igual à atual).

### 3. Atualizar testes existentes (mínima edição)
Os testes do 3.3 e 3.5 chamam `scanFromCamera()` — atualizar pra `scan()` (com default camera; semântica idêntica). Sem perda de cobertura.

## Critérios de aceite

**Atualizar `test/features/scan/scan_controller_test.dart` e `scan_controller_quota_test.dart`**: trocar `.scanFromCamera()` por `.scan()` em todas as chamadas. Mesmas asserções; mesmo comportamento.

**Novo teste em `test/features/scan/scan_source_choice_test.dart`**:
1. `scan(origin: ImageOrigin.gallery)` → o `FakeImageSource` recebe `origin: gallery` (verificável via `lastOrigin`).
2. `scan(origin: ImageOrigin.camera)` → `lastOrigin == camera`.
3. `scan()` sem param → `lastOrigin == camera` (default).

**Deliverable (Haiku + homologação visual)**:
4. Tap no scanner abre bottom sheet PT-BR com 3 itens (câmera, galeria, cancelar).
5. Escolher cada um aciona o caminho certo; cancelar não dispara nada.

## Definition of Done
- 3 testes novos verdes; testes atualizados verdes; suíte completa verde; `dart format`; `flutter analyze` limpo.
- `flutter build ios --simulator --debug --dart-define-from-file=dart_define.json` passa.
- "Escolher da galeria" testável no simulador iOS (sem câmera real necessária).
