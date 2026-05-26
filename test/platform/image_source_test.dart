import 'dart:typed_data';

import 'package:autolog/platform/image_source.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 3.0 — Abstração ImageSource e Fake.
/// Spec: docs/specs/sprint-3.0-image-source.md
void main() {
  group('FakeImageSource', () {
    test('retorna os bytes configurados', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final fake = FakeImageSource(bytes: bytes);
      expect(await fake.obtainReceiptImage(), bytes);
    });

    test('sem configuração retorna null (default)', () async {
      final fake = FakeImageSource();
      expect(await fake.obtainReceiptImage(), isNull);
    });

    test('returnNullOnCall: true retorna null', () async {
      final fake = FakeImageSource(
        bytes: Uint8List.fromList([1]),
        returnNullOnCall: true,
      );
      expect(await fake.obtainReceiptImage(), isNull);
    });

    test('throwOnCall: true lança ImageSourceException', () async {
      final fake = FakeImageSource(throwOnCall: true);
      expect(
        () => fake.obtainReceiptImage(),
        throwsA(isA<ImageSourceException>()),
      );
    });

    test('captura o último origin passado (default = camera)', () async {
      final fake = FakeImageSource();
      await fake.obtainReceiptImage();
      expect(fake.lastOrigin, ImageOrigin.camera);
      await fake.obtainReceiptImage(origin: ImageOrigin.gallery);
      expect(fake.lastOrigin, ImageOrigin.gallery);
    });

    test('callCount incrementa por chamada', () async {
      final fake = FakeImageSource();
      expect(fake.callCount, 0);
      await fake.obtainReceiptImage();
      await fake.obtainReceiptImage();
      expect(fake.callCount, 2);
    });
  });

  group('ImageSourceException', () {
    test('toString inclui o message', () {
      final e = ImageSourceException('algo deu errado');
      expect(e.toString(), contains('algo deu errado'));
    });

    test('aceita cause opcional', () {
      final original = StateError('original');
      final e = ImageSourceException('wrap', cause: original);
      expect(e.cause, original);
      expect(e.message, 'wrap');
    });
  });
}
