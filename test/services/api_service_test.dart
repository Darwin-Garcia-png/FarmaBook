import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:farmabook_flutter/services/api_service.dart';

class MockClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockClient mockClient;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  setUp(() {
    mockClient = MockClient();
    ApiService.testClient = mockClient;
    ApiService.clearCachedToken();
    ApiService.testCachedToken = 'test-token';
  });

  tearDown(() {
    ApiService.testClient = null;
    ApiService.testCachedToken = null;
  });

  group('ApiService', () {
    test('checkResponse throws ApiException on 400+', () async {
      final resp = http.Response('{"message":"Bad Request"}', 400);
      expect(
        () => ApiService.checkResponse(resp),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Bad Request')),
      );
    });

    test('checkResponse throws ApiException with nested error message', () async {
      final resp = http.Response('{"error":{"message":"Not Found"}}', 404);
      expect(
        () => ApiService.checkResponse(resp),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Not Found')),
      );
    });

    test('checkResponse does not throw on 200', () async {
      final resp = http.Response('{"data":"ok"}', 200);
      expect(() => ApiService.checkResponse(resp), returnsNormally);
    });

    test('checkResponse does not throw on 201', () async {
      final resp = http.Response('{"data":"created"}', 201);
      expect(() => ApiService.checkResponse(resp), returnsNormally);
    });

    test('createUser sends POST /users with correct body', () async {
      when(() => mockClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).thenAnswer((_) async => http.Response(
        '{"data":{"id":1,"username":"test"}}',
        201,
      ));

      final result = await ApiService.createUser({
        'username': 'testuser',
        'email': 'test@test.com',
        'password': '123456',
        'rolNombre': 'Administrador',
      });

      verify(() => mockClient.post(
        Uri.parse('https://farmabook.jonathanalarcon.qzz.io/users'),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).called(1);

      expect(result, containsPair('data', {'id': 1, 'username': 'test'}));
    });

    test('createUser throws ApiException on server error', () async {
      when(() => mockClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).thenAnswer((_) async => http.Response(
        '{"message":"Email already exists"}',
        409,
      ));

      expect(
        () => ApiService.createUser({'username': 'dup', 'email': 'dup@test.com', 'password': '123456'}),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409)),
      );
    });

    test('getUsers sends GET /users', () async {
      when(() => mockClient.get(
        any(),
        headers: any(named: 'headers'),
      )).thenAnswer((_) async => http.Response(
        '{"data":[{"id":1,"username":"admin"}]}',
        200,
      ));

      final users = await ApiService.getUsers();
      expect(users.length, 1);
      expect(users.first['username'], 'admin');
    });
  });
}
