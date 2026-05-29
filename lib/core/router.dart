import 'dart:async';

import 'package:autolog/core/transitions.dart';
import 'package:autolog/data/repositories/expense_repository.dart';
import 'package:autolog/data/repositories/fine_repository.dart';
import 'package:autolog/data/repositories/fuel_entry_repository.dart';
import 'package:autolog/data/repositories/insurance_repository.dart';
import 'package:autolog/data/repositories/reminder_repository.dart';
import 'package:autolog/data/repositories/trip_repository.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/features/auth/login_screen.dart';
import 'package:autolog/features/auth/signup_screen.dart';
import 'package:autolog/features/chat/chat_screen.dart';
import 'package:autolog/features/expenses/expense_form_screen.dart';
import 'package:autolog/features/expenses/expenses_list_screen.dart';
import 'package:autolog/features/fuel/fuel_entry_form_screen.dart';
import 'package:autolog/features/fuel/fuel_history_screen.dart';
import 'package:autolog/features/fuel/my_stations_screen.dart';
import 'package:autolog/features/insights/fiscal_plan_screen.dart';
import 'package:autolog/features/insights/insights_screen.dart';
import 'package:autolog/features/insights/maintenance_plan_screen.dart';
import 'package:autolog/features/onboarding/onboarding_screen.dart';
import 'package:autolog/features/personal_documents/cnh_form_screen.dart';
import 'package:autolog/features/personal_documents/fine_form_screen.dart';
import 'package:autolog/features/personal_documents/insurance_form_screen.dart';
import 'package:autolog/features/personal_documents/personal_documents_screen.dart';
import 'package:autolog/features/recap/recap_data.dart';
import 'package:autolog/features/recap/recap_screen.dart';
import 'package:autolog/features/reminders/reminder_form_screen.dart';
import 'package:autolog/features/reminders/reminders_list_screen.dart';
import 'package:autolog/features/reports/compare/period_compare_screen.dart';
import 'package:autolog/features/reports/fuel_economy_screen.dart';
import 'package:autolog/features/reports/reports_screen.dart';
import 'package:autolog/features/settings/settings_screen.dart';
import 'package:autolog/features/trips/trip_detail_screen.dart';
import 'package:autolog/features/trips/trip_form_screen.dart';
import 'package:autolog/features/trips/trips_list_screen.dart';
import 'package:autolog/features/vehicles/share_vehicle_screen.dart';
import 'package:autolog/features/vehicles/vehicle_form_screen.dart';
import 'package:autolog/features/vehicles/vehicles_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// [ChangeNotifier] que escuta o stream de autenticação e notifica o router.
///
/// Quando o estado de auth muda, o go_router dispara um refresh e avalia
/// o redirect novamente.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(Stream<bool> authStateChanges) {
    _subscription = authStateChanges.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<bool> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Rotas da aplicação.
