import 'package:flutter_test/flutter_test.dart';
import 'package:kyarem_eventos/models/campeonato_model.dart';

void main() {
  group('Campeonato.fromMap', () {
    test('deve criar corretamente com todos os campos preenchidos (formato API)', () {
      final map = {
        'id': 'camp-001',
        'nome': 'Copa Universitária',
        'nivelCampeonato': 'Universitário',
        'dataInicio': '2025-03-01T00:00:00.000Z',
        'dataFim': '2025-07-30T00:00:00.000Z',
        'escudoUrl': 'https://example.com/escudo.png',
      };

      final campeonato = Campeonato.fromMap(map);

      expect(campeonato.id, 'camp-001');
      expect(campeonato.nome, 'Copa Universitária');
      expect(campeonato.nivel, 'Universitário');
      expect(campeonato.dataInicio, DateTime.tryParse('2025-03-01T00:00:00.000Z'));
      expect(campeonato.dataFim, DateTime.tryParse('2025-07-30T00:00:00.000Z'));
      expect(campeonato.escudoUrl, 'https://example.com/escudo.png');
    });

    test('deve aceitar chaves no formato snake_case (compatibilidade Supabase)', () {
      final map = {
        'id': 'camp-002',
        'nome': 'Liga de Verão',
        'nivel_campeonato': 'Regional',
        'data_inicio': '2025-01-15T00:00:00.000Z',
        'data_fim': '2025-02-28T00:00:00.000Z',
        'escudo_url': 'https://example.com/logo.png',
      };

      final campeonato = Campeonato.fromMap(map);

      expect(campeonato.nivel, 'Regional');
      expect(campeonato.dataInicio, DateTime.tryParse('2025-01-15T00:00:00.000Z'));
      expect(campeonato.escudoUrl, 'https://example.com/logo.png');
    });

    test('deve retornar valores padrão quando campos opcionais estão ausentes', () {
      final map = {'id': 'camp-003', 'nome': 'Campeonato X'};

      final campeonato = Campeonato.fromMap(map);

      expect(campeonato.id, 'camp-003');
      expect(campeonato.nome, 'Campeonato X');
      expect(campeonato.nivel, isNull);
      expect(campeonato.dataInicio, isNull);
      expect(campeonato.dataFim, isNull);
      expect(campeonato.escudoUrl, isNull);
    });

    test('deve retornar nome padrão "Sem nome" quando nome está ausente', () {
      final map = {'id': 'camp-004'};
      final campeonato = Campeonato.fromMap(map);
      expect(campeonato.nome, 'Sem nome');
    });

    test('deve retornar id vazio quando id está ausente', () {
      final map = {'nome': 'Sem ID'};
      final campeonato = Campeonato.fromMap(map);
      expect(campeonato.id, '');
    });

    test('deve tratar data inválida como null sem lançar exceção', () {
      final map = {
        'id': '1',
        'nome': 'X',
        'dataInicio': 'data-invalida-aqui',
      };

      final campeonato = Campeonato.fromMap(map);
      expect(campeonato.dataInicio, isNull);
    });

    test('não deve lançar exceção com mapa completamente vazio', () {
      expect(() => Campeonato.fromMap({}), returnsNormally);
    });
  });
}
