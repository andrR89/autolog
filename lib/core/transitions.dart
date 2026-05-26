// Transições de rota do AutoLog.
//
// Substitui o default Material/go_router por uma transição slide+fade
// inspirada no CupertinoPageRoute: slide horizontal (entrada da direita,
// saída pela esquerda) com fade suave, 280ms easeOutCubic.
//
// Por que não usar diretamente CupertinoPageTransitionsBuilder no tema:
// - O PageTransitionsTheme aplica a animação mas o go_router não expõe
//   CustomTransitionPage de forma centralizada via esse mecanismo.
// - Usando `pageBuilder` nas rotas com `appTransitionPage()` temos controle
//   total e consistência entre plataformas (sem o "pop" iOS vs. Android).
//
// Uso no router:
//   GoRoute(path: '/foo', pageBuilder: appTransitionPage(FooScreen()))

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'design/tokens.dart';

/// Cria uma [CustomTransitionPage] com o slide+fade padrão do AutoLog.
///
/// `key` deve ser `state.pageKey` para go_router gerenciar corretamente
/// o ciclo de vida das páginas.
CustomTransitionPage<void> buildAppTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: AppMotion.page, // 240ms
    reverseTransitionDuration: AppMotion.page,
    transitionsBuilder: _slideAndFadeTransition,
  );
}

/// Helper que adapta a assinatura do `pageBuilder` do go_router.
///
/// ```dart
/// GoRoute(
///   path: '/foo',
///   pageBuilder: (context, state) => appTransitionPage(
///     state: state,
///     child: const FooScreen(),
///   ),
/// )
/// ```
CustomTransitionPage<void> appTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return buildAppTransitionPage(key: state.pageKey, child: child);
}

/// Transição: slide horizontal (direita→esquerda na ida; esquerda→direita
/// na volta) combinado com um fade suave (1.0→0.0 na saída).
///
/// Resultado: página nova desliza da direita sobre a anterior, que faz
/// um leve fade — próximo ao feel do iOS sem depender do Cupertino runtime.
Widget _slideAndFadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  // Slide da direita para o centro na entrada.
  final slideIn = Tween<Offset>(
    begin: const Offset(0.06, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: animation, curve: AppMotion.standardCurve));

  // Fade acompanha o slide (0→1).
  final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.7, curve: AppMotion.standardCurve),
    ),
  );

  // Página anterior recua levemente para a esquerda ao sair (parallax leve).
  final slideOut =
      Tween<Offset>(begin: Offset.zero, end: const Offset(-0.03, 0)).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: AppMotion.standardCurve,
        ),
      );

  return SlideTransition(
    position: slideOut,
    child: FadeTransition(
      opacity: fadeIn,
      child: SlideTransition(position: slideIn, child: child),
    ),
  );
}
