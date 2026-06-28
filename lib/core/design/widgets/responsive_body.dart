// ResponsiveBody — wrapper de telas em coluna única.
//
// Por quê: o design veio só pra mobile. No desktop/tablet, forms e listas
// esticam pra 1500px e ficam toscos. Em vez de refazer cada tela, este
// wrapper centra o conteúdo num limite de largura confortável e mantém o
// background original cobrindo o resto da viewport.
//
// Quando NÃO usar:
// - Hero headers que dependem da largura total (brand cobrindo toda
//   horizontal).
// - AppBars / barras de ação fixas — já são gerenciadas pelo Scaffold.
// - Listas que queremos que virem grid em telas largas (esse é o trabalho
//   da Camada 2, com LayoutBuilder próprio).
//
// Quando usar:
// - Forms (login, signup, vehicle/fuel/expense/reminder form).
// - Listas verticais que ficam ridículas estiradas (settings, paywall).

import 'package:flutter/material.dart';

/// Larguras-alvo. Numericamente afináveis sem mexer nos call sites.
abstract class ResponsiveWidths {
  /// Forms e telas de leitura focada — uma coluna confortável.
  static const double form = 560;

  /// Listas/cards verticais — um pouco mais largo pra acomodar 2 colunas
  /// internas (rótulo + valor, ícone + texto, etc.).
  static const double content = 720;

  /// Sheets modais / paywall hero.
  static const double sheet = 640;
}

class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveWidths.content,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
