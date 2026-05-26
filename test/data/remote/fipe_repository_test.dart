import 'dart:convert';

import 'package:autolog/data/remote/fipe_models.dart';
import 'package:autolog/data/remote/fipe_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Sprint 6.I — HttpFipeRepository.
/// Spec: docs/specs/sprint-6.I-fipe-autocomplete.md

void main() {
  group('HttpFipeRepository.listBrands', () {
    test('carro chama /cars/brands e deserializa', () async {
      Uri? called;
      final client = MockClient((req) async {
        called = req.url;
        return http.Response(
          jsonEncode([
            {'code': '1', 'name': 'Acura'},
            {'code': '21', 'name': 'Fiat'},
            {'code': '23', 'name': 'Honda'},
          ]),
          200,
        );
      });
      final repo = HttpFipeRepository(client: client);

      final brands = await repo.listBrands(VehicleType.carro);

      expect(called.toString(),
          'https://parallelum.com.br/fipe/api/v2/cars/brands');
      expect(brands.length, 3);
      expect(brands[2], const FipeBrand(code: '23', name: 'Honda'));
    });

    test('moto chama /motorcycles/brands', () async {
      Uri? called;
      final client = MockClient((req) async {
        called = req.url;
        return http.Response(jsonEncode(<dynamic>[]), 200);
      });
      final repo = HttpFipeRepository(client: client);

      await repo.listBrands(VehicleType.moto);
      expect(called!.path.contains('/motorcycles/brands'), isTrue);
    });
  });

  group('HttpFipeRepository.listModels', () {
    test('chama /cars/brands/{code}/models', () async {
      Uri? called;
      final client = MockClient((req) async {
        called = req.url;
        return http.Response(
          jsonEncode([
            {'code': '5585', 'name': 'CIVIC LX 1.7'},
          ]),
          200,
        );
      });
      final repo = HttpFipeRepository(client: client);

      final models = await repo.listModels(VehicleType.carro, '23');

      expect(called.toString(),
          'https://parallelum.com.br/fipe/api/v2/cars/brands/23/models');
      expect(models.single.code, '5585');
    });
  });

  group('HttpFipeRepository.listYears', () {
    test('chama /years e deserializa', () async {
      final client = MockClient((req) async => http.Response(
            jsonEncode([
              {'code': '2018-1', 'name': '2018 Gasolina'},
              {'code': '2017-1', 'name': '2017 Gasolina'},
            ]),
            200,
          ));
      final repo = HttpFipeRepository(client: client);

      final years = await repo.listYears(VehicleType.carro, '23', '5585');
      expect(years.first.code, '2018-1');
    });
  });

  group('HttpFipeRepository.getDetails', () {
    test(r'parseia priceValue de string formatada "R$ X.XXX,XX"', () async {
      final client = MockClient((req) async => http.Response(
            jsonEncode({
              'brand': 'Honda',
              'model': 'CIVIC LX 1.7',
              'modelYear': 2018,
              'fipeCode': '026003-6',
              'fuel': 'Gasolina',
              'price': r'R$ 78.420,00',
              'referenceMonth': 'janeiro de 2026',
            }),
            200,
          ));
      final repo = HttpFipeRepository(client: client);

      final d = await repo.getDetails(VehicleType.carro, '23', '5585', '2018-1');
      expect(d.brand, 'Honda');
      expect(d.model, 'CIVIC LX 1.7');
      expect(d.modelYear, 2018);
      expect(d.fipeCode, '026003-6');
      expect(d.priceValue, Decimal.parse('78420.00'));
    });

    // Regressão 26/05/2026 (homologação): API parallelum retorna alguns
    // veículos com fipeCode/fuel/referenceMonth = null e o `as String`
    // do _$FromJson gerado crashava o app.
    test('campos String null da API → parse defensivo sem crash', () async {
      final client = MockClient((req) async => http.Response(
            jsonEncode({
              'brand': 'Honda',
              'model': 'Civic',
              'modelYear': 2018,
              'fipeCode': null,
              'fuel': null,
              'price': r'R$ 78.420,00',
              'referenceMonth': null,
            }),
            200,
          ));
      final repo = HttpFipeRepository(client: client);
      // Não deve lançar.
      final d = await repo.getDetails(VehicleType.carro, '23', '5585', '2018-1');
      expect(d.brand, 'Honda');
      expect(d.model, 'Civic');
      expect(d.fipeCode, ''); // fallback empty pra String required
      expect(d.fuel, '');
      expect(d.referenceMonth, ''); // fallback empty quando não dá pra normalizar
    });

    test('brand/model ausentes → fallback "—" sem crash', () async {
      final client = MockClient((req) async => http.Response(
            jsonEncode({
              'modelYear': 2020,
              'price': 50000,
            }),
            200,
          ));
      final repo = HttpFipeRepository(client: client);
      final d = await repo.getDetails(VehicleType.carro, '1', '2', '3');
      expect(d.brand, '—');
      expect(d.model, '—');
    });

    test('modelYear ausente/inválido → 0 sem crash', () async {
      final client = MockClient((req) async => http.Response(
            jsonEncode({
              'brand': 'X', 'model': 'Y',
              'price': 100,
              'fipeCode': '001-2',
              'fuel': 'Flex',
              'referenceMonth': 'janeiro de 2026',
            }),
            200,
          ));
      final repo = HttpFipeRepository(client: client);
      final d = await repo.getDetails(VehicleType.carro, '1', '2', '3');
      expect(d.modelYear, 0);
    });

    test('parseia priceValue de número', () async {
      final client = MockClient((req) async => http.Response(
            jsonEncode({
              'brand': 'Honda',
              'model': 'X',
              'modelYear': 2020,
              'fipeCode': '001-2',
              'fuel': 'Flex',
              'price': 99999.5,
              'referenceMonth': 'janeiro de 2026',
            }),
            200,
          ));
      final repo = HttpFipeRepository(client: client);

      final d = await repo.getDetails(VehicleType.carro, '1', '2', '3');
      expect(d.priceValue, Decimal.parse('99999.5'));
    });

    test('normaliza referenceMonth pt-BR pra YYYY-MM', () async {
      final client = MockClient((req) async => http.Response(
            jsonEncode({
              'brand': 'X',
              'model': 'Y',
              'modelYear': 2020,
              'fipeCode': '001-2',
              'fuel': 'Gasolina',
              'price': 100,
              'referenceMonth': 'janeiro de 2026',
            }),
            200,
          ));
      final repo = HttpFipeRepository(client: client);
      final d = await repo.getDetails(VehicleType.carro, '1', '2', '3');
      expect(d.referenceMonth, '2026-01');
    });
  });

  group('HttpFipeRepository erros', () {
    test('500 → FipeException com mensagem PT-BR', () async {
      final client = MockClient((req) async => http.Response('boom', 500));
      final repo = HttpFipeRepository(client: client);
      expect(
        repo.listBrands(VehicleType.carro),
        throwsA(isA<FipeException>().having(
            (e) => e.message, 'message', contains('500'))),
      );
    });

    test('erro de rede genérico → FipeException envolvendo causa', () async {
      final client = MockClient((req) async => throw StateError('socket'));
      final repo = HttpFipeRepository(client: client);
      expect(repo.listBrands(VehicleType.carro), throwsA(isA<FipeException>()));
    });
  });
}
