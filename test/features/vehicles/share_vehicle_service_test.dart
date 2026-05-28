import 'package:autolog/features/scan/edge_function_invoker.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:autolog/features/vehicles/share_vehicle_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.Y — ShareVehicleService

class _FakeInvoker implements EdgeFunctionInvoker {
  _FakeInvoker({this.response, this.throwOnInvoke});

  final Map<String, dynamic>? response;
  final Object? throwOnInvoke;

  String? lastFunctionName;
  Map<String, dynamic>? lastBody;
  int callCount = 0;

  @override
  Future<Map<String, dynamic>> invoke(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    callCount++;
    lastFunctionName = functionName;
    lastBody = body;
    if (throwOnInvoke != null) throw throwOnInvoke!;
    return response ?? <String, dynamic>{};
  }
}

void main() {
  group('RealShareVehicleService.shareWith', () {
    test('invoca "share-vehicle" com vehicle_id e member_email', () async {
      final invoker = _FakeInvoker(response: {
        'ok': true,
        'member_user_id': 'user-abc-123',
      });
      final svc = RealShareVehicleService(invoker);

      final result = await svc.shareWith(
        vehicleId: 'vehicle-1',
        memberEmail: 'pessoa@example.com',
      );

      expect(invoker.lastFunctionName, 'share-vehicle');
      expect(invoker.lastBody!['vehicle_id'], 'vehicle-1');
      expect(invoker.lastBody!['member_email'], 'pessoa@example.com');
      expect(invoker.callCount, 1);
      expect(result, 'user-abc-123');
    });

    test('retorna o member_user_id da resposta', () async {
      const expectedId = 'uuid-de-membro-123';
      final invoker = _FakeInvoker(response: {
        'ok': true,
        'member_user_id': expectedId,
      });
      final svc = RealShareVehicleService(invoker);

      final result = await svc.shareWith(
        vehicleId: 'v1',
        memberEmail: 'x@y.com',
      );

      expect(result, expectedId);
    });

    test('propaga ScanException (404) como ShareEmailNotFoundException', () async {
      final invoker = _FakeInvoker(
        throwOnInvoke: ScanException('Erro ao chamar função (404)'),
      );
      final svc = RealShareVehicleService(invoker);

      expect(
        () => svc.shareWith(vehicleId: 'v1', memberEmail: 'notfound@x.com'),
        throwsA(isA<ShareEmailNotFoundException>()),
      );
    });

    test('ScanException com 404 contém o email correto', () async {
      final invoker = _FakeInvoker(
        throwOnInvoke: ScanException('Erro ao chamar função (404)'),
      );
      final svc = RealShareVehicleService(invoker);

      try {
        await svc.shareWith(vehicleId: 'v1', memberEmail: 'busca@x.com');
        fail('Deveria ter lançado ShareEmailNotFoundException');
      } on ShareEmailNotFoundException catch (e) {
        expect(e.email, 'busca@x.com');
      }
    });

    test('ScanException sem 404 é repropagada como ScanException', () async {
      final invoker = _FakeInvoker(
        throwOnInvoke: ScanException('Erro ao chamar função (500)'),
      );
      final svc = RealShareVehicleService(invoker);

      expect(
        () => svc.shareWith(vehicleId: 'v1', memberEmail: 'x@x.com'),
        throwsA(isA<ScanException>()),
      );
    });

    test('erro genérico wrappado em ScanException', () async {
      final invoker = _FakeInvoker(
        throwOnInvoke: Exception('Erro de rede qualquer'),
      );
      final svc = RealShareVehicleService(invoker);

      expect(
        () => svc.shareWith(vehicleId: 'v1', memberEmail: 'x@x.com'),
        throwsA(isA<ScanException>()),
      );
    });
  });

  group('MockShareVehicleService', () {
    test('retorna fixedMemberUserId por padrão', () async {
      final svc = MockShareVehicleService(
        fixedMemberUserId: 'mock-id-xyz',
        delay: Duration.zero,
      );

      final result = await svc.shareWith(vehicleId: 'v1', memberEmail: 'a@b.com');
      expect(result, 'mock-id-xyz');
      expect(svc.callCount, 1);
      expect(svc.lastVehicleId, 'v1');
      expect(svc.lastMemberEmail, 'a@b.com');
    });

    test('throwEmailNotFound lança ShareEmailNotFoundException', () async {
      final svc = MockShareVehicleService(
        throwEmailNotFound: true,
        delay: Duration.zero,
      );

      expect(
        () => svc.shareWith(vehicleId: 'v1', memberEmail: 'x@x.com'),
        throwsA(isA<ShareEmailNotFoundException>()),
      );
    });

    test('throwGenericError lança ScanException', () async {
      final svc = MockShareVehicleService(
        throwGenericError: true,
        delay: Duration.zero,
      );

      expect(
        () => svc.shareWith(vehicleId: 'v1', memberEmail: 'x@x.com'),
        throwsA(isA<ScanException>()),
      );
    });

    test('callCount incrementa a cada chamada', () async {
      final svc = MockShareVehicleService(delay: Duration.zero);
      await svc.shareWith(vehicleId: 'v1', memberEmail: 'a@a.com');
      await svc.shareWith(vehicleId: 'v1', memberEmail: 'b@b.com');
      expect(svc.callCount, 2);
    });
  });
}
