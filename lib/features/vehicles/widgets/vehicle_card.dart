// Cartão de identidade de um veículo na "garagem".
//
// Layout (decisões deliberadas):
//
//   ┌─┬────────────────────────────────────────────────────────┐
//   │█│  Civic                                          ⋯       │   nickname (display)
//   │█│  Honda Civic · 2018                                     │   sub  (make/model em inkMuted)
//   │█│                                                          │
//   │█│  [ ABC1D23 ]   ● Flex             45 312 km             │   plate strip · fuel chip · odômetro
//   └─┴────────────────────────────────────────────────────────┘
//
// - A faixa esquerda colorida (█) "marca" o carro pelo combustível —
//   é o detalhe que diferencia esta tela de um ListView genérico.
// - Nickname em Bricolage 22/600 vira hero local: a pessoa identifica
//   o carro "no instinto" antes de ler o restante.
// - Plate em "tira de placa" (PlateStrip) evoca a placa real sem
//   precisar de asset.
// - Odômetro em AppTypography.metric com tabular figures para alinhar
//   visualmente entre cards de carros diferentes.
//
// Interações:
// - Tap → tela de detalhe (callback onTap).
// - Long press → mostra o menu (Editar/Excluir).
// - Trailing "⋯" (mais) → idem.
//
// O card NÃO faz delete sozinho — emite callbacks; a tela que o hospeda
// orquestra Dismissible + Snackbar + saver. Mantém o widget puro.

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/vehicles/vehicle_form_validators.dart';
import 'package:autolog/features/vehicles/widgets/fuel_chip.dart';
import 'package:autolog/features/vehicles/widgets/fuel_type_style.dart';
import 'package:autolog/features/vehicles/widgets/plate_strip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VehicleCard extends StatelessWidget {
  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Vehicle vehicle;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _formatOdometer(int km) {
    // Formata 45312 -> "45 312" (separador "fino" não-quebrável). Não
    // usamos NumberFormat aqui para não puxar intl numa folha tão simples;
    // a regra "milhar com espaço fino" cobre o caso PT-BR sem locale.
    final s = km.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buf.write(' '); // narrow no-break space
      }
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String? _buildFipeLabel() {
    if (vehicle.fipeValue == null) return null;
    final value = vehicle.fipeValue!.toDouble();
    // Valor completo (R$ 78.420) — mais informativo que compactCurrency
    // ("R$79 mil"). Decisão pós-6.I.
    final formatted = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 0,
    ).format(value);

    String? monthLabel;
    if (vehicle.fipeReferenceMonth != null) {
      final parts = vehicle.fipeReferenceMonth!.split('-');
      if (parts.length == 2) {
        final year = parts[0].substring(2); // "26" de "2026"
        final monthNum = int.tryParse(parts[1]);
        const monthAbr = [
          '',
          'jan',
          'fev',
          'mar',
          'abr',
          'mai',
          'jun',
          'jul',
          'ago',
          'set',
          'out',
          'nov',
          'dez',
        ];
        if (monthNum != null && monthNum >= 1 && monthNum <= 12) {
          monthLabel = '${monthAbr[monthNum]}/$year';
        }
      }
    }

    return monthLabel != null
        ? 'FIPE $formatted ($monthLabel)'
        : 'FIPE $formatted';
  }

  String? _buildMakeModelLine() {
    final parts = <String>[
      if (vehicle.make != null && vehicle.make!.trim().isNotEmpty)
        vehicle.make!.trim(),
      if (vehicle.model != null && vehicle.model!.trim().isNotEmpty)
        vehicle.model!.trim(),
      if (vehicle.year != null) vehicle.year.toString(),
    ];
    if (vehicle.engineDisplacementCc != null) {
      parts.add(
        '• ${formatEngineDisplay(vehicle.engineDisplacementCc!, vehicle.type)}',
      );
    }
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  IconData get _vehicleIcon {
    return vehicle.type == VehicleType.moto
        ? Icons.two_wheeler
        : Icons.directions_car;
  }

  void _showActionMenu(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;
    final box = renderObject;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(box.size.topRight(Offset.zero), ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<_VehicleAction>(
      context: context,
      position: position,
      color: context.surfaceRaised,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.allMd,
        side: BorderSide(color: context.hairline),
      ),
      items: [
        PopupMenuItem(
          value: _VehicleAction.edit,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: context.ink),
              const SizedBox(width: AppSpacing.sm),
              const Text('Editar'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: _VehicleAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
              SizedBox(width: AppSpacing.sm),
              Text('Excluir', style: TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == _VehicleAction.edit) onEdit();
      if (value == _VehicleAction.delete) onDelete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fuel = FuelTypeStyle.of(vehicle.fuelType);
    final textTheme = Theme.of(context).textTheme;
    final makeModel = _buildMakeModelLine();
    final fipeLabel = _buildFipeLabel();

    // O card inteiro é um Material+InkWell para ganhar o ripple
    // sem precisar herdar do Card default (que adiciona elevation/tint
    // que o DS quer evitar).
    return Material(
      color: context.surfaceRaised,
      borderRadius: AppRadius.allMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showActionMenu(context),
        // Splash discreto — DS é "flat com hairline", não Material-pesado.
        splashColor: fuel.soft,
        highlightColor: context.surfaceSunken.withValues(alpha: 0.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.allMd,
            border: Border.all(color: context.hairline, width: 1),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Faixa lateral colorida — assinatura visual do card.
                // Largura 6 é suficiente para "marcar" sem competir
                // com o conteúdo.
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: fuel.color,
                    borderRadius: const BorderRadius.only(
                      topLeft: AppRadius.rMd,
                      bottomLeft: AppRadius.rMd,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header: ícone de tipo + nickname + botão "mais".
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.sm,
                                top: 2,
                              ),
                              child: Icon(
                                _vehicleIcon,
                                size: 18,
                                color: context.inkMuted,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                vehicle.nickname,
                                style: AppTypography.display(
                                  22,
                                  weight: FontWeight.w700,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Botão "mais" — visualmente leve, mas
                            // toque generoso (40x40 mínimo).
                            Builder(
                              builder: (innerContext) {
                                return InkResponse(
                                  onTap: () => _showActionMenu(innerContext),
                                  radius: 20,
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.sm,
                                    ),
                                    child: Icon(
                                      Icons.more_horiz,
                                      size: 20,
                                      color: innerContext.inkMuted,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        if (makeModel != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            makeModel,
                            style: textTheme.bodySmall?.copyWith(
                              color: context.inkMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md + 2),
                        // Rodapé: placa | combustível | odômetro.
                        // Wrap pra não estourar em telas pequenas /
                        // nicknames longos.
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            PlateStrip(plate: vehicle.plate),
                            FuelChip(fuelType: vehicle.fuelType),
                            // Odômetro: Bricolage tabular, calmo,
                            // com label "km" em peso 400 (Manrope)
                            // para dar ritmo.
                            Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    _formatOdometer(vehicle.initialOdometer),
                                    style: AppTypography.metric(
                                      15,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'km',
                                    style: textTheme.labelMedium?.copyWith(
                                      color: context.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Chip FIPE — aparece discretamente quando preenchido
                        if (fipeLabel != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.infoSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              fipeLabel,
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.info,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _VehicleAction { edit, delete }
