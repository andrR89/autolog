// Testes unitários de applyFuelFilter — função pura.
//
// ≥10 casos: tipo, posto substring, período inclusivo, texto, sort estável,
// combinação de filtros, lista vazia.

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/fuel/filters/fuel_filter.dart';
import 'package:autolog/features/fuel/filters/fuel_filter_state.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // -------------------------------------------------------------------------
  // Helper factory
  // -------------------------------------------------------------------------

  FuelEntry entry({
    required String id,
    required DateTime date,
    required FuelType fuelType,
    bool fullTank = true,
    String? stationName,
    String? stationBrand,
    String liters = '40',
    String totalCost = '200',
    int odometer = 10000,
    String vehicleId = 'v1',
  }) {
    return FuelEntry(
      id: id,
      vehicleId: vehicleId,
      date: date,
      odometer: odometer,
      liters: Decimal.parse(liters),
      pricePerLiter: Decimal.parse('5'),
      totalCost: Decimal.parse(totalCost),
      fullTank: fullTank,
      fuelType: fuelType,
      source: FuelSource.manual,
      stationName: stationName,
      stationBrand: stationBrand,
      createdAt: date,
      updatedAt: date,
      syncStatus: SyncStatus.pending,
    );
  }

  // Entradas de referência para os testes
  late FuelEntry eGasolina;
  late FuelEntry eEtanol;
  late FuelEntry eDiesel;
  late FuelEntry eGnv;
  late FuelEntry eShell;
  late FuelEntry eIpiranga;

  setUp(() {
    eGasolina = entry(
      id: 'g1',
      date: DateTime.utc(2026, 5, 10),
      fuelType: FuelType.gasolina,
      stationName: 'Posto Shell Centro',
      stationBrand: 'Shell',
      liters: '50',
      totalCost: '300',
      odometer: 12000,
    );
    eEtanol = entry(
      id: 'e1',
      date: DateTime.utc(2026, 4, 20),
      fuelType: FuelType.etanol,
      stationName: 'Ipiranga Rodovia',
      stationBrand: 'Ipiranga',
      liters: '45',
      totalCost: '180',
      odometer: 11500,
    );
    eDiesel = entry(
      id: 'd1',
      date: DateTime.utc(2026, 3, 5),
      fuelType: FuelType.diesel,
      stationName: 'Posto BR Estrada',
      stationBrand: 'BR',
      liters: '80',
      totalCost: '480',
      odometer: 50000,
      fullTank: false,
    );
    eGnv = entry(
      id: 'gnv1',
      date: DateTime.utc(2026, 2, 14),
      fuelType: FuelType.gnv,
      stationName: 'Gás Natural Ltda',
      liters: '10',
      totalCost: '50',
      odometer: 8000,
    );
    eShell = entry(
      id: 'sh1',
      date: DateTime.utc(2026, 1, 30),
      fuelType: FuelType.gasolina,
      stationName: 'Shell Av Paulista',
      stationBrand: 'Shell',
      liters: '40',
      totalCost: '220',
      odometer: 7000,
    );
    eIpiranga = entry(
      id: 'ip1',
      date: DateTime.utc(2026, 1, 15),
      fuelType: FuelType.gasolina,
      stationName: 'Ipiranga Bairro',
      stationBrand: 'Ipiranga',
      liters: '35',
      totalCost: '190',
      odometer: 6500,
    );
  });

  List<FuelEntry> allEntries() => [
    eGasolina,
    eEtanol,
    eDiesel,
    eGnv,
    eShell,
    eIpiranga,
  ];

  // -------------------------------------------------------------------------
  // Caso 1: lista vazia
  // -------------------------------------------------------------------------

  group('lista vazia', () {
    test('retorna lista vazia sem erros', () {
      final result = applyFuelFilter([], FuelFilterState());
      expect(result, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Caso 2: sem filtros — retorna tudo, ordenado por data desc
  // -------------------------------------------------------------------------

  group('sem filtros', () {
    test('retorna todos os entries em ordem dateDesc', () {
      final result = applyFuelFilter(allEntries(), FuelFilterState());
      expect(result.map((e) => e.id).toList(), [
        'g1',
        'e1',
        'd1',
        'gnv1',
        'sh1',
        'ip1',
      ]);
    });
  });

  // -------------------------------------------------------------------------
  // Caso 3: filtro por tipo de combustível
  // -------------------------------------------------------------------------

  group('filtro fuelType', () {
    test('gasolina → apenas entries gasolina', () {
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(fuelType: 'gasolina'),
      );
      expect(result.every((e) => e.fuelType == FuelType.gasolina), isTrue);
      expect(result.length, 3); // g1, sh1, ip1
    });

    test('etanol → apenas entry etanol', () {
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(fuelType: 'etanol'),
      );
      expect(result, hasLength(1));
      expect(result.first.id, 'e1');
    });

    test('diesel → apenas entry diesel', () {
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(fuelType: 'diesel'),
      );
      expect(result, hasLength(1));
      expect(result.first.id, 'd1');
    });

    test('gnv → apenas entry gnv', () {
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(fuelType: 'gnv'),
      );
      expect(result, hasLength(1));
      expect(result.first.id, 'gnv1');
    });

    test('tipo sem resultado → lista vazia', () {
      final result = applyFuelFilter([
        eGasolina,
      ], FuelFilterState(fuelType: 'etanol'));
      expect(result, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Caso 4: filtro por posto (substring case-insensitive)
  // -------------------------------------------------------------------------

  group('filtro stationQuery', () {
    test('substring "shell" (lowercase) encontra Shell', () {
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(stationQuery: 'shell'),
      );
      expect(result.map((e) => e.id).toList(), containsAll(['g1', 'sh1']));
      expect(result, hasLength(2));
    });

    test('substring "IPIRANGA" (uppercase) encontra Ipiranga', () {
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(stationQuery: 'IPIRANGA'),
      );
      expect(result.map((e) => e.id).toList(), containsAll(['e1', 'ip1']));
      expect(result, hasLength(2));
    });

    test('substring que não existe → lista vazia', () {
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(stationQuery: 'Petrobrás'),
      );
      expect(result, isEmpty);
    });

    test('stationQuery vazia → sem filtro', () {
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(stationQuery: ''),
      );
      expect(result, hasLength(6));
    });

    test('entry sem stationName não é encontrada por substring', () {
      final semPosto = entry(
        id: 'sp1',
        date: DateTime.utc(2026, 5, 1),
        fuelType: FuelType.gasolina,
      );
      final result = applyFuelFilter([
        semPosto,
      ], FuelFilterState(stationQuery: 'Shell'));
      expect(result, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Caso 5: filtro por período (inclusivo em ambos os extremos)
  // -------------------------------------------------------------------------

  group('filtro period', () {
    test('período que contém todos → retorna todos', () {
      final period = DateTimeRange(
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 12, 31),
      );
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(period: period),
      );
      expect(result, hasLength(6));
    });

    test('período de um dia exato captura entry do mesmo dia (inclusivo)', () {
      final period = DateTimeRange(
        start: DateTime.utc(2026, 5, 10),
        end: DateTime.utc(2026, 5, 10),
      );
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(period: period),
      );
      expect(result, hasLength(1));
      expect(result.first.id, 'g1');
    });

    test('período que não contém nenhuma entry → vazio', () {
      final period = DateTimeRange(
        start: DateTime.utc(2025, 1, 1),
        end: DateTime.utc(2025, 12, 31),
      );
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(period: period),
      );
      expect(result, isEmpty);
    });

    test('período de Jan 2026 captura sh1 e ip1', () {
      final period = DateTimeRange(
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 1, 31),
      );
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(period: period),
      );
      expect(result.map((e) => e.id).toList(), containsAll(['sh1', 'ip1']));
      expect(result, hasLength(2));
    });

    test('extremo inicial inclusivo — entry no início do período incluída', () {
      final period = DateTimeRange(
        start: DateTime.utc(2026, 4, 20),
        end: DateTime.utc(2026, 5, 10),
      );
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(period: period),
      );
      // g1 (05/10) e e1 (04/20) — ambas inclusivas
      expect(result.map((e) => e.id).toList(), containsAll(['g1', 'e1']));
      expect(result, hasLength(2));
    });
  });

  // -------------------------------------------------------------------------
  // Caso 6: filtro textQuery (busca livre)
  // -------------------------------------------------------------------------

  group('filtro textQuery', () {
    test('busca "gasolina" retorna apenas entries gasolina', () {
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(textQuery: 'gasolina'),
      );
      expect(result.every((e) => e.fuelType == FuelType.gasolina), isTrue);
    });

    test('busca "CENTRO" (uppercase) encontra stationName com "Centro"', () {
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(textQuery: 'CENTRO'),
      );
      expect(result, hasLength(1));
      expect(result.first.id, 'g1');
    });

    test('busca vazia → sem filtro', () {
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(textQuery: ''),
      );
      expect(result, hasLength(6));
    });
  });

  // -------------------------------------------------------------------------
  // Caso 7: filtro onlyFullTank
  // -------------------------------------------------------------------------

  group('filtro onlyFullTank', () {
    test('true → exclui entries parciais', () {
      // eDiesel é fullTank=false
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(onlyFullTank: true),
      );
      expect(result.every((e) => e.fullTank), isTrue);
      expect(result.any((e) => e.id == 'd1'), isFalse);
    });

    test('false (default) → inclui parciais', () {
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(onlyFullTank: false),
      );
      expect(result, hasLength(6));
    });
  });

  // -------------------------------------------------------------------------
  // Caso 8: ordenação
  // -------------------------------------------------------------------------

  group('ordenação', () {
    test('dateDesc (default) — mais recente primeiro', () {
      final result = applyFuelFilter(allEntries(), FuelFilterState());
      final dates = result.map((e) => e.date).toList();
      for (int i = 0; i < dates.length - 1; i++) {
        expect(
          dates[i].isAfter(dates[i + 1]) || dates[i] == dates[i + 1],
          isTrue,
          reason: 'dateDesc falhou entre índices $i e ${i + 1}',
        );
      }
    });

    test('dateAsc — mais antigo primeiro', () {
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(sortBy: FuelSortBy.dateAsc),
      );
      final dates = result.map((e) => e.date).toList();
      for (int i = 0; i < dates.length - 1; i++) {
        expect(
          dates[i].isBefore(dates[i + 1]) || dates[i] == dates[i + 1],
          isTrue,
        );
      }
    });

    test('totalDesc — maior custo primeiro', () {
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(sortBy: FuelSortBy.totalDesc),
      );
      // eDiesel=480, eGasolina=300, eShell=220, eIpiranga=190, eEtanol=180, eGnv=50
      expect(result.first.id, 'd1');
      expect(result.last.id, 'gnv1');
    });

    test('totalAsc — menor custo primeiro', () {
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(sortBy: FuelSortBy.totalAsc),
      );
      expect(result.first.id, 'gnv1');
      expect(result.last.id, 'd1');
    });

    test('litersDesc — maior volume primeiro', () {
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(sortBy: FuelSortBy.litersDesc),
      );
      // eDiesel=80, eGasolina=50, eEtanol=45, eShell=40, eIpiranga=35, eGnv=10
      expect(result.first.id, 'd1');
      expect(result.last.id, 'gnv1');
    });

    test('litersAsc — menor volume primeiro', () {
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(sortBy: FuelSortBy.litersAsc),
      );
      expect(result.first.id, 'gnv1');
      expect(result.last.id, 'd1');
    });

    test('tiebreaker estável por id quando critério primário empata', () {
      // Dois entries com mesma data → tiebreaker por id lexicográfico asc
      final e1 = entry(
        id: 'aaa',
        date: DateTime.utc(2026, 6, 1),
        fuelType: FuelType.gasolina,
        liters: '40',
        totalCost: '200',
      );
      final e2 = entry(
        id: 'zzz',
        date: DateTime.utc(2026, 6, 1),
        fuelType: FuelType.gasolina,
        liters: '40',
        totalCost: '200',
      );
      final result = applyFuelFilter([e2, e1], FuelFilterState());
      // dateDesc: mesma data, tiebreaker id asc → 'aaa' antes de 'zzz'
      expect(result.first.id, 'aaa');
      expect(result.last.id, 'zzz');
    });
  });

  // -------------------------------------------------------------------------
  // Caso 9: combinação de filtros
  // -------------------------------------------------------------------------

  group('combinação de filtros', () {
    test('fuelType + onlyFullTank exclui diesel parcial', () {
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(fuelType: 'diesel', onlyFullTank: true),
      );
      // d1 é diesel mas não fullTank
      expect(result, isEmpty);
    });

    test('fuelType gasolina + stationQuery Shell → 2 resultados', () {
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(fuelType: 'gasolina', stationQuery: 'Shell'),
      );
      expect(result.map((e) => e.id).toList(), containsAll(['g1', 'sh1']));
      expect(result, hasLength(2));
    });

    test('período + tipo reduz corretamente', () {
      final period = DateTimeRange(
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 5, 31),
      );
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(fuelType: 'gasolina', period: period),
      );
      // g1 (gasolina, 05/10) cabe; e1 (etanol, 04/20) não é gasolina
      expect(result, hasLength(1));
      expect(result.first.id, 'g1');
    });

    test('todos os filtros combinados → resultado preciso', () {
      final period = DateTimeRange(
        start: DateTime.utc(2026, 5, 1),
        end: DateTime.utc(2026, 5, 31),
      );
      final result = applyFuelFilter(
        allEntries(),
        FuelFilterState(
          fuelType: 'gasolina',
          stationQuery: 'shell',
          period: period,
          textQuery: 'centro',
          onlyFullTank: true,
          sortBy: FuelSortBy.litersDesc,
        ),
      );
      // Apenas g1 satisfaz todos: gasolina + Shell + maio/2026 + Centro + fullTank
      expect(result, hasLength(1));
      expect(result.first.id, 'g1');
    });
  });

  // -------------------------------------------------------------------------
  // Caso 10: não muta a lista original
  // -------------------------------------------------------------------------

  group('imutabilidade', () {
    test('lista original não é modificada após filtragem', () {
      final original = allEntries();
      final before = original.map((e) => e.id).toList();
      applyFuelFilter(original, FuelFilterState(fuelType: 'gasolina'));
      final after = original.map((e) => e.id).toList();
      expect(after, equals(before));
    });
  });
}