///
/// Todas as rotas usam [appTransitionPage] para garantir a transição
/// slide+fade consistente (ver `lib/core/transitions.dart`).
final List<RouteBase> appRoutes = [
  // Tour de onboarding — exibido uma única vez após login novo (Sprint 6.GG).
  GoRoute(
    path: '/onboarding',
    pageBuilder: (context, state) =>
        appTransitionPage(state: state, child: const OnboardingScreen()),
  ),

  GoRoute(
    path: '/login',
    pageBuilder: (context, state) =>
        appTransitionPage(state: state, child: const LoginScreen()),
  ),
  GoRoute(
    path: '/signup',
    pageBuilder: (context, state) =>
        appTransitionPage(state: state, child: const SignupScreen()),
  ),

  // /home redireciona para /vehicles (Sprint 1.3).
  GoRoute(path: '/home', redirect: (context, state) => '/vehicles'),

  // Lista de veículos.
  GoRoute(
    path: '/vehicles',
    pageBuilder: (context, state) =>
        appTransitionPage(state: state, child: const VehiclesListScreen()),
  ),

  // Formulário de criação.
  GoRoute(
    path: '/vehicles/new',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: const VehicleFormScreen(initial: null),
    ),
  ),

  // Detalhe/histórico de abastecimentos — carrega o veículo pelo id.
  GoRoute(
    path: '/vehicles/:vehicleId',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _VehicleDetailLoader(
        vehicleId: state.pathParameters['vehicleId']!,
      ),
    ),
  ),

  // Formulário de edição — carrega o veículo pelo id.
  GoRoute(
    path: '/vehicles/:id/edit',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _VehicleEditLoader(vehicleId: state.pathParameters['id']!),
    ),
  ),

  // Formulário de novo abastecimento.
  GoRoute(
    path: '/vehicles/:vehicleId/fuel/new',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _FuelNewLoader(vehicleId: state.pathParameters['vehicleId']!),
    ),
  ),

  // Formulário de edição de abastecimento.
  GoRoute(
    path: '/vehicles/:vehicleId/fuel/:entryId/edit',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _FuelEditLoader(
        vehicleId: state.pathParameters['vehicleId']!,
        entryId: state.pathParameters['entryId']!,
      ),
    ),
  ),

  // Lista de despesas do veículo.
  GoRoute(
    path: '/vehicles/:vehicleId/expenses',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _VehicleExpensesLoader(
        vehicleId: state.pathParameters['vehicleId']!,
      ),
    ),
  ),

  // Formulário de nova despesa.
  GoRoute(
    path: '/vehicles/:vehicleId/expenses/new',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _ExpenseNewLoader(vehicleId: state.pathParameters['vehicleId']!),
    ),
  ),

  // Formulário de edição de despesa.
  GoRoute(
    path: '/vehicles/:vehicleId/expenses/:expenseId/edit',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _ExpenseEditLoader(
        vehicleId: state.pathParameters['vehicleId']!,
        expenseId: state.pathParameters['expenseId']!,
      ),
    ),
  ),

  // Tela de relatórios do veículo.
  GoRoute(
    path: '/vehicles/:vehicleId/reports',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _VehicleReportsLoader(
        vehicleId: state.pathParameters['vehicleId']!,
      ),
    ),
  ),

  // Comparar período (mês vs mês anterior, ano vs ano anterior).
  GoRoute(
    path: '/vehicles/:vehicleId/reports/compare',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _VehicleCompareLoader(
        vehicleId: state.pathParameters['vehicleId']!,
      ),
    ),
  ),

  // Calculadora etanol × gasolina — só para veículos flex.
  GoRoute(
    path: '/vehicles/:vehicleId/fuel-economy',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _FuelEconomyLoader(vehicleId: state.pathParameters['vehicleId']!),
    ),
  ),

  // Tela de Insights do veículo.
  GoRoute(
    path: '/vehicles/:vehicleId/insights',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _VehicleInsightsLoader(
        vehicleId: state.pathParameters['vehicleId']!,
      ),
    ),
  ),

  // Tela de Plano de Manutenção Sugerido.
  GoRoute(
    path: '/vehicles/:vehicleId/insights/maintenance',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _VehicleMaintenancePlanLoader(
        vehicleId: state.pathParameters['vehicleId']!,
      ),
    ),
  ),

  // Tela de Lembretes Fiscais (IPVA + Licenciamento).
  GoRoute(
    path: '/vehicles/:vehicleId/insights/fiscal',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _VehicleFiscalPlanLoader(
        vehicleId: state.pathParameters['vehicleId']!,
      ),
    ),
  ),

  // Tela de chat com o assistente IA do histórico.
  GoRoute(
    path: '/vehicles/:vehicleId/insights/chat',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _VehicleChatLoader(vehicleId: state.pathParameters['vehicleId']!),
    ),
  ),

  // ── Documentos pessoais ──────────────────────────────────────────────────

  // Tela principal de documentos.
  GoRoute(
    path: '/personal-documents',
    pageBuilder: (context, state) =>
        appTransitionPage(state: state, child: const PersonalDocumentsScreen()),
  ),

  // Formulário de CNH.
  GoRoute(
    path: '/personal-documents/cnh',
    pageBuilder: (context, state) =>
        appTransitionPage(state: state, child: const CnhFormScreen()),
  ),

  // Formulário de nova multa.
  GoRoute(
    path: '/personal-documents/fines/new',
    pageBuilder: (context, state) =>
        appTransitionPage(state: state, child: const FineFormScreen()),
  ),

  // Formulário de edição de multa (com loader).
  GoRoute(
    path: '/personal-documents/fines/:id',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _FineEditLoader(fineId: state.pathParameters['id']!),
    ),
  ),

  // Formulário de nova apólice.
  GoRoute(
    path: '/personal-documents/insurances/new',
    pageBuilder: (context, state) =>
        appTransitionPage(state: state, child: const InsuranceFormScreen()),
  ),

  // Formulário de edição de apólice (com loader).
  GoRoute(
    path: '/personal-documents/insurances/:id',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _InsuranceEditLoader(insuranceId: state.pathParameters['id']!),
    ),
  ),

  // Tela "Meus postos" — agregação histórica por posto/bandeira.
  GoRoute(
    path: '/stations',
    pageBuilder: (context, state) =>
        appTransitionPage(state: state, child: const MyStationsScreen()),
  ),

  // Recap mensal/semanal — /recap?period=week|month
  GoRoute(
    path: '/recap',
    pageBuilder: (context, state) {
      final period = state.uri.queryParameters['period'] == 'week'
          ? RecapPeriod.week
          : RecapPeriod.month;
      return appTransitionPage(
        state: state,
        child: RecapScreen(period: period),
      );
    },
  ),

  // Tela de configurações.
  GoRoute(
    path: '/settings',
    pageBuilder: (context, state) =>
        appTransitionPage(state: state, child: const SettingsScreen()),
  ),

  // ── Lembretes ─────────────────────────────────────────────────────────────

  // Lista de lembretes do veículo.
  GoRoute(
    path: '/vehicles/:vehicleId/reminders',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _VehicleRemindersLoader(
        vehicleId: state.pathParameters['vehicleId']!,
      ),
    ),
  ),

  // Formulário de novo lembrete.
  GoRoute(
    path: '/vehicles/:vehicleId/reminders/new',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _ReminderNewLoader(vehicleId: state.pathParameters['vehicleId']!),
    ),
  ),

  // Formulário de edição de lembrete.
  GoRoute(
    path: '/vehicles/:vehicleId/reminders/:reminderId/edit',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _ReminderEditLoader(
        vehicleId: state.pathParameters['vehicleId']!,
        reminderId: state.pathParameters['reminderId']!,
      ),
    ),
  ),

  // Tela de compartilhamento de veículo.
  GoRoute(
    path: '/vehicles/:vehicleId/share',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _VehicleShareLoader(vehicleId: state.pathParameters['vehicleId']!),
    ),
  ),

  // ── Viagens ───────────────────────────────────────────────────────────────

  // Lista de viagens do veículo.
  GoRoute(
    path: '/vehicles/:vehicleId/trips',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _VehicleTripsLoader(vehicleId: state.pathParameters['vehicleId']!),
    ),
  ),

  // Formulário de nova viagem.
  GoRoute(
    path: '/vehicles/:vehicleId/trips/new',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _TripNewLoader(vehicleId: state.pathParameters['vehicleId']!),
    ),
  ),

  // Detalhe de viagem.
  GoRoute(
    path: '/vehicles/:vehicleId/trips/:tripId',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _TripDetailLoader(
        vehicleId: state.pathParameters['vehicleId']!,
        tripId: state.pathParameters['tripId']!,
      ),
    ),
  ),

  // Formulário de edição de viagem.
  GoRoute(
    path: '/vehicles/:vehicleId/trips/:tripId/edit',
    pageBuilder: (context, state) => appTransitionPage(
      state: state,
      child: _TripEditLoader(
        vehicleId: state.pathParameters['vehicleId']!,
        tripId: state.pathParameters['tripId']!,
      ),
    ),
  ),
];

