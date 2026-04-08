import 'package:flutter_test/flutter_test.dart';
import 'package:kyarem_eventos/models/atleta_model.dart';

void main() {
  group('Atleta.fromMap', () {
    test('deve criar atleta com todos os campos preenchidos', () {
      final map = {
        'id': 'inscricao-001',
        'atletaId': 'atleta-001',
        'equipeId': 'eq-001',
        'atleticaId': 'atl-001',
        'atletaNome': 'Carlos Eduardo',
        'numeroCamisa': 10,
        'ativo': true,
        'documentoIdentificacao': '123.456.789-00',
        'curso': 'Engenharia Civil',
        'fotoUrl': 'https://example.com/carlos.jpg',
      };

      final atleta = Atleta.fromMap(map);

      expect(atleta.id, 'inscricao-001');
      expect(atleta.atletaId, 'atleta-001');
      expect(atleta.equipeId, 'eq-001');
      expect(atleta.atleticaId, 'atl-001');
      expect(atleta.nome, 'Carlos Eduardo');
      expect(atleta.numero, 10);
      expect(atleta.ativo, isTrue);
      expect(atleta.documentoIdentificacao, '123.456.789-00');
      expect(atleta.curso, 'Engenharia Civil');
      expect(atleta.fotoUrl, 'https://example.com/carlos.jpg');
    });

    test('deve usar campo "nome" quando "atletaNome" está ausente', () {
      final map = {
        'id': 'ins-002',
        'nome': 'Ana Beatriz',
      };
      final atleta = Atleta.fromMap(map);
      expect(atleta.nome, 'Ana Beatriz');
    });

    test('deve priorizar "atletaNome" sobre "nome"', () {
      final map = {
        'id': 'ins-003',
        'nome': 'Nome Genérico',
        'atletaNome': 'Nome de Atleta',
      };
      final atleta = Atleta.fromMap(map);
      expect(atleta.nome, 'Nome de Atleta');
    });

    test('deve usar "Sem Nome" como padrão quando ambos os nomes estão ausentes', () {
      final map = {'id': 'ins-004'};
      final atleta = Atleta.fromMap(map);
      expect(atleta.nome, 'Sem Nome');
    });

    test('deve usar "id" como atletaId quando "atletaId" está ausente', () {
      final map = {'id': 'ins-005', 'nome': 'Pedro'};
      final atleta = Atleta.fromMap(map);
      expect(atleta.atletaId, 'ins-005');
    });

    test('deve retornar campos opcionais como null quando ausentes', () {
      final map = {'id': 'ins-006', 'nome': 'Lucas'};
      final atleta = Atleta.fromMap(map);

      expect(atleta.equipeId, isNull);
      expect(atleta.atleticaId, isNull);
      expect(atleta.numero, isNull);
      expect(atleta.ativo, isNull);
      expect(atleta.documentoIdentificacao, isNull);
      expect(atleta.curso, isNull);
      expect(atleta.fotoUrl, isNull);
    });

    test('não deve lançar exceção com mapa completamente vazio', () {
      expect(() => Atleta.fromMap({}), returnsNormally);
    });

    test('posicao e corTime devem ser null por padrão (campos runtime)', () {
      final map = {'id': 'ins-007', 'nome': 'Mariana'};
      final atleta = Atleta.fromMap(map);
      expect(atleta.posicao, isNull);
      expect(atleta.corTime, isNull);
    });
  });
}
