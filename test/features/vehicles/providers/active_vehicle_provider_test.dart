// Testes unitários para activeVehicleIdProvider / ActiveVehicleNotifier.
//
// Cobre:
//   1. setActive("abc") persiste em SharedPreferences.
//   2. setActive(null) remove a key.
//   3. Notifier recriado carrega o valor persistido (estado inicial).
//   4. setActive idempotente: chamar com mesmo id duas vezes não quebra.

import 'package:autolog/features/vehicles/providers/active_vehicle_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ActiveVehicleNotifier', () {
    test('1. setActive("abc") persiste a key em SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeVehicleIdProvider.notifier);

      // Aguarda o loadInitial interno.
      await notifier.loadInitial();

      await notifier.setActive('abc');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('active_vehicle_id'), 'abc');
    });

    test('2. setActive(null) remove a key de SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'active_vehicle_id': 'abc'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeVehicleIdProvider.notifier);
      await notifier.loadInitial();

      await notifier.setActive(null);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('active_vehicle_id'), isNull);
      expect(prefs.containsKey('active_vehicle_id'), isFalse);
    });

    test(
      '3. Notifier recriado lê valor inicial de SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({'active_vehicle_id': 'xyz'});

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(activeVehicleIdProvider.notifier);
        await notifier.loadInitial();

        final state = container.read(activeVehicleIdProvider);
        expect(state, 'xyz');
      },
    );

    test(
      '4. setActive idempotente — chamar 2x com mesmo id não quebra',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(activeVehicleIdProvider.notifier);
        await notifier.loadInitial();

        await notifier.setActive('abc');
        // Segunda chamada com mesmo valor — não deve lançar nem corromper.
        await expectLater(notifier.setActive('abc'), completes);

        final state = container.read(activeVehicleIdProvider);
        expect(state, 'abc');
      },
    );
  });
}
