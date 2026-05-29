// Testes unitários de FuelFilterState.
//
// Cobre: hasActiveFilters, activeCount, defaults.

import 'package:autolog/features/fuel/filters/fuel_filter_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FuelFilterState — defaults', () {
    test('estado inicial não tem filtros ativos', () {
      final state = FuelFilterState();
      expect(state.hasActiveFilters, isFalse);
      expect(state.activeCount, 0);
    });

    test('sortBy default é dateDesc', () {
      expect(FuelFilterState().sortBy, FuelSortBy.dateDesc);
    });

    test('onlyFullTank default é false', () {
      expect(FuelFilterState().onlyFullTank, isFalse);
    });
  });

  group('FuelFilterState — hasActiveFilters', () {
    test('fuelType não-null → ativo', () {
      final s = FuelFilterState(fuelType: 'gasolina');
      expect(s.hasActiveFilters, isTrue);
    });

    test('stationQuery vazia → não ativo', () {
      final s = FuelFilterState(stationQuery: '');
      expect(s.hasActiveFilters, isFalse);
    });

    test('stationQuery não-vazia → ativo', () {
      final s = FuelFilterState(stationQuery: 'Shell');
      expect(s.hasActiveFilters, isTrue);
    });

    test('period não-null → ativo', () {
      final now = DateTime.now();
      final s = FuelFilterState(
        period: DateTimeRange(start: now, end: now),
      );
      expect(s.hasActiveFilters, isTrue);
    });

    test('textQuery não-vazia → ativo', () {
      final s = FuelFilterState(textQuery: 'etanol');
      expect(s.hasActiveFilters, isTrue);
    });

    test('textQuery vazia → não ativo', () {
      final s = FuelFilterState(textQuery: '');
      expect(s.hasActiveFilters, isFalse);
    });

    test('sortBy ≠ dateDesc → ativo', () {
      final s = FuelFilterState(sortBy: FuelSortBy.totalDesc);
      expect(s.hasActiveFilters, isTrue);
    });

    test('onlyFullTank true → ativo', () {
      final s = FuelFilterState(onlyFullTank: true);
      expect(s.hasActiveFilters, isTrue);
    });
  });

  group('FuelFilterState — activeCount', () {
    test('sem filtros → 0', () {
      expect(FuelFilterState().activeCount, 0);
    });

    test('um filtro → 1', () {
      expect(FuelFilterState(fuelType: 'diesel').activeCount, 1);
    });

    test('dois filtros → 2', () {
      final s = FuelFilterState(fuelType: 'etanol', onlyFullTank: true);
      expect(s.activeCount, 2);
    });

    test('todos os filtros → 6', () {
      final now = DateTime.now();
      final s = FuelFilterState(
        fuelType: 'gasolina',
        stationQuery: 'Ipiranga',
        period: DateTimeRange(start: now, end: now),
        textQuery: 'cheio',
        sortBy: FuelSortBy.litersAsc,
        onlyFullTank: true,
      );
      expect(s.activeCount, 6);
    });

    test('stationQuery vazia não conta', () {
      final s = FuelFilterState(stationQuery: '', fuelType: 'gnv');
      expect(s.activeCount, 1);
    });

    test('textQuery vazia não conta', () {
      final s = FuelFilterState(textQuery: '', onlyFullTank: true);
      expect(s.activeCount, 1);
    });
  });

  group('FuelSortBy — labels', () {
    test('todos os valores têm label não-vazia', () {
      for (final v in FuelSortBy.values) {
        expect(v.label, isNotEmpty, reason: 'label vazia para $v');
      }
    });
  });
}
