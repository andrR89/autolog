import 'dart:typed_data';

import 'package:autolog/features/scan/image_preprocessor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 3.2 — preprocessor defensivo de imagem antes de upload.
/// Spec: docs/specs/sprint-3.2-image-capture-compression.md
void main() {
  group('ImagePreprocessor.prepareForUpload', () {
    test('bytes abaixo do limite retornam iguais', () {
      const p = ImagePreprocessor(maxBytes: 100);
      final input = Uint8List.fromList(List.filled(50, 0x42));
      final result = p.prepareForUpload(input);
      expect(result, input);
    });

    test('bytes no limite exato passam (== maxBytes)', () {
      const p = ImagePreprocessor(maxBytes: 100);
      final input = Uint8List.fromList(List.filled(100, 0x01));
      final result = p.prepareForUpload(input);
      expect(result.length, 100);
    });

    test('bytes acima do limite lançam ImageTooLargeException', () {
      const p = ImagePreprocessor(maxBytes: 100);
      final input = Uint8List.fromList(List.filled(101, 0x02));
      try {
        p.prepareForUpload(input);
        fail('Deveria ter lançado ImageTooLargeException');
      } on ImageTooLargeException catch (e) {
        expect(e.actualBytes, 101);
        expect(e.maxBytes, 100);
      }
    });

    test('limite custom no construtor é respeitado', () {
      const p = ImagePreprocessor(maxBytes: 10);
      expect(
        () => p.prepareForUpload(Uint8List.fromList(List.filled(20, 0))),
        throwsA(isA<ImageTooLargeException>()),
      );
    });
  });

  group('ImageTooLargeException', () {
    test('toString inclui actualBytes e maxBytes', () {
      final e = ImageTooLargeException(actualBytes: 5000, maxBytes: 1000);
      final s = e.toString();
      expect(s, contains('5000'));
      expect(s, contains('1000'));
    });
  });
}
