# Spec — Sprint 3.2: Captura de foto + compressão/redimensionamento

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> Depende de 3.0 (`ImageSource` + `MobileImageSource`).
> **Objetivo**: garantir que a imagem que vai pro Edge Function (3.1) é pequena o bastante pra **não estourar token nem upload lento** — sem adicionar dependência nova.

## Escopo
- Configurar `MobileImageSource` com parâmetros nativos do `image_picker` (`maxWidth`, `imageQuality`) — compressão acontece on-device durante a captura.
- Service `ImagePreprocessor` puro, testável: valida o tamanho final em bytes antes de subir, lança erro tipado se exceder o limite (defensivo; cenário raro depois da compressão nativa).
- **Nenhuma dependência nova.**

Fora de escopo:
- Compressão programática extra (pacote `image`) — desnecessária com `image_picker` nativo. Deixar pra depois SE virar gargalo real.
- Upload (3.3 / 3.1).

## Decisões técnicas

### 1. Parâmetros nativos de compressão no `MobileImageSource`
Em `lib/platform/image_source_mobile.dart`:
```dart
final xfile = await picker.ImagePicker().pickImage(
  source: ...,
  maxWidth: 1600,    // redimensiona a maior dimensão
  imageQuality: 85,  // JPEG quality (0-100)
);
```
Defaults explícitos no construtor, override permitido pra futuro tuning:
```dart
class MobileImageSource implements ImageSource {
  const MobileImageSource({this.maxWidth = 1600, this.imageQuality = 85});
  final double maxWidth;
  final int imageQuality;
  // ...
}
```
Esses defaults dão JPEGs de ~150-300 KB a partir de fotos de 12 MP — alvo confortável pra Claude Haiku 4.5 sem desperdiçar token.

### 2. `ImagePreprocessor` defensivo (testável)
`lib/features/scan/image_preprocessor.dart`:
```dart
/// Verifica se a imagem está pronta para upload.
/// Não modifica os bytes — a compressão real acontece on-device via image_picker.
class ImagePreprocessor {
  const ImagePreprocessor({this.maxBytes = 1500000}); // 1,5 MB
  final int maxBytes;

  /// Retorna os bytes se estiverem dentro do limite.
  /// Lança [ImageTooLargeException] se exceder.
  Uint8List prepareForUpload(Uint8List input);
}

class ImageTooLargeException implements Exception {
  ImageTooLargeException({required this.actualBytes, required this.maxBytes});
  final int actualBytes;
  final int maxBytes;
  @override
  String toString() =>
      'ImageTooLargeException: imagem com $actualBytes bytes excede o limite '
      'de $maxBytes bytes';
}
```
Provider Riverpod `imagePreprocessorProvider` retornando uma instância default.

> Por que não comprimir programaticamente aqui? Porque `image_picker` já comprime nativamente com qualidade muito melhor (codecs nativos). Reprocessar em Dart puro seria mais lento e pior qualidade. Esse service é uma **rede de segurança defensiva**: se por algum motivo a imagem chegou grande demais (ex.: web na fase 8 sem compressão nativa), barra antes de gastar tokens.

### 3. Provider
`imagePreprocessorProvider = Provider<ImagePreprocessor>((_) => const ImagePreprocessor());`

## Critérios de aceite (= testes em `test/features/scan/image_preprocessor_test.dart`)

`ImagePreprocessor`:
1. Bytes dentro do limite → retorna os mesmos bytes (referência ou cópia equivalente; testa igualdade de conteúdo).
2. Bytes no limite exato (`length == maxBytes`) → retorna ok.
3. Bytes acima do limite → lança `ImageTooLargeException` com `actualBytes`/`maxBytes` corretos.
4. Limite custom no construtor é respeitado.

`ImageTooLargeException`:
5. `toString()` inclui ambos os valores.

## Definition of Done
- Testes acima verdes (5 asserts); suíte completa verde; `dart format`; `flutter analyze` limpo.
- `flutter build ios --simulator --debug --dart-define-from-file=dart_define.json` passa.
- `MobileImageSource` agora passa `maxWidth=1600, imageQuality=85` pro `image_picker` (revisado por Haiku — não unit-testado, é plugin).
- **Sem nova dependência** no `pubspec.yaml`.