/// Widget intermediário que carrega o veículo por id e exibe o histórico.
///
/// Se o veículo não existir (ou já estiver soft-deletado), redireciona para
/// /vehicles em vez de mostrar uma tela sem dados.
class _VehicleDetailLoader extends ConsumerWidget {
  const _VehicleDetailLoader({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoFuture = Future(() async {
      final repo = ref.read(vehicleRepositoryProvider);
      return repo.getById(vehicleId);
    });

    return FutureBuilder(
      future: repoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          // Veículo não encontrado — vai para a lista.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return FuelHistoryScreen(vehicle: snapshot.data!);
      },
    );
  }
}

/// Widget intermediário que carrega o veículo por id antes de exibir o form.
///
/// Se o veículo não existir (ou já estiver soft-deletado), redireciona para
/// /vehicles em vez de mostrar um formulário sem dados.
class _VehicleEditLoader extends ConsumerWidget {
  const _VehicleEditLoader({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoFuture = Future(() async {
      final repo = ref.read(vehicleRepositoryProvider);
      return repo.getById(vehicleId);
    });

    return FutureBuilder(
      future: repoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          // Veículo não encontrado — vai para a lista.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return VehicleFormScreen(initial: snapshot.data);
      },
    );
  }
}

/// Carrega o [Vehicle] e abre o formulário de novo abastecimento.
///
/// Redireciona para /vehicles se o veículo não existir.
class _FuelNewLoader extends ConsumerWidget {
  const _FuelNewLoader({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final repo = ref.read(vehicleRepositoryProvider);
      return repo.getById(vehicleId);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return FuelEntryFormScreen(vehicle: snapshot.data!, initial: null);
      },
    );
  }
}

