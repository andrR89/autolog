# Spec — Sprint 3.0: Abstração `ImageSource`

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> Fonte: `docs/ARCHITECTURE.md §4` (Captura de imagem — abstração por plataforma) + Regras de Ouro #10 (captura abstraída por plataforma).
> **Primeiro tijolo do Sprint 3.** Garante que o pipeline de IA não conheça câmera nem upload — só recebe bytes.

## Escopo
- Interface `ImageSource` que devolve `Uint8List` (a imagem) sem saber a origem.
- Implementação **mobile** (`MobileImageSource`) usando `image_picker` (câmera + galeria).
- Implementação `FakeImageSource` para testes (devolve bytes pré-configurados).
- Provider Riverpod que injeta a impl da plataforma corrente. Web fica como `UnimplementedError` (Sprint 8 substitui).

Fora de escopo: compressão/redimensionamento (3.2), upload, edge function, UI de scan.

## Decisões técnicas

### 1. Interface mínima (uma única responsabilidade)
`lib/platform/image_source.dart` substitui o stub `// TODO: implement`:
```dart
import 'dart:typed_data';

/// Origem da captura — câmera ou galeria.
enum ImageOrigin { camera, gallery }

/// Fonte de imagem agnóstica de plataforma.
/// Retorna `null` se o usuário cancelar.
/// Lança [ImageSourceException] em erro real (permissão negada, hardware indisponível).
abstract class ImageSource {
  Future<Uint8List?> obtainReceiptImage({ImageOrigin origin = ImageOrigin.camera});
}

class ImageSourceException implements Exception {
  ImageSourceException(this.message, {this.cause});
  final String message;
  final Object? cause;
  @override
  String toString() => 'ImageSourceException: $message';
}
```

### 2. Impl mobile (`image_picker` 1.x — já no pubspec)
`lib/platform/image_source_mobile.dart` — `class MobileImageSource implements ImageSource`. Usa `package:image_picker`'s `ImagePicker().pickImage(source: ...)`, lê os bytes via `XFile.readAsBytes()`, devolve `Uint8List?`. Mapeia `PlatformException` em `ImageSourceException`. Cancelamento (`pickImage` retornando null) é cancelamento normal → devolve `null` (NÃO lança).

### 3. Impl web placeholder
`lib/platform/image_source_web.dart` — `class WebImageSource implements ImageSource` que apenas **lança `UnimplementedError('Web image source vem na Sprint 8')`**. Marca claramente que o pipeline já está abstraído pra receber a impl web depois sem retrabalho.

### 4. Provider que escolhe a impl
`lib/platform/image_source.dart` expõe `imageSourceProvider` (Riverpod `Provider<ImageSource>`):
- Em mobile (Android/iOS): retorna `MobileImageSource()`.
- Em web: retorna `WebImageSource()`.
- Detecção: `defaultTargetPlatform` + `kIsWeb` (de `package:flutter/foundation.dart`).

### 5. Fake pra testes (público, reutilizável em features downstream)
`lib/platform/image_source.dart` exporta também `class FakeImageSource implements ImageSource`:
- Construtor `FakeImageSource({Uint8List? bytes, bool throwOnCall = false, bool returnNullOnCall = false})`.
- Captura o último `origin` passado (`ImageOrigin? lastOrigin`) e contador de chamadas (`int callCount`).
- Devolve `bytes` quando configurado; `null` se `returnNullOnCall`; lança `ImageSourceException('fake error')` se `throwOnCall`.
- Pertence a `lib/` (não a `test/`) pra outros features (scan, etc.) overrideram o provider em testes sem duplicar fake.

## Critérios de aceite (= testes em `test/platform/image_source_test.dart`)

`ImageSource` (interface contract via `FakeImageSource`):
1. `FakeImageSource` com `bytes` configurado retorna os bytes no chamado.
2. `FakeImageSource` sem config → retorna `null` (default).
3. `FakeImageSource(returnNullOnCall: true)` retorna `null`.
4. `FakeImageSource(throwOnCall: true)` lança `ImageSourceException`.
5. `lastOrigin` captura o `origin` passado (`camera` default; testar `gallery` explícito).
6. `callCount` incrementa por chamada.

`ImageSourceException`:
7. `toString()` inclui o `message`.
8. Construtor aceita `cause` opcional.

## Definition of Done
- Testes acima verdes (~10 asserts); suíte completa verde (~149); `dart format`; `flutter analyze` limpo.
- `flutter build ios --simulator --debug --dart-define-from-file=dart_define.json` passa.
- `MobileImageSource` revisado por Haiku (não unit-testado — usa plugin).
- `WebImageSource` lança `UnimplementedError` (revisado).
- Sem chave/secret em código.
