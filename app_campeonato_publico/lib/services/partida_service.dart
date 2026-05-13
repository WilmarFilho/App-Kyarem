import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kyarem_eventos_publico/models/atletica_equipe_model.dart';
import 'package:kyarem_eventos_publico/models/partida_model.dart';
import 'package:kyarem_eventos_publico/core/app_globals.dart';

class PartidaService {
  final _supabase = Supabase.instance.client;

  static List<Partida>? _cachedFinishedMatches;
  static DateTime? _lastFinishedMatchesTime;

  Future<Map<String, String>> _getAthleticsShieldMap() async {
    final campId = AppGlobals.campeonatoAtivo?.id;
    if (campId == null || campId.isEmpty) return {};

    final res = await _supabase
        .from('campeonato_atleticas_publicos')
        .select('atletica_id, atletica_escudo_url')
        .eq('campeonato_id', campId);

    final map = <String, String>{};
    for (final item in (res as List)) {
      final row = Map<String, dynamic>.from(item);
      final atleticaId = row['atletica_id']?.toString() ?? '';
      final escudoUrl = row['atletica_escudo_url']?.toString() ?? '';
      if (atleticaId.isNotEmpty && escudoUrl.isNotEmpty) {
        map[atleticaId] = escudoUrl;
      }
    }

    return map;
  }

  List<Partida> _applyAthleticsShields(
    List<Partida> partidas,
    Map<String, String> escudosPorAtletica,
  ) {
    if (escudosPorAtletica.isEmpty) return partidas;

    return partidas.map((partida) {
      final equipeA = partida.equipeA;
      final equipeB = partida.equipeB;

      final escudoA =
          equipeA?.atleticaId.isNotEmpty == true
              ? escudosPorAtletica[equipeA!.atleticaId]
              : null;
      final escudoB =
          equipeB?.atleticaId.isNotEmpty == true
              ? escudosPorAtletica[equipeB!.atleticaId]
              : null;

      return Partida(
        id: partida.id,
        modalidadeId: partida.modalidadeId,
        status: partida.status,
        placarA: partida.placarA,
        placarB: partida.placarB,
        local: partida.local,
        iniciadaEm: partida.iniciadaEm,
        agendadoPara: partida.agendadoPara,
        equipeA: equipeA == null
            ? null
            : Equipe(
                id: equipeA.id,
                nome: equipeA.nome,
                atleticaId: equipeA.atleticaId,
                atleticaNome: equipeA.atleticaNome,
                atleticaEscudoUrl: escudoA ?? equipeA.atleticaEscudoUrl,
                campeonatoId: equipeA.campeonatoId,
                campeonatoNome: equipeA.campeonatoNome,
                modalidadeId: equipeA.modalidadeId,
                modalidadeNome: equipeA.modalidadeNome,
                atletica: equipeA.atletica == null
                    ? null
                    : Atletica(
                        id: equipeA.atletica!.id,
                        nome: equipeA.atletica!.nome,
                        sigla: equipeA.atletica!.sigla,
                        escudoUrl: escudoA ?? equipeA.atletica!.escudoUrl,
                        corPrincipal: equipeA.atletica!.corPrincipal,
                        presidenteId: equipeA.atletica!.presidenteId,
                      ),
              ),
        equipeB: equipeB == null
            ? null
            : Equipe(
                id: equipeB.id,
                nome: equipeB.nome,
                atleticaId: equipeB.atleticaId,
                atleticaNome: equipeB.atleticaNome,
                atleticaEscudoUrl: escudoB ?? equipeB.atleticaEscudoUrl,
                campeonatoId: equipeB.campeonatoId,
                campeonatoNome: equipeB.campeonatoNome,
                modalidadeId: equipeB.modalidadeId,
                modalidadeNome: equipeB.modalidadeNome,
                atletica: equipeB.atletica == null
                    ? null
                    : Atletica(
                        id: equipeB.atletica!.id,
                        nome: equipeB.atletica!.nome,
                        sigla: equipeB.atletica!.sigla,
                        escudoUrl: escudoB ?? equipeB.atletica!.escudoUrl,
                        corPrincipal: equipeB.atletica!.corPrincipal,
                        presidenteId: equipeB.atletica!.presidenteId,
                      ),
              ),
      );
    }).toList();
  }