/// Carrega o [Vehicle] e o [FuelEntry] e abre o formulário de edição de abastecimento.
///
/// - Veículo não encontrado → redireciona para /vehicles.
/// - Entry não encontrada → redireciona para /vehicles/:vehicleId.
class _FuelEditLoader extends ConsumerWidget {
  const _FuelEditLoader({required this.vehicleId, required this.entryId});

  final String vehicleId;
  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final vehicleRepo = ref.read(vehicleRepositoryProvider);
      final fuelRepo = ref.read(fuelEntryRepositoryProvider);
      final vehicle = await vehicleRepo.getById(vehicleId);
      final entry = await fuelRepo.getById(entryId);
      return (vehicle: vehicle, entry: entry);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final vehicle = snapshot.data!.vehicle;
        final entry = snapshot.data!.entry;

        if (vehicle == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (entry == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles/$vehicleId');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return FuelEntryFormScreen(vehicle: vehicle, initial: entry);
      },
    );
  }
}

/// Carrega o [Vehicle] e exibe a lista de despesas.
///
/// Redireciona para /vehicles se o veículo não existir.
class _VehicleExpensesLoader extends ConsumerWidget {
  const _VehicleExpensesLoader({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final repo = ref.read(vehicleRepositoryProvider);
      return repo.getById(vehicleId);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ExpensesListScreen(vehicle: snapshot.data!);
      },
    );
  }
}

/// Carrega o [Vehicle] e abre o formulário de nova despesa.
///
/// Redireciona para /vehicles se o veículo não existir.
class _ExpenseNewLoader extends ConsumerWidget {
  const _ExpenseNewLoader({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final repo = ref.read(vehicleRepositoryProvider);
      return repo.getById(vehicleId);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ExpenseFormScreen(vehicle: snapshot.data!, initial: null);
      },
    );
  }
}

/// Carrega o [Vehicle] e a [Expense] e abre o formulário de edição de despesa.
///
/// - Veículo não encontrado → redireciona para /vehicles.
/// - Despesa não encontrada → redireciona para /vehicles/:vehicleId/expenses.
class _ExpenseEditLoader extends ConsumerWidget {
  const _ExpenseEditLoader({required this.vehicleId, required this.expenseId});

  final String vehicleId;
  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final vehicleRepo = ref.read(vehicleRepositoryProvider);
      final expenseRepo = ref.read(expenseRepositoryProvider);
      final vehicle = await vehicleRepo.getById(vehicleId);
      final expense = await expenseRepo.getById(expenseId);
      return (vehicle: vehicle, expense: expense);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final vehicle = snapshot.data!.vehicle;
        final expense = snapshot.data!.expense;

        if (vehicle == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (expense == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/vehicles/$vehicleId/expenses');
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ExpenseFormScreen(vehicle: vehicle, initial: expense);
      },
    );
  }
}

/// Carrega o [Vehicle] e exibe a lista de lembretes.
///
/// Redireciona para /vehicles se o veículo não existir.
class _VehicleRemindersLoader extends ConsumerWidget {
  const _VehicleRemindersLoader({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final repo = ref.read(vehicleRepositoryProvider);
      return repo.getById(vehicleId);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return RemindersListScreen(vehicle: snapshot.data!);
      },
    );
  }
}

