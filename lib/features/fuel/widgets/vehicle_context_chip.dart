// Pílula horizontal "Para qual veículo?" — o pequeno hero do form.
//
// Por que existe: ao abrir o formulário a partir do FAB global, é fácil
// esquecer pra qual carro o abastecimento está sendo lançado (especialmente
// numa garagem com 2-3 carros). Este chip é um lembrete passivo e elegante,
// não um campo de seleção (a tela de origem já amarrou o vehicle).
//
// Layout (deliberadamente "papel sobre papel" — sem chrome de card):
//
//   ┌──────────────────────────────────────────────────────────┐
//   │  PARA                                                     │  eyebrow
//   │  ▌                                                        │
//   │  ▌ Civic     [ ABC1D23 ]  ● Flex                          │   faixa lateral + dados
//   └──────────────────────────────────────────────────────────┘
//
// A faixa lateral colorida (mesma do VehicleCard) cria continuidade visual
// entre a lista de garagem e este formulário — o usuário "reconhece" o carro
// imediatamente pela cor do combustível.

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/vehicles/widgets/fuel_chip.dart';
import 'package:autolog/features/vehicles/widgets/fuel_type_style.dart';
import 'package:autolog/features/vehicles/widgets/plate_strip.dart';
import 'package:flutter/material.dart';

class VehicleContextChip extends StatelessWidget {
  const VehicleContextChip({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final fuel = FuelTypeStyle.of(vehicle.fuelType);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Eyebrow vertical "PARA" — pequena ousadia tipográfica.
          Text(
            'PARA',
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.inkSoft,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Faixa lateral colorida — herda a "voz" do combustível.
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: fuel.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Nickname em display compacto.
          Flexible(
            child: Text(
              vehicle.nickname,
              style: AppTypography.display(
                17,
                weight: FontWeight.w700,
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          PlateStrip(plate: vehicle.plate),
          const SizedBox(width: AppSpacing.sm),
          FuelChip(fuelType: vehicle.fuelType),
        ],
      ),
    );
  }
}
