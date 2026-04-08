import 'package:flutter_test/flutter_test.dart';
import 'package:kyarem_eventos/models/arbitro_model.dart';

void main() {
  group('Arbitro.fromMap', () {
    test('deve criar árbitro corretamente com todos os campos', () {
      final map = {
        'id': 'arb-001',
        'nomeExibicao': 'João Silva',
        'fotoUrl': 'https://example.com/foto.jpg',
        'telefone': '(11) 99999-0000',
      };

      final arbitro = Arbitro.fromMap(map);

      expect(arbitro.id, 'arb-001');
      expect(arbitro.nome, 'João Silva');
      expect(arbitro.fotoUrl, 'https://example.com/foto.jpg');
      expect(arbitro.telefone, '(11) 99999-0000');
    });

    test('deve usar campo "nome" quando "nomeExibicao" está ausente', () {
      final map = {'id': 'arb-002', 'nome': 'Maria Souza'};
      final arbitro = Arbitro.fromMap(map);
      expect(arbitro.nome, 'Maria Souza');
    });

    test('deve priorizar "nomeExibicao" sobre "nome"', () {
      final map = {
        'id': 'arb-003',
        'nome': 'Nome Comum',
        'nomeExibicao': 'Nome de Exibição',
      };
      final arbitro = Arbitro.fromMap(map);
      expect(arbitro.nome, 'Nome de Exibição');
    });

    test('deve usar "Sem nome" como padrão quando ambos ausentes', () {
      final map = {'id': 'arb-004'};
      final arbitro = Arbitro.fromMap(map);
      expect(arbitro.nome, 'Sem nome');
    });

    test('deve aceitar foto_url no formato snake_case', () {
      final map = {
        'id': 'arb-005',
        'nome': 'Carlos',
        'foto_url': 'https://example.com/carlos.jpg',
      };
      final arbitro = Arbitro.fromMap(map);
      expect(arbitro.fotoUrl, 'https://example.com/carlos.jpg');
    });

    test('deve retornar campos opcionais como null quando ausentes', () {
      final map = {'id': 'arb-006', 'nome': 'Ana'};
      final arbitro = Arbitro.fromMap(map);
      expect(arbitro.fotoUrl, isNull);
      expect(arbitro.telefone, isNull);
    });

    test('id deve ser string mesmo quando vem como tipo diferente', () {
      final map = {'id': 42, 'nome': 'Pedro'};
      final arbitro = Arbitro.fromMap(map);
      expect(arbitro.id, '42');
    });

    test('não deve lançar exceção com mapa vazio', () {
      expect(() => Arbitro.fromMap({}), returnsNormally);
    });
  });

  group('PartidaDoArbitro.fromMap', () {
    Map<String, dynamic> _mapCompleto() => {
          'vinculoId': 'vinc-001',
          'funcao': 'Árbitro Principal',
          'vinculadoEm': '2025-04-01T10:00:00.000Z',
          'partidaId': 'part-001',
          'status': 'agendada',
          'agendadaPara': '2025-05-10T15:00:00.000Z',
          'iniciadaEm': '2025-05-10T15:05:00.000Z',
          'encerradaEm': '2025-05-10T16:20:00.000Z',
          'local': 'Ginásio Central',
          'fase': 'Semifinal',
          'categoria': 'Sub-23',
          'placarA': 3,
          'placarB': 1,
          'equipeANome': 'Engenharia FC',
          'equipeBNome': 'Medicina RC',
          'modalidadeNome': 'Futsal Masculino',
        };

    test('deve criar PartidaDoArbitro com todos os campos', () {
      final pda = PartidaDoArbitro.fromMap(_mapCompleto());

      expect(pda.vinculoId, 'vinc-001');
      expect(pda.funcao, 'Árbitro Principal');
      expect(pda.partidaId, 'part-001');
      expect(pda.status, 'agendada');
      expect(pda.local, 'Ginásio Central');
      expect(pda.placarA, 3);
      expect(pda.placarB, 1);
      expect(pda.equipeANome, 'Engenharia FC');
      expect(pda.equipeBNome, 'Medicina RC');
      expect(pda.modalidadeNome, 'Futsal Masculino');
    });

    test('deve parsear datas corretamente', () {
      final pda = PartidaDoArbitro.fromMap(_mapCompleto());
      expect(pda.vinculadoEm, DateTime.tryParse('2025-04-01T10:00:00.000Z'));
      expect(pda.agendadaPara, DateTime.tryParse('2025-05-10T15:00:00.000Z'));
      expect(pda.iniciadaEm, DateTime.tryParse('2025-05-10T15:05:00.000Z'));
      expect(pda.encerradaEm, DateTime.tryParse('2025-05-10T16:20:00.000Z'));
    });

    test('deve retornar placar zero quando não informado', () {
      final map = {
        'vinculoId': 'v1',
        'funcao': 'Mesário',
        'partidaId': 'p1',
        'status': 'agendada',
      };
      final pda = PartidaDoArbitro.fromMap(map);
      expect(pda.placarA, 0);
      expect(pda.placarB, 0);
    });
  });

  group('PartidaDoArbitro.isAtiva / isEncerrada', () {
    PartidaDoArbitro _criarComStatus(String status) => PartidaDoArbitro(
          vinculoId: 'v1',
          funcao: 'Árbitro Principal',
          partidaId: 'p1',
          status: status,
        );

    test('"agendada" deve ser considerada ativa', () {
      final p = _criarComStatus('agendada');
      expect(p.isAtiva, isTrue);
      expect(p.isEncerrada, isFalse);
    });

    test('"em_andamento" deve ser considerada ativa', () {
      final p = _criarComStatus('em_andamento');
      expect(p.isAtiva, isTrue);
    });

    test('"finalizada" deve ser considerada encerrada', () {
      final p = _criarComStatus('finalizada');
      expect(p.isAtiva, isFalse);
      expect(p.isEncerrada, isTrue);
    });

    test('"fechada" deve ser considerada encerrada', () {
      final p = _criarComStatus('fechada');
      expect(p.isAtiva, isFalse);
      expect(p.isEncerrada, isTrue);
    });

    test('status com letras maiúsculas "Finalizada" deve ser encerrada (case-insensitive)', () {
      final p = _criarComStatus('Finalizada');
      expect(p.isAtiva, isFalse);
    });

    test('"FECHADA" maiúsculo deve ser considerado encerrado', () {
      final p = _criarComStatus('FECHADA');
      expect(p.isEncerrada, isTrue);
    });
  });
}
