import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/user_profile_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/user_profile.dart';
import 'package:autolog/domain/repositories/user_profile_repository.dart' as domain;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.O — Repositório de perfil de usuário (CRUD local).
void main() {
  late AppDatabase db;
  late DateTime fakeNow;
  late domain.UserProfileRepository repo;

  DateTime now() => fakeNow;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 5, 24, 10);
    repo = DriftUserProfileRepository(db, now: now);
  });

  tearDown(() => db.close());

  group('getOrCreate', () {
    test('cria perfil vazio se não existir', () async {
      final profile = await repo.getOrCreate('u1');

      expect(profile.userId, 'u1');
      expect(profile.syncStatus, SyncStatus.pending);
      expect(profile.createdAt, fakeNow);
      expect(profile.updatedAt, fakeNow);
      expect(profile.cnhNumber, isNull);
      expect(profile.cnhCategory, isNull);
      expect(profile.cnhExpiresAt, isNull);
    });

    test('retorna existente se já houver', () async {
      await repo.getOrCreate('u1');
      fakeNow = DateTime.utc(2026, 5, 24, 11);

      final second = await repo.getOrCreate('u1');
      // createdAt deve ser o original
      expect(second.createdAt, DateTime.utc(2026, 5, 24, 10));
    });

    test('isolamento por userId', () async {
      await repo.getOrCreate('u1');
      await repo.getOrCreate('u2');

      final p1 = await repo.getById('u1');
      final p2 = await repo.getById('u2');
      expect(p1!.userId, 'u1');
      expect(p2!.userId, 'u2');
    });
  });

  group('update', () {
    test('atualiza campos e marca pending, bumpa updatedAt', () async {
      await repo.getOrCreate('u1');
      fakeNow = DateTime.utc(2026, 5, 24, 12);

      final existing = await repo.getById('u1');
      await repo.update(
        existing!.copyWith(
          cnhNumber: '01234567891',
          cnhCategory: 'B',
          cnhExpiresAt: DateTime.utc(2030, 1, 1),
        ),
      );

      final updated = await repo.getById('u1');
      expect(updated!.cnhNumber, '01234567891');
      expect(updated.cnhCategory, 'B');
      expect(updated.cnhExpiresAt, DateTime.utc(2030, 1, 1));
      expect(updated.updatedAt, fakeNow);
      expect(updated.syncStatus, SyncStatus.pending);
    });

    test('upsert (cria se não existir via insertOnConflictUpdate)', () async {
      final profile = UserProfile(
        userId: 'u_new',
        cnhNumber: '12345678901',
        cnhCategory: 'B',
        cnhExpiresAt: null,
        createdAt: fakeNow,
        updatedAt: fakeNow,
        syncStatus: SyncStatus.pending,
      );
      await repo.update(profile);

      final found = await repo.getById('u_new');
      expect(found, isNotNull);
      expect(found!.cnhNumber, '12345678901');
    });
  });

  group('watch', () {
    test('emite inicial e em cada mutação', () async {
      final stream = repo.watch('u1');
      final emissions = <UserProfile?>[];
      final sub = stream.listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      await repo.getOrCreate('u1');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      fakeNow = fakeNow.add(const Duration(minutes: 1));
      final existing = await repo.getById('u1');
      await repo.update(existing!.copyWith(cnhCategory: 'A'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await sub.cancel();

      expect(emissions.length, greaterThanOrEqualTo(3));
      expect(emissions.first, isNull);
      expect(emissions[1], isNotNull);
      expect(emissions.last!.cnhCategory, 'A');
    });
  });
}
