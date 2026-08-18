import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:clean_solid_cli_mobile/core/error/failures.dart';
import 'package:clean_solid_cli_mobile/features/session/domain/entity/session_entity.dart';
import 'package:clean_solid_cli_mobile/features/session/domain/usecases/session_usecases.dart';
import 'package:clean_solid_cli_mobile/features/session/presentation/controller/session_controller.dart';

class MockSessionUsecases extends Mock implements SessionUsecases {}

void main() {
  late SessionController sut;
  late MockSessionUsecases mockUsecases;

  setUp(() {
    mockUsecases = MockSessionUsecases();
    sut = SessionController(mockUsecases);
    registerFallbackValue(SessionEntity());
  });

  void setupSearchSuccess(List<SessionEntity> entities) {
    when(() => mockUsecases.searchSession(
      criteria: any(named: 'criteria'),
      start: any(named: 'start'),
      end: any(named: 'end'),
    )).thenAnswer((_) async => Right(entities));
  }

  group('searchSession', () {
    const tEntities = [SessionEntity(id: '1'), SessionEntity(id: '2')];

    test('should populate list and clear error on success', () async {
      setupSearchSuccess(tEntities);
      await sut.searchSession(null);
      expect(sut.state.isLoading, false);
      expect(sut.state.sessions, tEntities);
      expect(sut.state.error, isNull);
    });

    test('should set error on failure', () async {
      const tFailure = ServerFailure(message: 'Server error', code: '500');
      when(() => mockUsecases.searchSession(
        criteria: any(named: 'criteria'),
        start: any(named: 'start'),
        end: any(named: 'end'),
      )).thenAnswer((_) async => const Left(tFailure));
      await sut.searchSession(null);
      expect(sut.state.isLoading, false);
      expect(sut.state.error, const ServerFailure(message: 'Server error', code: '500'));
    });
  });

  group('createSession', () {
    const tEntity = SessionEntity(id: 'new-1');

    test('should prepend new entity to list', () async {
      setupSearchSuccess(const [SessionEntity(id: 'old-1')]);
      await sut.searchSession(null);
      expect(sut.state.sessions?.length, 1);
      when(() => mockUsecases.insertSession(any()))
          .thenAnswer((_) async => Right(tEntity));
      await sut.createSession(tEntity);
      expect(sut.state.sessions?.first.id, 'new-1');
      expect(sut.state.sessions?.length, 2);
      expect(sut.state.error, isNull);
    });
  });

  group('updateSession', () {
    test('should keep entity in list on success', () async {
      setupSearchSuccess(const [SessionEntity(id: '1')]);
      when(() => mockUsecases.updateSession(any()))
          .thenAnswer((_) async => const Right(SessionEntity(id: '1')));
      await sut.searchSession(null);
      await sut.updateSession(const SessionEntity(id: '1'));
      expect(sut.state.sessions?.length, 1);
      expect(sut.state.error, isNull);
    });
  });

  group('deleteSessionById', () {
    test('should remove entity from list', () async {
      setupSearchSuccess(const [SessionEntity(id: '1'), SessionEntity(id: '2')]);
      when(() => mockUsecases.deleteSessionById('1'))
          .thenAnswer((_) async => const Right(unit));
      await sut.searchSession(null);
      expect(sut.state.sessions?.length, 2);
      await sut.deleteSessionById('1');
      expect(sut.state.sessions?.length, 1);
      expect(sut.state.sessions?.first.id, '2');
      expect(sut.state.error, isNull);
    });
  });
}
