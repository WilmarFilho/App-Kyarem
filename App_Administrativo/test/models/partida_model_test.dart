import 'package:flutter_test/flutter_test.dart';
import 'package:kyarem_eventos/models/partida_model.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';

void main() {
  group('Partida.fromMap', () {
    Map<String, dynamic> _mapCompleto() => {
      'id': 'partida-001',
      'modalidadeId': 'mod-001',
      'status': 'agendada',
      'equipeAId': 'eq-a',
      'equipeBId': 'eq-b',
      'placarA': 2,
      'placarB': 1,
      'local': 'Ginásio Central',
      'categoria': 'Sub-23',
      'fase': 'Quartas de Final',
      'agendadoPara': '2025-05-10T15:00:00.000Z',
      'iniciadaEm': '2025-05-10T15:05:00.000Z',
      'encerradaEm': '2025-05-10T16:20:00.000Z',
    };

    test('deve criar partida corretamente com todos os campos', () {
      final partida = Partida.fromMap(_mapCompleto());

      expect(partida.id, 'partida-001');
      expect(partida.modalidadeId, 'mod-001');
      expect(partida.status, 'agendada');
      expect(partida.equipeAId, 'eq-a');
      expect(partida.equipeBId, 'eq-b');
      expect(partida.placarA, 2);
      expect(partida.placarB, 1);
      expect(partida.local, 'Ginásio Central');
      expect(partida.categoria, 'Sub-23');
      expect(partida.fase, 'Quartas de Final');
    });

    test('deve parsear agendadoPara corretamente', () {
      final partida = Partida.fromMap(_mapCompleto());
      expect(
        partida.agendadaPara,
        DateTime.tryParse('2025-05-10T15:00:00.000Z'),
      );
    });

    test('alias agendadoPara deve funcionar igual a agendadaPara', () {
      final partida = Partida.fromMap(_mapCompleto());
      expect(partida.agendadoPara, equals(partida.agendadaPara));
    });

    test('deve aceitar agendada_para no formato snake_case', () {
      final map = {
        'id': '1',
        'modalidadeId': 'm1',
        'status': 'agendada',
        'equipeAId': 'a',
        'equipeBId': 'b',
        'agendada_para': '2025-06-01T10:00:00.000Z',
      };
      final partida = Partida.fromMap(map);
      expect(
        partida.agendadaPara,
        DateTime.tryParse('2025-06-01T10:00:00.000Z'),
      );
    });

    test('deve retornar placar zero quando não informado', () {
      final map = {
        'id': '1',
        'modalidadeId': 'm1',
        'status': 'agendada',
        'equipeAId': 'a',
        'equipeBId': 'b',
      };
      final partida = Partida.fromMap(map);
      expect(partida.placarA, 0);
      expect(partida.placarB, 0);
    });

    test('deve carregar equipeA a partir de campo nested "equipeA"', () {
      final map = {
        'id': '1',
        'modalidadeId': 'm1',
        'status': 'agendada',
        'equipeAId': 'eq-a',
        'equipeBId': 'eq-b',
        'equipeA': {
          'id': 'eq-a',
          'nome': 'Engenharia FC',
          'atleticaId': 'atl-1',
        },
      };
      final partida = Partida.fromMap(map);
      expect(partida.equipeA, isNotNull);
      expect(partida.equipeA?.nome, 'Engenharia FC');
    });

    test(
      'deve carregar equipeA a partir do snapshotSumula quando campo direto ausente',
      () {
        final map = {
          'id': '1',
          'modalidadeId': 'm1',
          'status': 'finalizada',
          'equipeAId': 'eq-a',
          'equipeBId': 'eq-b',
          'snapshotSumula': {
            'equipeA': {
              'id': 'eq-a',
              'nome': 'Medicina FC',
              'atleticaId': 'atl-2',
            },
            'equipeB': {
              'id': 'eq-b',
              'nome': 'Direito SC',
              'atleticaId': 'atl-3',
            },
          },
        };
        final partida = Partida.fromMap(map);
        expect(partida.equipeA?.nome, 'Medicina FC');
        expect(partida.equipeB?.nome, 'Direito SC');
      },
    );

    test('deve carregar modalidade a partir de campo nested "modalidade"', () {
      final map = {
        'id': '1',
        'modalidadeId': 'mod-x',
        'status': 'agendada',
        'equipeAId': 'a',
        'equipeBId': 'b',
        'modalidade': {
          'id': 'mod-x',
          'campeonatoId': 'camp-1',
          'esporteId': 'esp-1',
          'genero': 'Masculino',
          'nome': 'Futsal Masculino',
        },
      };
      final partida = Partida.fromMap(map);
      expect(partida.modalidade, isNotNull);
      expect(partida.modalidade?.esporteNome, 'Futsal Masculino');
    });

    test('não deve lançar exceção com mapa mínimo', () {
      expect(
        () => Partida.fromMap({
          'id': '1',
          'modalidadeId': 'm1',
          'status': 'agendada',
          'equipeAId': 'a',
          'equipeBId': 'b',
        }),
        returnsNormally,
      );
    });
  });

  group('Partida.copyWith', () {
    late Partida base;

    setUp(() {
      base = Partida(
        id: 'p1',
        modalidadeId: 'm1',
        status: 'agendada',
        equipeAId: 'a',
        equipeBId: 'b',
        placarA: 0,
        placarB: 0,
      );
    });

    test('deve preservar todos os campos não alterados', () {
      final copia = base.copyWith(placarA: 3);

      expect(copia.id, base.id);
      expect(copia.modalidadeId, base.modalidadeId);
      expect(copia.status, base.status);
      expect(copia.equipeAId, base.equipeAId);
      expect(copia.equipeBId, base.equipeBId);
      expect(copia.placarA, 3);
      expect(copia.placarB, base.placarB);
    });

    test('deve atualizar status corretamente', () {
      final atualizada = base.copyWith(status: 'em_andamento');
      expect(atualizada.status, 'em_andamento');
      expect(base.status, 'agendada'); // original intacto
    });

    test('deve atualizar equipeA sem alterar equipeB', () {
      final novaEquipe = Equipe(
        id: 'eq-nova',
        nome: 'Nova Equipe',
        atleticaId: 'atl-1',
      );
      final atualizada = base.copyWith(equipeA: novaEquipe);

      expect(atualizada.equipeA?.nome, 'Nova Equipe');
      expect(atualizada.equipeB, isNull);
    });

    test('deve atualizar placar de ambas as equipes', () {
      final atualizada = base.copyWith(placarA: 2, placarB: 1);
      expect(atualizada.placarA, 2);
      expect(atualizada.placarB, 1);
    });
  });
}
