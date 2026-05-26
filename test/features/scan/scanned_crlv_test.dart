import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/features/scan/scanned_crlv.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.K — parse defensivo do ScannedCrlv.
/// Spec: docs/specs/sprint-6.K-scan-crlv.md
void main() {
  group('ScannedCrlv.fromJson', () {
    test('JSON completo com todos os campos', () {
      final r = ScannedCrlv.fromJson(<String, dynamic>{
        'plate': 'ABC1D23',
        'renavam': '12345678901',
        'chassi': '9BWZZZ377VT004251',
        'color': 'preto',
        'fuel_type': 'flex',
        'make': 'Honda',
        'model': 'CIVIC LX 1.7',
        'year': 2018,
      });
      expect(r.plate, 'ABC1D23');
      expect(r.renavam, '12345678901');
      expect(r.chassi, '9BWZZZ377VT004251');
      expect(r.color, 'preto');
      expect(r.fuelType, FuelType.flex);
      expect(r.make, 'Honda');
      expect(r.model, 'CIVIC LX 1.7');
      expect(r.year, 2018);
    });

    test('todos os campos null → modelo todo null', () {
      final r = ScannedCrlv.fromJson(<String, dynamic>{
        'plate': null, 'renavam': null, 'chassi': null,
        'color': null, 'fuel_type': null,
        'make': null, 'model': null, 'year': null,
      });
      expect(r.plate, isNull);
      expect(r.renavam, isNull);
      expect(r.chassi, isNull);
      expect(r.fuelType, isNull);
      expect(r.year, isNull);
    });

    test('JSON vazio → modelo todo null', () {
      final r = ScannedCrlv.fromJson(<String, dynamic>{});
      expect(r.plate, isNull);
      expect(r.make, isNull);
    });

    test('chaves extras ignoradas', () {
      final r = ScannedCrlv.fromJson(<String, dynamic>{
        'plate': 'ABC1234',
        'foo': 'bar',
        'random_field': 42,
      });
      expect(r.plate, 'ABC1234');
    });

    test('fuel_type desconhecido → null (defensivo)', () {
      final r = ScannedCrlv.fromJson({'fuel_type': 'kerosene'});
      expect(r.fuelType, isNull);
    });

    test('fuel_type conhecido — todos os 5 valores', () {
      for (final f in FuelType.values) {
        final r = ScannedCrlv.fromJson({'fuel_type': f.wire});
        expect(r.fuelType, f, reason: 'fuel ${f.wire}');
      }
    });

    test('year como inteiro', () {
      final r = ScannedCrlv.fromJson({'year': 2018});
      expect(r.year, 2018);
    });
  });

  group('ScannedCrlv roundtrip JSON', () {
    test('toJson → fromJson preserva campos', () {
      const original = ScannedCrlv(
        plate: 'ABC1D23',
        renavam: '00012345678',
        chassi: '9BWZZZ377VT004251',
        color: 'preto',
        fuelType: FuelType.flex,
        make: 'Honda',
        model: 'CIVIC',
        year: 2018,
      );
      final back = ScannedCrlv.fromJson(original.toJson());
      expect(back, original);
    });
  });
}
