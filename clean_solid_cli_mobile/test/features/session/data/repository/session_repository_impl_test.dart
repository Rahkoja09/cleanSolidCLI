import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:clean_solid_cli_mobile/core/error/exceptions.dart';
import 'package:clean_solid_cli_mobile/core/error/failures.dart';
import 'package:clean_solid_cli_mobile/core/network/network_info.dart';
import 'package:clean_solid_cli_mobile/features/session/data/model/session_model.dart';
import 'package:clean_solid_cli_mobile/features/session/data/source/session_remote_source.dart';
import 'package:clean_solid_cli_mobile/features/session/data/repository/session_repository_impl.dart';
import 'package:clean_solid_cli_mobile/features/session/domain/entity/session_entity.dart';

class MockSessionRemoteSource extends Mock implements SessionRemoteSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late SessionRepositoryImpl sut;
  late MockSessionRemoteSource mockRemoteSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteSource = MockSessionRemoteSource();
    mockNetworkInfo = MockNetworkInfo();
    sut = SessionRepositoryImpl(mockRemoteSource, mockNetworkInfo);
    registerFallbackValue(SessionEntity());
  });

  void setupConnected() {
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
  }

  void setupOffline() {
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
  }

  group('insertSession', () {
    const tEntity = SessionEntity(id: '1');
    final tModel = SessionModel(id: '1');

    test('should return Right when online and source succeeds', () async {
      setupConnected();
      when(() => mockRemoteSource.insertSession(any()))
          .thenAnswer((_) async => tModel);
      final result = await sut.insertSession(tEntity);
      expect(result.isRight(), true);
      verify(() => mockRemoteSource.insertSession(tEntity)).called(1);
    });

    test('should return NetworkFailure when offline', () async {
      setupOffline();
      final result = await sut.insertSession(tEntity);
      expect(result, Left(NetworkFailure(message: 'Pas de connexion Internet', code: 'NET_001')));
      verifyNever(() => mockRemoteSource.insertSession(any()));
    });

    test('should return ApiFailure on ApiException', () async {
      setupConnected();
      when(() => mockRemoteSource.insertSession(any()))
          .thenThrow(ApiException(message: 'Not Found', code: '404'));
      final result = await sut.insertSession(tEntity);
      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f, isA<ApiFailure>()),
        (_) => fail('Should not be Right'),
      );
    });

    test('should return UnexpectedFailure on unknown exception', () async {
      setupConnected();
      when(() => mockRemoteSource.insertSession(any()))
          .thenThrow(Exception('unexpected'));
      final result = await sut.insertSession(tEntity);
      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f, isA<UnexpectedFailure>()),
        (_) => fail('Should not be Right'),
      );
    });
  });

  group('updateSession', () {
    const tEntity = SessionEntity(id: '1');
    final tModel = SessionModel(id: '1');

    test('should return updated entity', () async {
      setupConnected();
      when(() => mockRemoteSource.updateSession(any()))
          .thenAnswer((_) async => tModel);
      final result = await sut.updateSession(tEntity);
      expect(result.isRight(), true);
    });

    test('should return NetworkFailure when offline', () async {
      setupOffline();
      final result = await sut.updateSession(tEntity);
      expect(result, Left(NetworkFailure(message: 'Pas de connexion Internet', code: 'NET_001')));
    });
  });

  group('searchSession', () {
    final tModels = [SessionModel(id: '1'), SessionModel(id: '2')];

    test('should return list of entities', () async {
      setupConnected();
      when(() => mockRemoteSource.searchSession(any(), start: any(named: 'start'), end: any(named: 'end')))
          .thenAnswer((_) async => tModels);
      final result = await sut.searchSession(start: 0, end: 9);
      expect(result.isRight(), true);
    });

    test('should return empty list when no results', () async {
      setupConnected();
      when(() => mockRemoteSource.searchSession(any(), start: any(named: 'start'), end: any(named: 'end')))
          .thenAnswer((_) async => <SessionModel>[]);
      final result = await sut.searchSession(start: 0, end: 9);
      expect(result.isRight(), true);
    });

    test('should return NetworkFailure when offline', () async {
      setupOffline();
      final result = await sut.searchSession(start: 0, end: 9);
      expect(result, Left(NetworkFailure(message: 'Pas de connexion Internet', code: 'NET_001')));
    });
  });

  group('getSessionById', () {
    final tModel = SessionModel(id: '1');

    test('should return entity', () async {
      setupConnected();
      when(() => mockRemoteSource.getSessionById('1'))
          .thenAnswer((_) async => tModel);
      final result = await sut.getSessionById('1');
      expect(result.isRight(), true);
    });
  });

  group('deleteSessionById', () {
    test('should return unit on success', () async {
      setupConnected();
      when(() => mockRemoteSource.deleteSessionById('1'))
          .thenAnswer((_) async {});
      expect((await sut.deleteSessionById('1')).isRight(), true);
    });

    test('should return NetworkFailure when offline', () async {
      setupOffline();
      final result = await sut.deleteSessionById('1');
      expect(result, Left(NetworkFailure(message: 'Pas de connexion Internet', code: 'NET_001')));
    });
  });
}
