import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kyarem_eventos/services/partida_service.dart';
import 'package:kyarem_eventos/models/partida_model.dart';

import 'partida_service_test.mocks.dart';

// Instrui o build_runner a gerar MockDio
@GenerateMocks([Dio])
void main() {
  late MockDio mockDio;
  late PartidaService service;

  Response<dynamic> _fakeResponse(dynamic data, {int statusCode = 200}) {
    return Response(
      data: data,
      statusCode: statusCode,
      requestOptions: RequestOptions(path: ''),
    );
  }

  setUpAll(() {
    // Necessário em testes (Windows/Linux) pois o PartidaService usa SQLite no construtor
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    mockDio = MockDio();
    when(mockDio.interceptors).thenReturn(Interceptors());
    service = PartidaService(dio: mockDio);
  });

  tearDown(() {
    service.dispose();
  });

  // ============================================================
  // LISTAR PARTIDAS
  // ============================================================
  group('PartidaService — listarTodasPartidas', () {
    test('deve retornar lista de partidas em caso de sucesso', () async {
      // Stub: retorna duas partidas para /partidas
      // O enriquecimento de equipes tentará GET /equipes/{id} e falhará silenciosamente
      // (comportamento esperado quando não há equipes no cache)
      when(mockDio.get('/partidas', queryParameters: anyNamed('queryParameters'),
              options: anyNamed('options'),
              cancelToken: anyNamed('cancelToken'),
              onReceiveProgress: anyNamed('onReceiveProgress')))
          .thenAnswer((_) async => _fakeResponse([
                {
                  'id': 'p1',
                  'modalidadeId': 'm1',
                  'status': 'agendada',
                  'equipeAId': 'eq-a',
                  'equipeBId': 'eq-b',
                },
                {
                  'id': 'p2',
                  'modalidadeId': 'm2',
                  'status': 'em_andamento',
                  'equipeAId': 'eq-c',
                  'equipeBId': 'eq-d',
                },
              ]));

      // Stub: equipes individuais lançam exceção (enriquecimento falha graciosamente)
      when(mockDio.get('/equipes/eq-a', queryParameters: anyNamed('queryParameters'),
              options: anyNamed('options'),
              cancelToken: anyNamed('cancelToken'),
              onReceiveProgress: anyNamed('onReceiveProgress')))
          .thenThrow(DioException(requestOptions: RequestOptions(path: '/equipes/eq-a')));
      when(mockDio.get('/equipes/eq-b', queryParameters: anyNamed('queryParameters'),
              options: anyNamed('options'),
              cancelToken: anyNamed('cancelToken'),
              onReceiveProgress: anyNamed('onReceiveProgress')))
          .thenThrow(DioException(requestOptions: RequestOptions(path: '/equipes/eq-b')));
      when(mockDio.get('/equipes/eq-c', queryParameters: anyNamed('queryParameters'),
              options: anyNamed('options'),
              cancelToken: anyNamed('cancelToken'),
              onReceiveProgress: anyNamed('onReceiveProgress')))
          .thenThrow(DioException(requestOptions: RequestOptions(path: '/equipes/eq-c')));
      when(mockDio.get('/equipes/eq-d', queryParameters: anyNamed('queryParameters'),
              options: anyNamed('options'),
              cancelToken: anyNamed('cancelToken'),
              onReceiveProgress: anyNamed('onReceiveProgress')))
          .thenThrow(DioException(requestOptions: RequestOptions(path: '/equipes/eq-d')));

      final result = await service.listarTodasPartidas();

      expect(result, hasLength(2));
      expect(result[0].id, 'p1');
      expect(result[1].status, 'em_andamento');
    });

    test('deve retornar lista vazia em caso de erro na API', () async {
      when(mockDio.get('/partidas', queryParameters: anyNamed('queryParameters'),
              options: anyNamed('options'),
              cancelToken: anyNamed('cancelToken'),
              onReceiveProgress: anyNamed('onReceiveProgress')))
          .thenThrow(DioException(requestOptions: RequestOptions(path: '/partidas')));

      final result = await service.listarTodasPartidas();
      expect(result, isEmpty);
    });
  });

  // ============================================================
  // BUSCAR PARTIDA POR ID
  // ============================================================
  group('PartidaService — buscarPartidaPorId', () {
    test('deve retornar Partida quando encontrada', () async {
      when(mockDio.get('/partidas/p1', queryParameters: anyNamed('queryParameters'),
              options: anyNamed('options'),
              cancelToken: anyNamed('cancelToken'),
              onReceiveProgress: anyNamed('onReceiveProgress')))
          .thenAnswer((_) async => _fakeResponse({
                'id': 'p1',
                'modalidadeId': 'm1',
                'status': 'agendada',
                'equipeAId': 'eq-a',
                'equipeBId': 'eq-b',
              }));

      final result = await service.buscarPartidaPorId('p1');

      expect(result, isNotNull);
      expect(result?.id, 'p1');
      expect(result?.status, 'agendada');
    });

    test('deve retornar null em caso de erro', () async {
      when(mockDio.get('/partidas/p-nao-existe', queryParameters: anyNamed('queryParameters'),
              options: anyNamed('options'),
              cancelToken: anyNamed('cancelToken'),
              onReceiveProgress: anyNamed('onReceiveProgress')))
          .thenThrow(DioException(requestOptions: RequestOptions(path: '/partidas/p-nao-existe')));

      final result = await service.buscarPartidaPorId('p-nao-existe');
      expect(result, isNull);
    });
  });

  // ============================================================
  // STATUS DA PARTIDA
  // ============================================================
  group('PartidaService — atualizarPartida (status)', () {
    test('deve chamar PATCH /partidas/{id}/status com status correto', () async {
      when(mockDio.patch('/partidas/p1/status', data: anyNamed('data'),
              queryParameters: anyNamed('queryParameters'),
              options: anyNamed('options'),
              cancelToken: anyNamed('cancelToken'),
              onSendProgress: anyNamed('onSendProgress'),
              onReceiveProgress: anyNamed('onReceiveProgress')))
          .thenAnswer((_) async => _fakeResponse({'ok': true}));

      // Não deve lançar exceção
      await expectLater(
        service.atualizarPartida('p1', novoStatus: 'em_andamento'),
        completes,
      );

      verify(mockDio.patch('/partidas/p1/status', data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'))).called(1);
    });

    test('deve ignorar status vazio sem fazer requisição', () async {
      await service.atualizarPartida('p1', novoStatus: '');

      verifyNever(mockDio.patch(any, data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress')));
    });

    test('deve ignorar status null sem fazer requisição', () async {
      await service.atualizarPartida('p1', novoStatus: null);

      verifyNever(mockDio.patch(any, data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress')));
    });
  });

  // ============================================================
  // START / END PARTIDA
  // ============================================================
  group('PartidaService — startPartida', () {
    test('deve chamar POST /partidas/{id}/start sem lançar exceção', () async {
      when(mockDio.post('/partidas/p1/start', data: anyNamed('data'),
              queryParameters: anyNamed('queryParameters'),
              options: anyNamed('options'),
              cancelToken: anyNamed('cancelToken'),
              onSendProgress: anyNamed('onSendProgress'),
              onReceiveProgress: anyNamed('onReceiveProgress')))
          .thenAnswer((_) async => _fakeResponse({'ok': true}));

      await expectLater(service.startPartida('p1'), completes);
    });
  });

  group('PartidaService — endPartida', () {
    test('deve retornar statusCode 200 em caso de sucesso', () async {
      when(mockDio.post('/partidas/p1/end', data: anyNamed('data'),
              queryParameters: anyNamed('queryParameters'),
              options: anyNamed('options'),
              cancelToken: anyNamed('cancelToken'),
              onSendProgress: anyNamed('onSendProgress'),
              onReceiveProgress: anyNamed('onReceiveProgress')))
          .thenAnswer((_) async => _fakeResponse({'ok': true}, statusCode: 200));

      final (code, detail) = await service.endPartida('p1');

      expect(code, 200);
      expect(detail, isNull);
    });

    test('deve retornar statusCode 409 e detail quando já encerrada', () async {
      when(mockDio.post('/partidas/p1/end', data: anyNamed('data'),
              queryParameters: anyNamed('queryParameters'),
              options: anyNamed('options'),
              cancelToken: anyNamed('cancelToken'),
              onSendProgress: anyNamed('onSendProgress'),
              onReceiveProgress: anyNamed('onReceiveProgress')))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: '/partidas/p1/end'),
            response: Response(
              requestOptions: RequestOptions(path: '/partidas/p1/end'),
              statusCode: 409,
              data: {'detail': 'Partida já encerrada'},
            ),
          ));

      final (code, detail) = await service.endPartida('p1');

      expect(code, 409);
      expect(detail, 'Partida já encerrada');
    });
  });

  // ============================================================
  // BUSCAR DADOS POR ABA
  // ============================================================
  group('PartidaService — buscarDadosPorAba', () {
    test('deve retornar lista vazia para aba desconhecida', () async {
      final result = await service.buscarDadosPorAba('AbaInexistente');
      expect(result, isEmpty);
    });
  });
}
