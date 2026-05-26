import 'dart:convert';

import 'package:autolog/data/local/fipe_cache.dart';
import 'package:autolog/data/remote/fipe_models.dart';
import 'package:autolog/data/remote/fipe_repository.dart';
import 'package:autolog/domain/models/enums.dart';

/// Decorator que envolve [FipeRepository] com cache local persistente (Drift).
///
/// TTL: 7 dias. Fallback stale: se o delegate falhar e existe cache (mesmo
/// expirado), serve o stale — offline-first (Regra de Ouro #1).
class CachedFipeRepository implements FipeRepository {
  CachedFipeRepository(
    this._delegate,
    this._cache, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final FipeRepository _delegate;
  final FipeCacheStore _cache;
  final DateTime Function() _now;

  static const _ttl = Duration(days: 7);

  // -------------------------------------------------------------------------
  // Helpers de chave (espelha os paths da API)
  // -------------------------------------------------------------------------

  String _brandsKey(VehicleType t) =>
      t == VehicleType.moto ? '/motorcycles/brands' : '/cars/brands';

  String _modelsKey(VehicleType t, String brand) =>
      t == VehicleType.moto
          ? '/motorcycles/brands/$brand/models'
          : '/cars/brands/$brand/models';

  String _yearsKey(VehicleType t, String brand, String model) =>
      t == VehicleType.moto
          ? '/motorcycles/brands/$brand/models/$model/years'
          : '/cars/brands/$brand/models/$model/years';

  String _detailsKey(VehicleType t, String brand, String model, String year) =>
      t == VehicleType.moto
          ? '/motorcycles/brands/$brand/models/$model/years/$year'
          : '/cars/brands/$brand/models/$model/years/$year';

  // -------------------------------------------------------------------------
  // Cache genérico
  // -------------------------------------------------------------------------

  Future<T> _cached<T>(
    String key,
    Future<T> Function() fetch,
    T Function(dynamic) decode,
    dynamic Function(T) encode,
  ) async {
    final hit = await _cache.read(key);

    // Cache hit válido (não expirado).
    if (hit != null && hit.expiresAt.isAfter(_now())) {
      return decode(jsonDecode(hit.value));
    }

    try {
      final fresh = await fetch();
      await _cache.write(
        key,
        jsonEncode(encode(fresh)),
        _now().add(_ttl),
      );
      return fresh;
    } on FipeException {
      // Fallback stale: mesmo expirado, melhor do que nada.
      if (hit != null) return decode(jsonDecode(hit.value));
      rethrow;
    }
  }

  // -------------------------------------------------------------------------
  // Implementação de FipeRepository
  // -------------------------------------------------------------------------

  @override
  Future<List<FipeBrand>> listBrands(VehicleType type) {
    return _cached<List<FipeBrand>>(
      _brandsKey(type),
      () => _delegate.listBrands(type),
      (raw) => (raw as List)
          .cast<Map<String, dynamic>>()
          .map(FipeBrand.fromJson)
          .toList(),
      (list) => list.map((b) => b.toJson()).toList(),
    );
  }

  @override
  Future<List<FipeModel>> listModels(VehicleType type, String brandCode) {
    return _cached<List<FipeModel>>(
      _modelsKey(type, brandCode),
      () => _delegate.listModels(type, brandCode),
      (raw) => (raw as List)
          .cast<Map<String, dynamic>>()
          .map(FipeModel.fromJson)
          .toList(),
      (list) => list.map((m) => m.toJson()).toList(),
    );
  }

  @override
  Future<List<FipeYear>> listYears(
    VehicleType type,
    String brandCode,
    String modelCode,
  ) {
    return _cached<List<FipeYear>>(
      _yearsKey(type, brandCode, modelCode),
      () => _delegate.listYears(type, brandCode, modelCode),
      (raw) => (raw as List)
          .cast<Map<String, dynamic>>()
          .map(FipeYear.fromJson)
          .toList(),
      (list) => list.map((y) => y.toJson()).toList(),
    );
  }

  @override
  Future<FipeVehicleDetails> getDetails(
    VehicleType type,
    String brandCode,
    String modelCode,
    String yearCode,
  ) {
    return _cached<FipeVehicleDetails>(
      _detailsKey(type, brandCode, modelCode, yearCode),
      () => _delegate.getDetails(type, brandCode, modelCode, yearCode),
      (raw) => FipeVehicleDetails.fromJson(raw as Map<String, dynamic>),
      (d) => d.toJson(),
    );
  }
}
