import 'package:flutter_test/flutter_test.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';

void main() {
  group('Atletica.fromMap', () {
    test('deve criar corretamente com formato API (camelCase)', () {
      final map = {
        'id': 'atl-001',
        'nome': 'Atlética de Engenharia',
        'sigla': 'AEng',
        'escudoUrl': 'https://example.com/escudo.png',
        'corPrincipal': '#FF5500',
        'presidenteId': 'user-001',
      };

      final atletica = Atletica.fromMap(map);

      expect(atletica.id, 'atl-001');
      expect(atletica.nome, 'Atlética de Engenharia');
      expect(atletica.sigla, 'AEng');
      expect(atletica.escudoUrl, 'https://example.com/escudo.png');
      expect(atletica.corPrincipal, '#FF5500');
      expect(atletica.presidenteId, 'user-001');
    });

    test('deve aceitar formato snake_case (compatibilidade Supabase)', () {
      final map = {
        'id': 'atl-002',
        'nome': 'Atlética de Medicina',
        'escudo_url': 'https://example.com/med.png',
        'cor_principal': '#00AA44',
        'presidente_id': 'user-002',
      };

      final atletica = Atletica.fromMap(map);

      expect(atletica.escudoUrl, 'https://example.com/med.png');
      expect(atletica.corPrincipal, '#00AA44');
      expect(atletica.presidenteId, 'user-002');
    });

    test('deve retornar campos opcionais como null quando ausentes', () {
      final map = {'id': 'atl-003', 'nome': 'Atlética X'};
      final atletica = Atletica.fromMap(map);

      expect(atletica.sigla, isNull);
      expect(atletica.escudoUrl, isNull);
      expect(atletica.corPrincipal, isNull);
      expect(atletica.presidenteId, isNull);
    });

    test('não deve lançar exceção com mapa vazio', () {
      expect(() => Atletica.fromMap({}), returnsNormally);
    });
  });

  group('Equipe.fromMap', () {
    test('deve criar equipe com campos básicos', () {
      final map = {
        'id': 'eq-001',
        'nome': 'Engenharia FC',
        'atleticaId': 'atl-001',
      };

      final equipe = Equipe.fromMap(map);

      expect(equipe.id, 'eq-001');
      expect(equipe.nome, 'Engenharia FC');
      expect(equipe.atleticaId, 'atl-001');
    });

    test('deve aceitar nomeEquipe como alias de nome', () {
      final map = {
        'id': 'eq-002',
        'nomeEquipe': 'Medicina RC',
        'atleticaId': 'atl-002',
      };

      final equipe = Equipe.fromMap(map);
      expect(equipe.nome, 'Medicina RC');
    });

    test('deve aceitar nome_equipe no formato snake_case', () {
      final map = {
        'id': 'eq-003',
        'nome_equipe': 'Direito SC',
        'atleticaId': 'atl-003',
      };

      final equipe = Equipe.fromMap(map);
      expect(equipe.nome, 'Direito SC');
    });

    test('deve usar "Time Desconhecido" como nome padrão quando ausente', () {
      final map = {'id': 'eq-004', 'atleticaId': 'atl-004'};
      final equipe = Equipe.fromMap(map);
      expect(equipe.nome, 'Time Desconhecido');
    });

    test('deve extrair atleticaId de atletica nested quando ausente no root', () {
      final map = {
        'id': 'eq-005',
        'nome': 'Bio SC',
        'atletica': {'id': 'atl-via-nested', 'nome': 'Atlética Bio'},
      };

      final equipe = Equipe.fromMap(map);
      expect(equipe.atleticaId, 'atl-via-nested');
    });

    test('deve extrair escudo de atletica nested', () {
      final map = {
        'id': 'eq-006',
        'nome': 'Quim FC',
        'atleticaId': 'atl-006',
        'atletica': {
          'id': 'atl-006',
          'nome': 'Atlética Química',
          'escudoUrl': 'https://example.com/quim.png',
        },
      };

      final equipe = Equipe.fromMap(map);
      expect(equipe.atleticaEscudoUrl, 'https://example.com/quim.png');
    });

    test('deve aceitar atleticaEscudoUrl direto no root', () {
      final map = {
        'id': 'eq-007',
        'nome': 'Fis SC',
        'atleticaId': 'atl-007',
        'atleticaEscudoUrl': 'https://example.com/fis.png',
      };

      final equipe = Equipe.fromMap(map);
      expect(equipe.atleticaEscudoUrl, 'https://example.com/fis.png');
    });

    test('deve criar objeto Atletica aninhado com dados disponíveis', () {
      final map = {
        'id': 'eq-008',
        'nome': 'Let FC',
        'atleticaId': 'atl-008',
        'atleticaNome': 'Atlética de Letras',
        'atleticaEscudoUrl': 'https://example.com/let.png',
      };

      final equipe = Equipe.fromMap(map);
      expect(equipe.atletica, isNotNull);
      expect(equipe.atletica?.nome, 'Atlética de Letras');
      expect(equipe.atletica?.escudoUrl, 'https://example.com/let.png');
    });

    test('não deve lançar exceção com mapa mínimo', () {
      expect(
        () => Equipe.fromMap({'id': 'eq-min', 'atleticaId': 'atl-min'}),
        returnsNormally,
      );
    });
  });
}
