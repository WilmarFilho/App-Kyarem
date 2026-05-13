import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kyarem_eventos/services/admin_api_service.dart';

import 'admin_api_service_test.mocks.dart';

// Instrui o build_runner a gerar MockDio
@GenerateMocks([Dio])
void main() {
  late MockDio mockDio;
  late AdminApiService service;

  /// Cria um [Response] fake com os dados e status informados.
  Response<dynamic> fakeResponse(dynamic data, {int statusCode = 200}) {
    return Response(
      data: data,
      statusCode: statusCode,
      requestOptions: RequestOptions(path: ''),
    );
  }

  setUp(() {
    mockDio = MockDio();
    // Stub do interceptors.add para que o AdminApiService não quebre
    // ao tentar registrar interceptors no Dio mockado.
    when(mockDio.interceptors).thenReturn(Interceptors());
    service = AdminApiService(dio: mockDio);
  });

  // ============================================================
  // CAMPEONATOS
  // ============================================================
  group('AdminApiService — listarCampeonatos', () {
    test('deve retornar lista de campeonatos em caso de sucesso', () async {
      when(
        mockDio.get(
          '/campeonatos',
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenAnswer(
        (_) async => fakeResponse([
          {'id': 'c1', 'nome': 'Copa Universitária'},
          {'id': 'c2', 'nome': 'Liga de Verão'},
        ]),
      );

      final result = await service.listarCampeonatos();

      expect(result, hasLength(2));
      expect(result.first.nome, 'Copa Universitária');
      expect(result[1].nome, 'Liga de Verão');
    });

    test('deve retornar lista vazia quando a API lança exceção', () async {
      when(
        mockDio.get(
          '/campeonatos',
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/campeonatos')),
      );

      final result = await service.listarCampeonatos();

      expect(result, isEmpty);
    });

    test(
      'deve retornar lista vazia quando a API retorna lista vazia',
      () async {
        when(
          mockDio.get(
            '/campeonatos',
            queryParameters: anyNamed('queryParameters'),
          ),
        ).thenAnswer((_) async => fakeResponse([]));

        final result = await service.listarCampeonatos();
        expect(result, isEmpty);
      },
    );
  });

  group('AdminApiService — criarCampeonato', () {
    test('deve retornar Campeonato em caso de sucesso', () async {
      final payload = {'nome': 'Novo Campeonato', 'nivelCampeonato': 'Local'};
      when(mockDio.post('/campeonatos', data: anyNamed('data'))).thenAnswer(
        (_) async => fakeResponse({'id': 'c-new', 'nome': 'Novo Campeonato'}),
      );

      final result = await service.criarCampeonato(payload);

      expect(result, isNotNull);
      expect(result?.id, 'c-new');
      expect(result?.nome, 'Novo Campeonato');
    });

    test('deve retornar null quando a API lança exceção', () async {
      when(mockDio.post('/campeonatos', data: anyNamed('data'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/campeonatos')),
      );

      final result = await service.criarCampeonato({'nome': 'X'});
      expect(result, isNull);
    });
  });

  group('AdminApiService — atualizarCampeonato', () {
    test('deve retornar Campeonato atualizado em caso de sucesso', () async {
      final payload = {'nome': 'Nome Atualizado'};
      when(mockDio.put('/campeonatos/c1', data: anyNamed('data'))).thenAnswer(
        (_) async => fakeResponse({'id': 'c1', 'nome': 'Nome Atualizado'}),
      );

      final result = await service.atualizarCampeonato('c1', payload);

      expect(result, isNotNull);
      expect(result?.nome, 'Nome Atualizado');
    });

    test('deve retornar null em caso de erro', () async {
      when(mockDio.put('/campeonatos/c1', data: anyNamed('data'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/campeonatos/c1')),
      );

      final result = await service.atualizarCampeonato('c1', {});
      expect(result, isNull);
    });
  });

  group('AdminApiService — excluirCampeonato', () {
    test('deve retornar true em caso de sucesso', () async {
      when(
        mockDio.delete('/campeonatos/c1'),
      ).thenAnswer((_) async => fakeResponse(null, statusCode: 204));

      final result = await service.excluirCampeonato('c1');
      expect(result, isTrue);
    });

    test('deve retornar false em caso de erro', () async {
      when(mockDio.delete('/campeonatos/c1')).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/campeonatos/c1')),
      );

      final result = await service.excluirCampeonato('c1');
      expect(result, isFalse);
    });
  });

  // ============================================================
  // ATLÉTICAS
  // ============================================================
  group('AdminApiService — listarAtleticas', () {
    test('deve retornar lista de atleticas em caso de sucesso', () async {
      when(
        mockDio.get('/atleticas', queryParameters: anyNamed('queryParameters')),
      ).thenAnswer(
        (_) async => fakeResponse([
          {'id': 'atl-1', 'nome': 'Atlética Eng'},
          {'id': 'atl-2', 'nome': 'Atlética Med'},
        ]),
      );

      final result = await service.listarAtleticas();

      expect(result, hasLength(2));
      expect(result.first.nome, 'Atlética Eng');
    });

    test('deve retornar lista vazia em caso de erro', () async {
      when(
        mockDio.get('/atleticas', queryParameters: anyNamed('queryParameters')),
      ).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/atleticas')),
      );

      final result = await service.listarAtleticas();
      expect(result, isEmpty);
    });
  });

  group('AdminApiService — buscarAtleticaDoPresidente', () {
    test('deve retornar id da atletica quando usuario é presidente', () async {
      when(
        mockDio.get('/atleticas', queryParameters: anyNamed('queryParameters')),
      ).thenAnswer(
        (_) async => fakeResponse([
          {'id': 'atl-1', 'presidenteId': 'user-abc', 'nome': 'Atlética Eng'},
          {'id': 'atl-2', 'presidenteId': 'user-xyz', 'nome': 'Atlética Med'},
        ]),
      );

      final result = await service.buscarAtleticaDoPresidente('user-abc');
      expect(result, 'atl-1');
    });

    test(
      'deve retornar null quando usuario não é presidente de nenhuma atletica',
      () async {
        when(
          mockDio.get(
            '/atleticas',
            queryParameters: anyNamed('queryParameters'),
          ),
        ).thenAnswer(
          (_) async => fakeResponse([
            {'id': 'atl-1', 'presidenteId': 'user-outro', 'nome': 'Outro'},
          ]),
        );

        final result = await service.buscarAtleticaDoPresidente(
          'user-sem-atletica',
        );
        expect(result, isNull);
      },
    );

    test('deve aceitar campo presidente_id no formato snake_case', () async {
      when(
        mockDio.get('/atleticas', queryParameters: anyNamed('queryParameters')),
      ).thenAnswer(
        (_) async => fakeResponse([
          {
            'id': 'atl-3',
            'presidente_id': 'user-snake',
            'nome': 'Atlética Snake',
          },
        ]),
      );

      final result = await service.buscarAtleticaDoPresidente('user-snake');
      expect(result, 'atl-3');
    });

    test('deve retornar null em caso de erro na API', () async {
      when(
        mockDio.get('/atleticas', queryParameters: anyNamed('queryParameters')),
      ).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/atleticas')),
      );

      final result = await service.buscarAtleticaDoPresidente('user-x');
      expect(result, isNull);
    });
  });

  // ============================================================
  // ÁRBITROS
  // ============================================================
  group('AdminApiService — listarArbitros', () {
    test('deve retornar lista de árbitros em caso de sucesso', () async {
      when(
        mockDio.get('/arbitros', queryParameters: anyNamed('queryParameters')),
      ).thenAnswer(
        (_) async => fakeResponse([
          {'id': 'arb-1', 'nomeExibicao': 'João Silva'},
          {'id': 'arb-2', 'nomeExibicao': 'Maria Souza'},
        ]),
      );

      final result = await service.listarArbitros();

      expect(result, hasLength(2));
      expect(result.first.nome, 'João Silva');
    });

    test('deve retornar lista vazia em caso de erro', () async {
      when(
        mockDio.get('/arbitros', queryParameters: anyNamed('queryParameters')),
      ).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/arbitros')),
      );

      final result = await service.listarArbitros();
      expect(result, isEmpty);
    });
  });

  group('AdminApiService — vincularArbitro', () {
    test('deve retornar true em caso de sucesso', () async {
      when(
        mockDio.post('/partidas/p1/arbitros', data: anyNamed('data')),
      ).thenAnswer((_) async => fakeResponse({'ok': true}));

      final result = await service.vincularArbitro(
        'p1',
        'arb-1',
        'Árbitro Principal',
      );
      expect(result, isTrue);
    });

    test('deve retornar false em caso de erro', () async {
      when(
        mockDio.post('/partidas/p1/arbitros', data: anyNamed('data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/partidas/p1/arbitros'),
        ),
      );

      final result = await service.vincularArbitro('p1', 'arb-1', 'Mesário');
      expect(result, isFalse);
    });
  });

  group('AdminApiService — desvincularArbitro', () {
    test('deve retornar true em caso de sucesso', () async {
      when(
        mockDio.delete('/partidas/p1/arbitros/vinc-1'),
      ).thenAnswer((_) async => fakeResponse(null, statusCode: 204));

      final result = await service.desvincularArbitro('p1', 'vinc-1');
      expect(result, isTrue);
    });

    test('deve retornar false em caso de erro', () async {
      when(mockDio.delete('/partidas/p1/arbitros/vinc-1')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/partidas/p1/arbitros/vinc-1'),
        ),
      );

      final result = await service.desvincularArbitro('p1', 'vinc-1');
      expect(result, isFalse);
    });
  });

  // ============================================================
  // EQUIPES
  // ============================================================
  group('AdminApiService — listarEquipes', () {
    test('deve retornar lista de equipes sem filtros', () async {
      when(
        mockDio.get('/equipes', queryParameters: anyNamed('queryParameters')),
      ).thenAnswer(
        (_) async => fakeResponse([
          {'id': 'eq-1', 'nome': 'Engenharia FC', 'atleticaId': 'atl-1'},
          {'id': 'eq-2', 'nome': 'Medicina RC', 'atleticaId': 'atl-2'},
        ]),
      );

      final result = await service.listarEquipes();
      expect(result, hasLength(2));
    });

    test('deve retornar lista vazia em caso de erro', () async {
      when(
        mockDio.get('/equipes', queryParameters: anyNamed('queryParameters')),
      ).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/equipes')),
      );

      final result = await service.listarEquipes();
      expect(result, isEmpty);
    });
  });

  group('AdminApiService — excluirEquipe', () {
    test('deve retornar true em caso de sucesso', () async {
      when(
        mockDio.delete('/equipes/eq-1'),
      ).thenAnswer((_) async => fakeResponse(null, statusCode: 204));

      final result = await service.excluirEquipe('eq-1');
      expect(result, isTrue);
    });

    test('deve retornar false em caso de erro', () async {
      when(mockDio.delete('/equipes/eq-1')).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/equipes/eq-1')),
      );

      final result = await service.excluirEquipe('eq-1');
      expect(result, isFalse);
    });
  });

  // ============================================================
  // PARTIDAS (ADMIN)
  // ============================================================
  group('AdminApiService — criarPartida', () {
    test('deve retornar map de partida em caso de sucesso', () async {
      final payload = {
        'modalidadeId': 'm1',
        'equipeAId': 'a',
        'equipeBId': 'b',
      };
      when(mockDio.post('/partidas', data: anyNamed('data'))).thenAnswer(
        (_) async => fakeResponse({'id': 'p-new', 'status': 'agendada'}),
      );

      final result = await service.criarPartida(payload);

      expect(result, isNotNull);
      expect(result?['id'], 'p-new');
      expect(result?['status'], 'agendada');
    });

    test('deve retornar null em caso de erro', () async {
      when(mockDio.post('/partidas', data: anyNamed('data'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/partidas')),
      );

      final result = await service.criarPartida({});
      expect(result, isNull);
    });
  });

  group('AdminApiService — excluirPartida', () {
    test('deve retornar true em caso de sucesso', () async {
      when(
        mockDio.delete('/partidas/p1'),
      ).thenAnswer((_) async => fakeResponse(null, statusCode: 204));

      final result = await service.excluirPartida('p1');
      expect(result, isTrue);
    });

    test('deve retornar false em caso de erro', () async {
      when(mockDio.delete('/partidas/p1')).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/partidas/p1')),
      );

      final result = await service.excluirPartida('p1');
      expect(result, isFalse);
    });
  });
}
