import 'dart:async';
import 'dart:convert';

import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/local/fipe_cache.dart';
import 'package:autolog/data/remote/cached_fipe_repository.dart';
import 'package:autolog/data/remote/fipe_models.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Contrato / Exceção
// ---------------------------------------------------------------------------

abstract class FipeRepository {
  Future<List<FipeBrand>> listBrands(VehicleType type);
  Future<List<FipeModel>> listModels(VehicleType type, String brandCode);
  Future<List<FipeYear>> listYears(
    VehicleType type,
    String brandCode,
    String modelCode,
  );
  Future<FipeVehicleDetails> getDetails(
    VehicleType type,
    String brandCode,
    String modelCode,
    String yearCode,
  );
}

class FipeException implements Exception {
  FipeException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'FipeException: $message';
}

// ---------------------------------------------------------------------------
// HttpFipeRepository
// ---------------------------------------------------------------------------

class HttpFipeRepository implements FipeRepository {
  HttpFipeRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _base = 'https://parallelum.com.br/fipe/api/v2';

  String _path(VehicleType t) =>
      t == VehicleType.moto ? 'motorcycles' : 'cars';

  Future<dynamic> _get(String path) async {
    final uri = Uri.parse('$_base$path');
    try {
      final r = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) {
        throw FipeException(
          'Resposta inesperada (${r.statusCode}) da FIPE',
        );
      }
      return jsonDecode(r.body);
    } on TimeoutException {
      throw FipeException('Timeout consultando FIPE');
    } on FipeException {
      rethrow;
    } catch (e) {
      throw FipeException('Erro de rede ao consultar FIPE', cause: e);
    }
  }

  @override
  Future<List<FipeBrand>> listBrands(VehicleType type) async {
    final raw = await _get('/${_path(type)}/brands') as List;
    return raw
        .cast<Map<String, dynamic>>()
        .map(FipeBrand.fromJson)
        .toList();
  }

  @override
  Future<List<FipeModel>> listModels(
    VehicleType type,
    String brandCode,
  ) async {
    final raw =
        await _get('/${_path(type)}/brands/$brandCode/models') as List;
    return raw
        .cast<Map<String, dynamic>>()
        .map(FipeModel.fromJson)
        .toList();
  }

  @override
  Future<List<FipeYear>> listYears(
    VehicleType type,
    String brandCode,
    String modelCode,
  ) async {
    final raw = await _get(
      '/${_path(type)}/brands/$brandCode/models/$modelCode/years',
    ) as List;
    return raw
        .cast<Map<String, dynamic>>()
        .map(FipeYear.fromJson)
        .toList();
  }

  @override
  Future<FipeVehicleDetails> getDetails(
    VehicleType type,
    String brandCode,
    String modelCode,
    String yearCode,
  ) async {
    final raw = await _get(
      '/${_path(type)}/brands/$brandCode/models/$modelCode/years/$yearCode',
    ) as Map<String, dynamic>;
    return FipeVehicleDetails.fromJson(raw);
  }
}

// ---------------------------------------------------------------------------
// Providers Riverpod
// ---------------------------------------------------------------------------

final httpClientProvider = Provider<http.Client>((ref) {
  final c = http.Client();
  ref.onDispose(c.close);
  return c;
});

final fipeCacheStoreProvider = Provider<FipeCacheStore>((ref) {
  return DriftFipeCacheStore(ref.watch(appDatabaseProvider));
});

final fipeRepositoryProvider = Provider<FipeRepository>((ref) {
  final httpRepo = HttpFipeRepository(
    client: ref.watch(httpClientProvider),
  );
  final cache = ref.watch(fipeCacheStoreProvider);
  return CachedFipeRepository(httpRepo, cache);
});