/// Carrega o [Vehicle] e abre o formulário de novo lembrete.
///
/// Redireciona para /vehicles se o veículo não existir.
class _ReminderNewLoader extends ConsumerWidget {
  const _ReminderNewLoader({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final repo = ref.read(vehicleRepositoryProvider);
      return repo.getById(vehicleId);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ReminderFormScreen(vehicle: snapshot.data!, initial: null);
      },
    );
  }
}

/// Carrega o [Vehicle] e o [Reminder] e abre o formulário de edição de lembrete.
///
/// - Veículo não encontrado → redireciona para /vehicles.
/// - Lembrete não encontrado → redireciona para /vehicles/:vehicleId/reminders.
class _ReminderEditLoader extends ConsumerWidget {
  const _ReminderEditLoader({
    required this.vehicleId,
    required this.reminderId,
  });

  final String vehicleId;
  final String reminderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final vehicleRepo = ref.read(vehicleRepositoryProvider);
      final reminderRepo = ref.read(reminderRepositoryProvider);
      final vehicle = await vehicleRepo.getById(vehicleId);
      final reminder = await reminderRepo.getById(reminderId);
      return (vehicle: vehicle, reminder: reminder);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final vehicle = snapshot.data!.vehicle;
        final reminder = snapshot.data!.reminder;

        if (vehicle == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (reminder == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/vehicles/$vehicleId/reminders');
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ReminderFormScreen(vehicle: vehicle, initial: reminder);
      },
    );
  }
}

/// Carrega o [Vehicle] e exibe a tela de insights.
///
/// Redireciona para /vehicles se o veículo não existir.
class _VehicleInsightsLoader extends ConsumerWidget {
  const _VehicleInsightsLoader({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final repo = ref.read(vehicleRepositoryProvider);
      return repo.getById(vehicleId);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return InsightsScreen(vehicle: snapshot.data!);
      },
    );
  }
}

/// Carrega o [Vehicle] e exibe o plano de manutenção sugerido.
///
/// Redireciona para /vehicles se o veículo não existir.
class _VehicleMaintenancePlanLoader extends ConsumerWidget {
  const _VehicleMaintenancePlanLoader({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final repo = ref.read(vehicleRepositoryProvider);
      return repo.getById(vehicleId);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return MaintenancePlanScreen(vehicle: snapshot.data!);
      },
    );
  }
}

/// Carrega o [Vehicle] e exibe a tela de lembretes fiscais.
///
/// Redireciona para /vehicles se o veículo não existir.
class _VehicleFiscalPlanLoader extends ConsumerWidget {
  const _VehicleFiscalPlanLoader({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final repo = ref.read(vehicleRepositoryProvider);
      return repo.getById(vehicleId);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return FiscalPlanScreen(vehicle: snapshot.data!);
      },
    );
  }
}

/// Carrega o [Vehicle] e exibe a tela de relatórios.
///
/// Redireciona para /vehicles se o veículo não existir.
class _VehicleReportsLoader extends ConsumerWidget {
  const _VehicleReportsLoader({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final repo = ref.read(vehicleRepositoryProvider);
      return repo.getById(vehicleId);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ReportsScreen(vehicle: snapshot.data!);
      },
    );
  }
}

/// Carrega o [Vehicle] por id e abre a tela de comparar período.
///
/// Mesma estratégia do `_VehicleReportsLoader`.
class _VehicleCompareLoader extends ConsumerWidget {
  const _VehicleCompareLoader({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final repo = ref.read(vehicleRepositoryProvider);
      return repo.getById(vehicleId);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return PeriodCompareScreen(vehicle: snapshot.data!);
      },
    );
  }
}

/// Carrega a [Fine] por id e abre o formulário de edição.
///
/// Redireciona para /personal-documents se não encontrar.
class _FineEditLoader extends ConsumerWidget {
  const _FineEditLoader({required this.fineId});

  final String fineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final repo = ref.read(fineRepositoryProvider);
      return repo.getById(fineId);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/personal-documents');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return FineFormScreen(initial: snapshot.data);
      },
    );
  }
}

/// Carrega o [Vehicle] e exibe a calculadora etanol × gasolina.
///
/// Redireciona para /vehicles se o veículo não existir.
class _FuelEconomyLoader extends ConsumerWidget {
  const _FuelEconomyLoader({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final repo = ref.read(vehicleRepositoryProvider);
      return repo.getById(vehicleId);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return FuelEconomyScreen(vehicle: snapshot.data!);
      },
    );
  }
}

