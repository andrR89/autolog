import 'dart:typed_data';

import 'package:autolog/features/scan/image_preprocessor.dart';
import 'package:autolog/features/scan/scan_controller.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:autolog/features/scan/scanned_receipt.dart';
import 'package:autolog/platform/image_source.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 3.3 — ScanController state transitions.
/// Spec: docs/specs/sprint-3.3-scan-flow.md
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
      fixedResult: ScannedReceipt(
        liters: Decimal.parse('40'),
        pricePerLiter: Decimal.parse('5'),
        totalCost: Decimal.parse('200'),
      ),
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

  test('sucesso: idle → inProgress → success com receipt', () async {
    expect(container.read(scanControllerProvider), isA<ScanIdle>());
    final receipt = await container
        .read(scanControllerProvider.notifier)
        .scan();
    expect(receipt, isNotNull);
    expect(receipt!.liters, Decimal.parse('40'));
    final state = container.read(scanControllerProvider);
    expect(state, isA<ScanSuccess>());
    expect((state as ScanSuccess).receipt, receipt);
  });

  test(
    'cancelado: image source retorna null → state volta a idle, retorna null',
    () async {
      final cancelling = FakeImageSource(returnNullOnCall: true);
      final cancelContainer = ProviderContainer(
        overrides: [
          imageSourceProvider.overrideWithValue(cancelling),
          imagePreprocessorProvider.overrideWithValue(preprocessor),
          scanServiceProvider.overrideWithValue(scanService),
        ],
      );
      addTearDown(cancelContainer.dispose);

      final result = await cancelContainer
          .read(scanControllerProvider.notifier)
          .scan();
      expect(result, isNull);
      expect(cancelContainer.read(scanControllerProvider), isA<ScanIdle>());
      expect(scanService.callCount, 0);
    },
  );

  test('imagem grande demais: state vira error PT-BR, retorna null', () async {
    final big = FakeImageSource(
      bytes: Uint8List.fromList(List.filled(5000, 0x01)),
    );
    final c = ProviderContainer(
      overrides: [
        imageSourceProvider.overrideWithValue(big),
        imagePreprocessorProvider.overrideWithValue(preprocessor),
        scanServiceProvider.overrideWithValue(scanService),
      ],
    );
    addTearDown(c.dispose);

    final result = await c.read(scanControllerProvider.notifier).scan();
    expect(result, isNull);
    final state = c.read(scanControllerProvider);
    expect(state, isA<ScanError>());
    expect((state as ScanError).message, contains('grande demais'));
  });

  test('scan service lança: state vira error PT-BR, retorna null', () async {
    final failing = MockScanService(delay: Duration.zero, throwOnCall: true);
    final c = ProviderContainer(
      overrides: [
        imageSourceProvider.overrideWithValue(fakeImageSource),
        imagePreprocessorProvider.overrideWithValue(preprocessor),
        scanServiceProvider.overrideWithValue(failing),
      ],
    );
    addTearDown(c.dispose);

    final result = await c.read(scanControllerProvider.notifier).scan();
    expect(result, isNull);
    final state = c.read(scanControllerProvider);
    expect(state, isA<ScanError>());
    expect((state as ScanError).message, contains('Não foi possível'));
  });

  test(
    'image source lança erro inesperado: NUNCA propaga, vira state error',
    () async {
      final raising = FakeImageSource(throwOnCall: true);
      final c = ProviderContainer(
        overrides: [
          imageSourceProvider.overrideWithValue(raising),
          imagePreprocessorProvider.overrideWithValue(preprocessor),
          scanServiceProvider.overrideWithValue(scanService),
        ],
      );
      addTearDown(c.dispose);

      final result = await c.read(scanControllerProvider.notifier).scan();
      expect(result, isNull);
      expect(c.read(scanControllerProvider), isA<ScanError>());
    },
  );
}
