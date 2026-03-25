import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kyarem_eventos_publico/models/partida_model.dart';

class PartidaService {
  final _supabase = Supabase.instance.client;

  /// Busca partidas em destaque (em andamento)
  ///
  /// Observação: No back-end o status "em andamento" é qualquer status válido
  /// diferente de "agendada" e "finalizada".
  Future<List<Partida>> listarPartidasDestaque() async {
    try {
      final response = await _supabase
          .from('partidas')
          .select('''
            *,
            equipe_a:equipes!partidas_equipe_a_id_fkey(*, atleticas(*)),
            equipe_b:equipes!partidas_equipe_b_id_fkey(*, atleticas(*))
          ''')
          .neq('status', 'agendada')
          .neq('status', 'finalizada')
          .order('iniciada_em', ascending: false);

      return (response as List).map((json) => Partida.fromMap(json)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao buscar destaques: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> listarModalidades(
    String campeonatoId,
  ) async {
    final res = await Supabase.instance.client
        .from('modalidades')
        .select('nome')
        .eq('campeonato_id', campeonatoId);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> buscarTopAtletas(
    String nomeTipoEvento,
  ) async {
    try {
      // 1. Busca o ID do tipo de evento
      final tipoEventoRes = await _supabase
          .from('tipos_eventos')
          .select('id')
          .ilike('nome', '%$nomeTipoEvento%')
          .maybeSingle();

      if (tipoEventoRes == null) return [];
      final tipoId = tipoEventoRes['id'];

      // 2. Busca eventos com a Foreign Key EXPLÍCITA
      final List<dynamic> res = await _supabase
          .from('eventos_partida')
          .select('''
          atleta_id,
          atleta:atletas!eventos_partida_atleta_id_fkey (
            nome,
            foto_url,
            atleticas ( nome )
          )
        ''')
          .eq('tipo_evento_id', tipoId);

      if (res.isEmpty) return [];

      // 3. Agrupamento e Contagem
      Map<String, int> contagem = {};
      Map<String, dynamic> infoAtleta = {};

      for (var item in res) {
        final dadosDoAtleta = item['atleta'];
        if (dadosDoAtleta == null) continue;

        String id = item['atleta_id'].toString();
        contagem[id] = (contagem[id] ?? 0) + 1;
        infoAtleta[id] = dadosDoAtleta;
      }

      // 4. Ordenação (Do maior para o menor)
      var sortedKeys = contagem.keys.toList()
        ..sort((a, b) => contagem[b]!.compareTo(contagem[a]!));

      // 5. Retorno apenas do MELHOR (Top 1)
      if (sortedKeys.isEmpty) return [];

      final idLider = sortedKeys.first;
      final atleta = infoAtleta[idLider];

      String modalidadeNome = "Geral";
      if (atleta['atleticas'] != null) {
        modalidadeNome = atleta['atleticas']['nome'];
      }

      return [
        {
          'nome': atleta['nome'] ?? 'Atleta',
          'modalidade': modalidadeNome,
          'valor': contagem[idLider].toString(),
          'label': nomeTipoEvento.toUpperCase() == 'GOL' ? 'GOL' : 'PONTO',
          'foto': atleta['foto_url'],
        },
      ];
    } catch (e) {
      debugPrint('ERRO NO SERVICE: $e');
      return [];
    }
  }

  /// Busca todas as partidas finalizadas (Histórico)
  Future<List<Partida>> listarHistoricoPartidas() async {
    try {
      final response = await _supabase
          .from('partidas')
          .select('''
            *,
            equipe_a:equipes!partidas_equipe_a_id_fkey(*, atleticas(*)),
            equipe_b:equipes!partidas_equipe_b_id_fkey(*, atleticas(*))
          ''')
          .eq('status', 'finalizada')
          .order('encerrada_em', ascending: false);

      return (response as List).map((json) => Partida.fromMap(json)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao buscar histórico: $e');
      return [];
    }
  }
}
