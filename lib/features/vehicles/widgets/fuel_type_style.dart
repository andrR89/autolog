// Mapeia FuelType -> apresentação visual (cor de acento + label PT-BR).
//
// A "personalidade por combustível" é uma das marcas visuais da tela de
// veículos: cada carro ganha uma faixa lateral colorida pelo tipo de
// combustível, com um chip semente da mesma cor. Centralizar essa
// associação aqui evita drift entre widgets (lista, detalhe, formulário
// poderão reusar).

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:flutter/material.dart';

/// Aparência canônica de um [FuelType] para uso em UI.
class FuelTypeStyle {
  const FuelTypeStyle({required this.color, required this.label});

  /// Cor sólida — usada na faixa lateral, ponto do chip e ícone.
  final Color color;

  /// Label PT-BR já capitalizado para exibição direta ("Gasolina", "GNV").
  final String label;

  /// Versão suave (12% alpha) para fundos de chip.
  Color get soft => color.withValues(alpha: 0.12);

  static FuelTypeStyle of(FuelType type) {
    switch (type) {
      case FuelType.gasolina:
        return const FuelTypeStyle(
          color: AppColors.fuelGasoline,
          label: 'Gasolina',
        );
      case FuelType.etanol:
        return const FuelTypeStyle(
          color: AppColors.fuelEthanol,
          label: 'Etanol',
        );
      case FuelType.diesel:
        return const FuelTypeStyle(
          color: AppColors.fuelDiesel,
          label: 'Diesel',
        );
      case FuelType.flex:
        return const FuelTypeStyle(color: AppColors.fuelFlex, label: 'Flex');
      case FuelType.gnv:
        // GNV não tem token dedicado (só 4 cores definidas no DS); usa
        // info como cor neutra-azulada, consistente com "gás natural".
        return const FuelTypeStyle(color: AppColors.info, label: 'GNV');
    }
  }
}
