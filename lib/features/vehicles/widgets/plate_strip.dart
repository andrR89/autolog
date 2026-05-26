// Widget decorativo que renderiza a placa do veículo como uma "tira de
// placa" — um painel off-white com borda hairline, cantos suaves e a placa
// em Bricolage tabular. Não é uma reprodução fiel da placa Mercosul
// (sem brasão), mas evoca essa estética sem custo de assets.
//
// Quando o veículo não tem placa cadastrada, exibe um placeholder discreto
// ("sem placa") em inkSoft, mantendo o mesmo formato para não criar
// "buracos" visuais entre cards.

import 'package:autolog/core/design/tokens.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlateStrip extends StatelessWidget {
  const PlateStrip({super.key, required this.plate});

  /// Placa crua (ex.: "ABC1D23" ou "ABC-1234"). Pode ser nulo/vazio.
  final String? plate;

  @override
  Widget build(BuildContext context) {
    final hasPlate = plate != null && plate!.trim().isNotEmpty;
    final display = hasPlate ? plate!.trim().toUpperCase() : 'sem placa';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        // Fundo off-white quente — destaca dentro do card branco e
        // referencia o papel da placa real.
        color: AppColors.surface,
        borderRadius: AppRadius.allSm,
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: Text(
        display,
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 13,
          fontWeight: hasPlate ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: hasPlate ? 1.4 : 0.2,
          height: 1.0,
          color: hasPlate ? AppColors.ink : AppColors.inkSoft,
          fontFeatures: const [FontFeature.tabularFigures()],
          fontStyle: hasPlate ? FontStyle.normal : FontStyle.italic,
        ),
      ),
    );
  }
}
