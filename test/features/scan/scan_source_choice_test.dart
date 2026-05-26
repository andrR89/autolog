import 'dart:typed_data';

import 'package:autolog/features/scan/image_preprocessor.dart';
import 'package:autolog/features/scan/scan_controller.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:autolog/features/scan/scanned_receipt.dart';
import 'package:autolog/platform/image_source.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 3.6 — scan aceita ImageOrigin (câmera ou galeria).
/// Spec: docs/specs/sprint-3.6-scan-source-choice.md
void main() {
  late FakeImageSource fakeImageSource;
  late ImagePreprocessor preprocessor;
  late MockScanService scanService;
  late ProviderContainer container;

  setUp(() {
    fakeImageSource = FakeImageSource(
      bytes: Uint8List.fromList(List.filled(100, 0x42)),
    );
    preprocessor = const ImagePreprocessor(maxBytes: 1000);
    scanService = MockScanService(
      delay: Duration.zero,
      fixedResult: ScannedReceipt(liters: Decimal.parse('40')),
    );
    container = ProviderContainer(
      overrides: [
        imageSourceProvider.overrideWithValue(fakeImageSource),
        imagePreprocessorProvider.overrideWithValue(preprocessor),
        scanServiceProvider.overrideWithValue(scanService),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('scan(origin: gallery) propaga origin pra o ImageSource', () async {
    await container
        .read(scanControllerProvider.notifier)
        .scan(origin: ImageOrigin.gallery);
    expect(fakeImageSource.lastOrigin, ImageOrigin.gallery);
  });

  test('scan(origin: camera) propaga origin pra o ImageSource', () async {
    await container
        .read(scanControllerProvider.notifier)
        .scan(origin: ImageOrigin.camera);
    expect(fakeImageSource.lastOrigin, ImageOrigin.camera);
  });

  test('scan() sem param usa câmera por default', () async {
    await container.read(scanControllerProvider.notifier).scan();
    expect(fakeImageSource.lastOrigin, ImageOrigin.camera);
  });
}
