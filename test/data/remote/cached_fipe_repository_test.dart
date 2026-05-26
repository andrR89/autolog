import 'package:autolog/data/local/fipe_cache.dart';
import 'package:autolog/data/remote/cached_fipe_repository.dart';
import 'package:autolog/data/remote/fipe_models.dart';
import 'package:autolog/data/remote/fipe_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.I — CachedFipeRepository (decorator com TTL 7d e fallback stale).
/// Spec: docs/specs/sprint-6.I-fipe-autocomplete.md

class _FakeFipe implements FipeRepository {
  _FakeFipe({this.throwOnCall = false});
  bool throwOnCall;
  int brandsCalls = 0;
  int detailsCalls = 0;
  List<FipeBrand> brands = const [FipeBrand(code: '23', name: 'Honda')];
  FipeVehicleDetails details = FipeVehicleDetails(
    brand: 'Honda',
    model: 'Civic',
    modelYear: 2018,
    fipeCode: '001-2',
    fuel: 'Flex',
    priceValue: Decimal.parse('78420.00'),
    referenceMonth: '2026-05',
  );

  @override
  Future<List<FipeBrand>> listBrands(VehicleType type) async {
    brandsCalls++;
    if (throwOnCall) throw FipeException('fake fipe down');
    return brands;
  }

  @override
  Future<List<FipeModel>> listModels(VehicleType type, String brandCode) async {
    if (throwOnCall) throw FipeException('fake');
    return const [];
  }

  @override
  Future<List<FipeYear>> listYears(
      VehicleType type, String brandCode, String modelCode) async {
    if (throwOnCall) throw FipeException('fake');
    return const [];
  }

  @override
  Future<FipeVehicleDetails> getDetails(VehicleType type, String brandCode,
      String modelCode, String yearCode) async {
    detailsCalls++;
    if (throwOnCall) throw FipeException('fake');
    return details;
  }
}

class _InMemoryStore implements FipeCacheStore {
  final Map<String, FipeCacheRow> _map = {};

  @override
  Future<FipeCacheRow?> read(String key) async => _map[key];

  @override
  Future<void> write(String key, String value, DateTime expiresAt) async {
    _map[key] = FipeCacheRow(key: key, value: value, expiresAt: expiresAt);
  }
}

void main() {
  late DateTime fakeNow;
  DateTime now() => fakeNow;

  setUp(() {
    fakeNow = DateTime.utc(2026, 5, 26, 10);
  });

  test('1ª chamada vai pro delegate e cacheia; 2ª serve do cache', () async {
    final delegate = _FakeFipe();
    final cache = _InMemoryStore();
    final repo = CachedFipeRepository(delegate, cache, now: now);

    final r1 = await repo.listBrands(VehicleType.carro);
    expect(r1.single.name, 'Honda');
    expect(delegate.brandsCalls, 1);

    final r2 = await repo.listBrands(VehicleType.carro);
    expect(r2.single.name, 'Honda');
    expect(delegate.brandsCalls, 1, reason: 'cache hit, delegate não chamado');
  });

  test('TTL 7d: passado o prazo, chama delegate de novo', () async {
    final delegate = _FakeFipe();
    final cache = _InMemoryStore();
    final repo = CachedFipeRepository(delegate, cache, now: now);

    await repo.listBrands(VehicleType.carro);
    expect(delegate.brandsCalls, 1);

    fakeNow = fakeNow.add(const Duration(days: 7, minutes: 1));
    await repo.listBrands(VehicleType.carro);
    expect(delegate.brandsCalls, 2);
  });

  test('delegate falha + cache válido → serve cache', () async {
    final delegate = _FakeFipe();
    final cache = _InMemoryStore();
    final repo = CachedFipeRepository(delegate, cache, now: now);

    await repo.listBrands(VehicleType.carro);
    expect(delegate.brandsCalls, 1);

    delegate.throwOnCall = true;
    fakeNow = fakeNow.add(const Duration(days: 8)); // expirado, força nova fetch
    final r = await repo.listBrands(VehicleType.carro);
    expect(r.single.name, 'Honda', reason: 'serve stale fallback');
  });

  test('delegate falha + cache vazio → propaga FipeException', () async {
    final delegate = _FakeFipe(throwOnCall: true);
    final cache = _InMemoryStore();
    final repo = CachedFipeRepository(delegate, cache, now: now);

    expect(repo.listBrands(VehicleType.carro),
        throwsA(isA<FipeException>()));
  });

  test('cacheia getDetails separadamente por (brand, model, year)', () async {
    final delegate = _FakeFipe();
    final cache = _InMemoryStore();
    final repo = CachedFipeRepository(delegate, cache, now: now);

    await repo.getDetails(VehicleType.carro, '23', '5585', '2018-1');
    await repo.getDetails(VehicleType.carro, '23', '5585', '2018-1');
    expect(delegate.detailsCalls, 1);

    await repo.getDetails(VehicleType.carro, '23', '5585', '2017-1');
    expect(delegate.detailsCalls, 2);
  });
}