/// Carrega o [Vehicle] e abre a tela de chat com o assistente IA.
///
/// Redireciona para /vehicles se o veículo não existir.
class _VehicleChatLoader extends ConsumerWidget {
  const _VehicleChatLoader({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final repo = ref.read(vehicleRepositoryProvider);
      return repo.getById(vehicleId);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ChatScreen(vehicle: snapshot.data!);
      },
    );
  }
}

/// Carrega a [Insurance] por id e abre o formulário de edição.
///
/// Redireciona para /personal-documents se não encontrar.
class _InsuranceEditLoader extends ConsumerWidget {
  const _InsuranceEditLoader({required this.insuranceId});

  final String insuranceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final repo = ref.read(insuranceRepositoryProvider);
      return repo.getById(insuranceId);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/personal-documents');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return InsuranceFormScreen(initial: snapshot.data);
      },
    );
  }
}

/// Carrega o [Vehicle] e exibe a lista de viagens.
///
/// Redireciona para /vehicles se o veículo não existir.
class _VehicleTripsLoader extends ConsumerWidget {
  const _VehicleTripsLoader({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final repo = ref.read(vehicleRepositoryProvider);
      return repo.getById(vehicleId);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return TripsListScreen(vehicle: snapshot.data!);
      },
    );
  }
}

/// Carrega o [Vehicle] e abre o formulário de nova viagem.
///
/// Redireciona para /vehicles se o veículo não existir.
class _TripNewLoader extends ConsumerWidget {
  const _TripNewLoader({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final repo = ref.read(vehicleRepositoryProvider);
      return repo.getById(vehicleId);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return TripFormScreen(vehicle: snapshot.data!, initial: null);
      },
    );
  }
}

/// Carrega o [Vehicle] e o [Trip] e exibe o detalhe da viagem.
///
/// - Veículo não encontrado → redireciona para /vehicles.
/// - Viagem não encontrada → redireciona para /vehicles/:vehicleId/trips.
class _TripDetailLoader extends ConsumerWidget {
  const _TripDetailLoader({required this.vehicleId, required this.tripId});

  final String vehicleId;
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final vehicleRepo = ref.read(vehicleRepositoryProvider);
      final tripRepo = ref.read(tripRepositoryProvider);
      final vehicle = await vehicleRepo.getById(vehicleId);
      final trip = await tripRepo.getById(tripId);
      return (vehicle: vehicle, trip: trip);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final vehicle = snapshot.data!.vehicle;
        final trip = snapshot.data!.trip;

        if (vehicle == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (trip == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles/$vehicleId/trips');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return TripDetailScreen(vehicle: vehicle, trip: trip);
      },
    );
  }
}

/// Carrega o [Vehicle] e o [Trip] e abre o formulário de edição de viagem.
///
/// - Veículo não encontrado → redireciona para /vehicles.
/// - Viagem não encontrada → redireciona para /vehicles/:vehicleId/trips.
class _TripEditLoader extends ConsumerWidget {
  const _TripEditLoader({required this.vehicleId, required this.tripId});

  final String vehicleId;
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final vehicleRepo = ref.read(vehicleRepositoryProvider);
      final tripRepo = ref.read(tripRepositoryProvider);
      final vehicle = await vehicleRepo.getById(vehicleId);
      final trip = await tripRepo.getById(tripId);
      return (vehicle: vehicle, trip: trip);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final vehicle = snapshot.data!.vehicle;
        final trip = snapshot.data!.trip;

        if (vehicle == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (trip == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles/$vehicleId/trips');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return TripFormScreen(vehicle: vehicle, initial: trip);
      },
    );
  }
}

/// Carrega o [Vehicle] e abre a tela de compartilhamento.
///
/// Redireciona para /vehicles se o veículo não existir.
class _VehicleShareLoader extends ConsumerWidget {
  const _VehicleShareLoader({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = Future(() async {
      final repo = ref.read(vehicleRepositoryProvider);
      return repo.getById(vehicleId);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/vehicles');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ShareVehicleScreen(vehicle: snapshot.data!);
      },
    );
  }
}
