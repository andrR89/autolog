import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fine.dart';
import 'package:autolog/domain/models/insurance.dart';
import 'package:autolog/domain/models/user_profile.dart';
import 'package:autolog/features/personal_documents/document_reminder_suggestions.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.O — `suggestDocumentReminders` pura.
/// Spec: docs/specs/sprint-6.O-personal-documents.md
void main() {
  final now = DateTime.utc(2026, 5, 26);

  UserProfile profile({DateTime? expires}) => UserProfile(
        userId: 'u1',
        cnhExpiresAt: expires,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.synced,
      );

  Fine fine({
    String id = 'f1',
    DateTime? due,
    bool paid = false,
  }) =>
      Fine(
        id: id,
        vehicleId: 'v1',
        issuedAt: now.subtract(const Duration(days: 30)),
        description: 'X',
        amount: Decimal.parse('100'),
        dueDate: due,
        paid: paid,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.synced,
      );

  Insurance insurance({
    String id = 'i1',
    required DateTime ends,
    String? insurer,
  }) =>
      Insurance(
        id: id,
        vehicleId: 'v1',
        insurer: insurer,
        startsAt: now.subtract(const Duration(days: 30)),
        endsAt: ends,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.synced,
      );

  group('CNH', () {
    test('expira em 25 dias (≤30) → 1 proposta', () {
      final r = suggestDocumentReminders(
        profile: profile(expires: now.add(const Duration(days: 25))),
        unpaidFines: const [],
        activeInsurances: const [],
        now: now,
      );
      expect(r.length, 1);
      expect(r.single.title.toLowerCase().contains('cnh'), isTrue);
    });

    test('expira em 60 dias (>30) → 0 propostas', () {
      final r = suggestDocumentReminders(
        profile: profile(expires: now.add(const Duration(days: 60))),
        unpaidFines: const [],
        activeInsurances: const [],
        now: now,
      );
      expect(r, isEmpty);
    });

    test('profile null ou cnhExpiresAt null → sem proposta de CNH', () {
      expect(
        suggestDocumentReminders(
          profile: null,
          unpaidFines: const [],
          activeInsurances: const [],
          now: now,
        ),
        isEmpty,
      );
      expect(
        suggestDocumentReminders(
          profile: profile(expires: null),
          unpaidFines: const [],
          activeInsurances: const [],
          now: now,
        ),
        isEmpty,
      );
    });
  });

  group('Seguro', () {
    test('vence em 30 dias (≤60) → 1 proposta', () {
      final r = suggestDocumentReminders(
        profile: null,
        unpaidFines: const [],
        activeInsurances: [
          insurance(ends: now.add(const Duration(days: 30))),
        ],
        now: now,
      );
      expect(r.length, 1);
      expect(r.single.title.toLowerCase().contains('seguro'), isTrue);
    });

    test('vence em 90 dias (>60) → 0 propostas', () {
      final r = suggestDocumentReminders(
        profile: null,
        unpaidFines: const [],
        activeInsurances: [
          insurance(ends: now.add(const Duration(days: 90))),
        ],
        now: now,
      );
      expect(r, isEmpty);
    });

    test('insurer aparece no título quando preenchido', () {
      final r = suggestDocumentReminders(
        profile: null,
        unpaidFines: const [],
        activeInsurances: [
          insurance(
            ends: now.add(const Duration(days: 30)),
            insurer: 'Porto',
          ),
        ],
        now: now,
      );
      expect(r.single.title.contains('Porto'), isTrue);
    });
  });

  group('Multa', () {
    test('due em 5 dias (≤7) E não paga → 1 proposta', () {
      final r = suggestDocumentReminders(
        profile: null,
        unpaidFines: [
          fine(due: now.add(const Duration(days: 5)), paid: false),
        ],
        activeInsurances: const [],
        now: now,
      );
      expect(r.length, 1);
      expect(r.single.title.toLowerCase().contains('multa'), isTrue);
    });

    test('due em 30 dias (>7) → 0 propostas', () {
      final r = suggestDocumentReminders(
        profile: null,
        unpaidFines: [
          fine(due: now.add(const Duration(days: 30))),
        ],
        activeInsurances: const [],
        now: now,
      );
      expect(r, isEmpty);
    });

    test('paid=true → 0 propostas mesmo com due próximo', () {
      final r = suggestDocumentReminders(
        profile: null,
        unpaidFines: [
          fine(due: now.add(const Duration(days: 3)), paid: true),
        ],
        activeInsurances: const [],
        now: now,
      );
      expect(r, isEmpty);
    });

    test('due null → 0 propostas (sem data não dá pra agendar)', () {
      final r = suggestDocumentReminders(
        profile: null,
        unpaidFines: [fine(due: null)],
        activeInsurances: const [],
        now: now,
      );
      expect(r, isEmpty);
    });
  });

  group('Combinações', () {
    test('CNH + seguro + multa todos urgentes → 3 propostas', () {
      final r = suggestDocumentReminders(
        profile: profile(expires: now.add(const Duration(days: 20))),
        unpaidFines: [fine(due: now.add(const Duration(days: 5)))],
        activeInsurances: [
          insurance(ends: now.add(const Duration(days: 30))),
        ],
        now: now,
      );
      expect(r.length, 3);
    });

    test('múltiplas multas urgentes → 1 proposta por multa', () {
      final r = suggestDocumentReminders(
        profile: null,
        unpaidFines: [
          fine(id: 'f1', due: now.add(const Duration(days: 3))),
          fine(id: 'f2', due: now.add(const Duration(days: 5))),
          fine(id: 'f3', due: now.add(const Duration(days: 20))), // longe
        ],
        activeInsurances: const [],
        now: now,
      );
      expect(r.length, 2);
    });
  });
}
