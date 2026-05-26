import 'package:autolog/data/repositories/fipe_history_repository.dart';
import 'package:autolog/features/vehicles/widgets/fipe_history_chart.dart';
import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.J — Widget tests para FipeHistoryChart.
/// Spec: docs/specs/sprint-6.J-fipe-history.md

List<FipeSnapshot> _snapshots(int count) {
  return List.generate(count, (i) {
    final month = i + 1;
    return FipeSnapshot(
      month: '2025-${month.toString().padLeft(2, '0')}',
      value: Decimal.fromInt(70000 + i * 500),
    );
  });
}

Widget _buildApp(List<FipeSnapshot> snapshots) {
  return ProviderScope(
    overrides: [
      fipeHistoryProvider('vehicle-1').overrideWith(
        (ref) => Stream.value(snapshots),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: FipeHistoryChart(vehicleId: 'vehicle-1'),
      ),
    ),
  );
}

void main() {
  group('FipeHistoryChart', () {
    testWidgets('0 pontos → renderiza empty state', (tester) async {
      await tester.pumpWidget(_buildApp([]));
      await tester.pumpAndSettle();

      // Empty state mostra ícone show_chart e mensagem de incentivo
      expect(find.byIcon(Icons.show_chart), findsOneWidget);
      expect(
        find.textContaining('Valor FIPE'),
        findsOneWidget,
      );
    });

    testWidgets('1 ponto → renderiza valor único formatado', (tester) async {
      await tester.pumpWidget(_buildApp(_snapshots(1)));
      await tester.pumpAndSettle();

      // Deve encontrar o label "Valor FIPE"
      expect(find.text('Valor FIPE'), findsOneWidget);

      // Deve encontrar "1 ponto coletado em ..."
      expect(find.textContaining('1 ponto coletado em'), findsOneWidget);

      // Não deve ter LineChart com 1 ponto
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('3 pontos → renderiza LineChart', (tester) async {
      await tester.pumpWidget(_buildApp(_snapshots(3)));
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('13+ pontos → renderiza badge YoY com sinal', (tester) async {
      // Cria 13 snapshots com crescimento (último > primeiro)
      final snaps = List.generate(13, (i) {
        final month = i + 1;
        return FipeSnapshot(
          month: '2025-${month.toString().padLeft(2, '0')}',
          // Valor cresce: 70000, 71000, ..., 82000
          value: Decimal.fromInt(70000 + i * 1000),
        );
      });

      await tester.pumpWidget(_buildApp(snaps));
      await tester.pumpAndSettle();

      // Deve ter o LineChart
      expect(find.byType(LineChart), findsOneWidget);

      // Badge YoY deve estar presente com sinal positivo (+) e percentual
      final badgeText = find.textContaining('+');
      expect(badgeText, findsAtLeastNWidgets(1));

      // Cor do badge deve ser success (verde) pra delta positivo
      // Verifica que o widget Container com cor success existe
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasSuccessContainer = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color?.toARGB32() ==
                  const Color(0xFF1F7A4D).toARGB32() ||
              decoration.color?.toARGB32() ==
                  const Color(0xFFE6F2EB).toARGB32();
        }
        return false;
      });
      expect(hasSuccessContainer, isTrue);
    });

    testWidgets('13+ pontos com queda → badge YoY negativo (vermelho)',
        (tester) async {
      // Snapshots com queda: último < 12 meses atrás
      final snaps = List.generate(13, (i) {
        final month = i + 1;
        return FipeSnapshot(
          month: '2025-${month.toString().padLeft(2, '0')}',
          // Valor cai: 82000, 81000, ..., 70000
          value: Decimal.fromInt(82000 - i * 1000),
        );
      });

      await tester.pumpWidget(_buildApp(snaps));
      await tester.pumpAndSettle();

      // Badge YoY deve estar presente com percentual negativo (contém %)
      // Busca pelo sinal no badge: o texto termina em %
      final allTexts = tester.widgetList<Text>(find.byType(Text));
      final hasBadgeWithPercent = allTexts.any(
        (t) => (t.data ?? '').endsWith('%') && (t.data ?? '').startsWith('-'),
      );
      expect(hasBadgeWithPercent, isTrue);

      // Cor do badge deve ser danger (vermelho) pra delta negativo
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasDangerContainer = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color?.toARGB32() ==
                  const Color(0xFFB23A2F).toARGB32() ||
              decoration.color?.toARGB32() ==
                  const Color(0xFFF6E1DD).toARGB32();
        }
        return false;
      });
      expect(hasDangerContainer, isTrue);
    });
  });
}
