import 'package:kyarem_eventos/models/campeonato_model.dart';
import 'package:kyarem_eventos/models/arbitro_model.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import 'package:kyarem_eventos/services/admin_api_service.dart';

/// Implementação fake de [AdminApiService] para uso exclusivo em testes de widget.
/// Retorna listas vazias por padrão. Use campos nomeados para pré-popular.
class FakeAdminApiService extends AdminApiService {
  final List<Campeonato> campeonatos;
  final List<Arbitro> arbitros;
  final List<Atletica> atleticas;
  final List<Equipe> equipes;
  final String? atleticaDoPresidenteId;

  FakeAdminApiService({
    this.campeonatos = const [],
    this.arbitros = const [],
    this.atleticas = const [],
    this.equipes = const [],
    this.atleticaDoPresidenteId,
  });

  // ---- Campeonatos ----
  @override
  Future<List<Campeonato>> listarCampeonatos() async => campeonatos;

  @override
  Future<bool> excluirCampeonato(String id) async => true;

  @override
  Future<Campeonato?> criarCampeonato(Map<String, dynamic> data) async =>
      campeonatos.isEmpty ? null : campeonatos.first;

  @override
  Future<Campeonato?> atualizarCampeonato(
    String id,
    Map<String, dynamic> data,
  ) async =>
      campeonatos.isEmpty ? null : campeonatos.first;

  // ---- Árbitros ----
  @override
  Future<List<Arbitro>> listarArbitros() async => arbitros;

  // ---- Atléticas ----
  @override
  Future<List<Atletica>> listarAtleticas() async => atleticas;

  @override
  Future<Atletica?> buscarAtletica(String id) async =>
      atleticas.isEmpty ? null : atleticas.first;

  @override
  Future<bool> excluirAtletica(String id) async => true;

  // ---- Equipes ----
  @override
  Future<List<Equipe>> listarEquipes({
    String? campeonatoId,
    String? modalidadeId,
    String? atleticaId,
  }) async => equipes;

  @override
  Future<bool> excluirEquipe(String id) async => true;

  // ---- Partidas ----
  @override
  Future<bool> excluirPartida(String id) async => true;

  // ---- Atlética do Presidente ----
  @override
  Future<String?> buscarAtleticaDoPresidente(String userId) async =>
      atleticaDoPresidenteId;
}
