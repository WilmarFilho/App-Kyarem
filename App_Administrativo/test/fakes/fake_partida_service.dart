import 'dart:typed_data';

import 'package:kyarem_eventos/models/partida_model.dart';
import 'package:kyarem_eventos/models/tipo_evento_model.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import 'package:kyarem_eventos/services/partida_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementação fake de [PartidaService] para uso exclusivo em testes de widget.
///
/// Usa o construtor [PartidaService.forTesting()] para garantir que nenhum
/// Timer.periodic é criado e nenhuma operação SQLite ocorre — eliminando
/// completamente o problema de "A Timer is still pending" nos testes.
class FakePartidaService extends PartidaService {
  final SupabaseClient _fakeSupabaseClient = SupabaseClient(
    'https://fake-project.supabase.co',
    'fake-anon-key',
  );

  final List<Partida> partidas;
  final List<TipoEventoEsporte> tiposEvento;
  final List<Map<String, dynamic>> inscritosA;
  final List<Map<String, dynamic>> inscritosB;
  final List<Map<String, dynamic>> eventosPartida;
  final Map<String, dynamic>? ultimoEventoComTempo;
  final Uint8List pdfBytes;
  final (int?, String?) endPartidaResult;
  int startPartidaChamadas = 0;
  final List<Map<String, dynamic>> eventosSalvos = [];
  final List<Map<String, String?>> statusAtualizados = [];
  int endPartidaChamadas = 0;

  FakePartidaService({
    this.partidas = const [],
    this.tiposEvento = const [],
    this.inscritosA = const [],
    this.inscritosB = const [],
    this.eventosPartida = const [],
    this.ultimoEventoComTempo,
    Uint8List? pdfBytes,
    this.endPartidaResult = (200, null),
  }) : pdfBytes = pdfBytes ?? Uint8List(0),
       super.forTesting();

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
  Future<Map<String, dynamic>?> buscarConfiguracaoModalidadeDaPartida(
    String modalidadeId,
  ) async {
    return {
      'id': modalidadeId,
      'nomeExibicao': 'Futsal',
      'esporteNome': 'Futebol',
      'tempoPartidaMinutos': 20,
      'permiteProrrogacao': true,
      'permitePenaltis': true,
    };
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
    String? periodoAntesPausa,
  }) async {
    statusAtualizados.add({
      'partidaId': partidaId,
      'novoStatus': novoStatus,
      'periodoAntesPausa': periodoAntesPausa,
    });
  }

  @override
  Future<void> startPartida(String partidaId) async {
    startPartidaChamadas++;
  }

  @override
  Future<(int?, String?)> endPartida(String partidaId) async {
    endPartidaChamadas++;
    return endPartidaResult;
  }

  @override
  Future<Uint8List> baixarSumulaOficialPdf(String partidaId) async => pdfBytes;

  @override
  RealtimeChannel subscribeRealtimePartida(
    String partidaId, {
    required void Function(Map<String, dynamic> payload) onUpdate,
  }) {
    return _fakeSupabaseClient.channel('fake_partida_$partidaId');
  }

  @override
  RealtimeChannel subscribeRealtimeEventos(
    String partidaId, {
    required void Function(Map<String, dynamic> payload) onInsert,
  }) {
    return _fakeSupabaseClient.channel('fake_eventos_$partidaId');
  }

  @override
  void dispose() {
    // Sem timers para cancelar nem banco para fechar
  }
}
