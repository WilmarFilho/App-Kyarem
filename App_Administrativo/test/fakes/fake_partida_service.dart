import 'package:kyarem_eventos/models/partida_model.dart';
import 'package:kyarem_eventos/models/tipo_evento_model.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import 'package:kyarem_eventos/services/partida_service.dart';

/// Implementação fake de [PartidaService] para uso exclusivo em testes de widget.
///
/// Usa o construtor [PartidaService.forTesting()] para garantir que nenhum
/// Timer.periodic é criado e nenhuma operação SQLite ocorre — eliminando
/// completamente o problema de "A Timer is still pending" nos testes.
class FakePartidaService extends PartidaService {
  final List<Partida> partidas;
  final List<TipoEventoEsporte> tiposEvento;
  final List<Map<String, dynamic>> inscritosA;
  final List<Map<String, dynamic>> inscritosB;
  final List<Map<String, dynamic>> eventosPartida;
  final Map<String, dynamic>? ultimoEventoComTempo;
  int startPartidaChamadas = 0;
  final List<Map<String, dynamic>> eventosSalvos = [];
  final List<Map<String, String?>> statusAtualizados = [];

  FakePartidaService({
    this.partidas = const [],
    this.tiposEvento = const [],
    this.inscritosA = const [],
    this.inscritosB = const [],
    this.eventosPartida = const [],
    this.ultimoEventoComTempo,
  }) : super.forTesting();

  @override
  Future<List<Partida>> listarTodasPartidas() async => partidas;

  @override
  Future<List<Partida>> listarPartidasMinhas() async => partidas;

  @override
  Future<List<dynamic>> buscarDadosPorAba(String aba) async => [];

  @override
  Future<Partida?> buscarPartidaPorId(String id) async {
    return partidas.isEmpty ? null : partidas.firstWhere((p) => p.id == id, orElse: () => partidas.first);
  }

  @override
  Future<Partida> carregarEquipesDaPartida(Partida partida) async {
    return partida.copyWith(
      equipeA: Equipe(id: partida.equipeAId, nome: 'Equipe A', atleticaId: '1'),
      equipeB: Equipe(id: partida.equipeBId, nome: 'Equipe B', atleticaId: '2'),
    );
  }

  @override
  Future<List<TipoEventoEsporte>> buscarTiposDeEventoDaPartida(String modalidadeId) async => tiposEvento;

  @override
  Future<List<dynamic>> buscarInscritos(String equipeId) async {
    if (equipeId.contains('a') || equipeId.contains('A')) return inscritosA;
    if (equipeId.contains('b') || equipeId.contains('B')) return inscritosB;
    return inscritosA; // fallback
  }

  @override
  Future<List<Map<String, dynamic>>> buscarEventosDaPartida(String partidaId) async => eventosPartida;

  @override
  Future<Map<String, dynamic>?> buscarUltimoEventoComTempo(String partidaId) async {
    if (ultimoEventoComTempo != null) return ultimoEventoComTempo;
    if (eventosPartida.isEmpty) return null;
    return eventosPartida.last;
  }

  @override
  Future<void> salvarEvento({
    required String partidaId,
    required String tipoEventoId,
    String? equipeId,
    String? atletaId,
    String? atletaSaiId,
    required String tempoFormatado,
    String? descricao,
    bool isSubstitution = false,
  }) async {
    eventosSalvos.add({
      'partidaId': partidaId,
      'tipoEventoId': tipoEventoId,
      'equipeId': equipeId,
      'atletaId': atletaId,
      'atletaSaiId': atletaSaiId,
      'tempoFormatado': tempoFormatado,
      'descricao': descricao,
      'isSubstitution': isSubstitution.toString(),
    });
  }

  @override
  Future<void> atualizarPartida(
    String partidaId, {
    String? novoStatus,
    String? statusAntesPausa,
  }) async {
    statusAtualizados.add({
      'partidaId': partidaId,
      'novoStatus': novoStatus,
      'statusAntesPausa': statusAntesPausa,
    });
  }

  @override
  Future<void> startPartida(String partidaId) async {
    startPartidaChamadas++;
  }

  @override
  void dispose() {
    // Sem timers para cancelar nem banco para fechar
  }
}
