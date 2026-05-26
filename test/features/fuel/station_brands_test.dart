import 'package:autolog/features/fuel/station_brands.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.P — testa normalizeStation e brStationBrands.
/// Spec: docs/specs/sprint-6.P-station-price-tracker.md

void main() {
  group('normalizeStation', () {
    test('"Shell " → "shell"', () {
      expect(normalizeStation('Shell '), 'shell');
    });

    test('"Petrobrás" → "petrobras"', () {
      expect(normalizeStation('Petrobrás'), 'petrobras');
    });

    test('"Raízen" → "raizen"', () {
      expect(normalizeStation('Raízen'), 'raizen');
    });

    test('vazio → vazio', () {
      expect(normalizeStation(''), '');
    });

    test('espaços apenas → vazio', () {
      expect(normalizeStation('   '), '');
    });
  });

  group('brStationBrands', () {
    test(
      'contém pelo menos 10 bandeiras incluindo Shell, Petrobras, Ipiranga',
      () {
        expect(brStationBrands.length >= 10, isTrue);
        expect(
          brStationBrands,
          containsAll(['Shell', 'Petrobras', 'Ipiranga']),
        );
      },
    );
  });
}