  Future<List<Partida>> getMatchesByModalityAndStatus({
    required String modalityId,
    String status = 'all',
  }) async {
    try {
      List<Partida> allMatches = [];

      // Se não for especificamente finalizadas_e_fechadas, busca nas ao_vivo
      if (status != 'finalizadas_e_fechadas') {
        var queryAoVivo = _supabase.from('partidas_ao_vivo').select('*');
        queryAoVivo = queryAoVivo.eq('campeonato_modalidade_id', modalityId);
        
        if (status != 'all' && status != 'finalizadas_e_fechadas') {
            queryAoVivo = queryAoVivo.eq('status', status);
        }

        final resAoVivo = await queryAoVivo.order('agendado_para', ascending: true);
        allMatches.addAll((resAoVivo as List).map((json) => Partida.fromMap(json)));
      }

      // Se for all ou especificamente finalizadas_e_fechadas, busca no historico
      if (status == 'all' || status == 'finalizadas_e_fechadas') {
        var queryHist = _supabase.from('partidas_historico').select('*');
        queryHist = queryHist.eq('campeonato_modalidade_id', modalityId);

        if (status == 'finalizadas_e_fechadas') {
           // O historico já tem finalizadas e fechadas
        }

        final resHist = await queryHist.order('iniciada_em', ascending: false);
        allMatches.addAll((resHist as List).map((json) => Partida.fromMap(json)));
      }

      final escudosPorAtletica = await _getAthleticsShieldMap();
      return _applyAthleticsShields(allMatches, escudosPorAtletica);
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao buscar partidas: $e');
      return [];
    }
  }

  Future<List<Partida>> getActiveMatches() async {
    try {
      var query = _supabase
          .from('partidas_ao_vivo')
          .select('*')
          .neq('status', 'agendada')
          .neq('status', 'finalizada')
          .neq('status', 'fechada');

      // Filtra pelo campeonato ativo configurado no .env
      final campId = AppGlobals.campeonatoAtivo?.id;
      if (campId != null && campId.isNotEmpty) {
        query = query.eq('campeonato_id', campId);
      }

      final response = await query.order('partida_id', ascending: false);
      final partidas = (response as List)
          .map((json) => Partida.fromMap(json))
          .toList();
      final escudosPorAtletica = await _getAthleticsShieldMap();
      return _applyAthleticsShields(partidas, escudosPorAtletica);
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao buscar destaques: $e');
      return [];
    }
  }

  Future<List<Partida>> getFinishedMatches({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedFinishedMatches != null &&
        _lastFinishedMatchesTime != null) {
      if (DateTime.now().difference(_lastFinishedMatchesTime!).inMinutes < 5) {
        return _cachedFinishedMatches!;
      }
    }

    try {
      var query = _supabase
          .from('partidas_historico')
          .select('*');

      // Filtra pelo campeonato ativo configurado no .env
      final campId = AppGlobals.campeonatoAtivo?.id;
      if (campId != null && campId.isNotEmpty) {
        query = query.eq('campeonato_id', campId);
      }

      final response = await query
          .order('encerrada_em', ascending: false)
          .limit(4);

      final partidas = (response as List)
          .map((json) => Partida.fromMap(json))
          .toList();
      final escudosPorAtletica = await _getAthleticsShieldMap();
      _cachedFinishedMatches = _applyAthleticsShields(
        partidas,
        escudosPorAtletica,
      );
      _lastFinishedMatchesTime = DateTime.now();

      return _cachedFinishedMatches!;
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao buscar histórico: $e');
      return [];
    }
  }
}
