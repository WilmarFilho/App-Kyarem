import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/partida_model.dart';
import '../models/sumula_model.dart';
import '../models/evento_model.dart';
import 'database_helper.dart';

class PartidaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // 1. CARGA INICIAL: Busca Mocks e popula o Banco Local
  Future<List<Partida>> buscarPartidasDoDia() async {
    print("DEBUG: Iniciando busca de partidas (Mock)...");
    await Future.delayed(const Duration(seconds: 1));

    final mocks = [
      Partida(
        id: '101',
        nomeTimeA: 'Computação',
        nomeTimeB: 'Medicina',
        atletasTimeA: ['João', 'Carlos', 'Beto', 'Erik', 'Vini'],
        atletasTimeB: ['Marcos', 'Zé', 'Luiz', 'Gabriel', 'Davi'],
        dataHora: DateTime.now(),
        sumula: Sumula(id: 's1'),
      ),
      Partida(
        id: '102',
        nomeTimeA: 'Direito',
        nomeTimeB: 'Engenharia',
        atletasTimeA: ['Tavares', 'Hugo', 'Léo'],
        atletasTimeB: ['Bruno', 'Kadu', 'Samu'],
        dataHora: DateTime.now(),
        sumula: Sumula(id: 's2'),
      ),
    ];


    print("DEBUG: Salvando ${mocks.length} partidas no cache local...");
    await _salvarPartidasNoCache(mocks);

    await debugCheckDatabase();
    return mocks;
  }

  Future<void> encerrarPartida(String partidaId) async {
    final db = await _dbHelper.database; //

    await db.update(
      'sumulas_cache',
      {'status': 'encerrada'}, //
      where: 'partida_id = ?',
      whereArgs: [partidaId],
    );

    await debugCheckDatabase();
    print("API JAVA: Partida $partidaId encerrada automaticamente.");
  }

  // 2. INICIAR PARTIDA: Atualiza cache e notifica servidor
  Future<void> iniciarPartida(Partida partida) async {
    final db = await _dbHelper.database;

    // Atualiza status local para 'emAndamento'
    await db.update(
      'sumulas_cache',
      {'status': 'emAndamento'},
      where: 'partida_id = ?',
      whereArgs: [partida.id],
    );

    // TODO: Implementar chamada real via Dio/Http para o seu Backend Java
    await debugCheckDatabase();
    print("API JAVA: Partida ${partida.id} iniciada com sucesso.");
  }

  // 3. REGISTRAR EVENTO: Grava no SQLite e entra na fila de sincronização
  Future<void> registrarEvento({
    required String sumulaId,
    required String atletaNome,
    required String tipo, // 'GOL', 'FALTA', 'AMARELO', 'VERMELHO'
    required String time, // 'A' ou 'B'
  }) async {
    final db = await _dbHelper.database;
    final String eventoId = DateTime.now().millisecondsSinceEpoch.toString();

    // Passo A: Inserir evento no cache com flag de não sincronizado
    await db.insert('eventos_cache', {
      'id': eventoId,
      'sumula_id': sumulaId,
      'atleta_id': atletaNome, // Usando nome como ID no mock
      'tipo': tipo,
      'timestamp': DateTime.now().toIso8601String(),
      'sincronizado': 0,
    });

    // Passo B: Se for GOL, atualiza o placar na tabela de súmulas
    if (tipo == 'GOL') {
      String coluna = (time == 'A') ? 'placar_a' : 'placar_b';
      await db.execute(
        'UPDATE sumulas_cache SET $coluna = $coluna + 1 WHERE id = ?',
        [sumulaId],
      );
    }

    // Passo C: Tentar enviar para o Java em background
    await debugCheckDatabase();
    _sincronizarEventoComServidor(eventoId, sumulaId, atletaNome, tipo);
  }

  // 4. SINCRONIZAÇÃO ASSÍNCRONA (Background)
  Future<void> _sincronizarEventoComServidor(
    String eventoId,
    String sumulaId,
    String atleta,
    String tipo,
  ) async {
    try {
      // Simula tentativa de conexão com o Java
      await Future.delayed(const Duration(seconds: 2));

      final db = await _dbHelper.database;
      await db.update(
        'eventos_cache',
        {'sincronizado': 1},
        where: 'id = ?',
        whereArgs: [eventoId],
      );

      await debugCheckDatabase();
      print("SYNC: Evento $tipo do atleta $atleta enviado ao Java.");
    } catch (e) {
      print(
        "SYNC ERROR: Falha ao enviar para o Java. O evento $eventoId permanece no cache.",
      );
    }
  }

  Future<List<Evento>> buscarEventosDaSumula(String sumulaId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'eventos_cache',
      where: 'sumula_id = ?',
      whereArgs: [sumulaId],
      orderBy: 'timestamp DESC', // Mostra os lances mais recentes primeiro
    );

    return List.generate(maps.length, (i) => Evento.fromMap(maps[i]));
  }

  Future<void> debugCheckDatabase() async {
    final db = await _dbHelper.database;

    // Verifica Súmulas
    final sumulas = await db.query('sumulas_cache');
    print('--- DEBUG BANCO: SÚMULAS ---');
    for (var row in sumulas) {
      print(
        'ID: ${row['id']} | Placar: ${row['placar_a']}x${row['placar_b']} | Status: ${row['status']}',
      );
    }


    // Verifica Eventos
    final eventos = await db.query('eventos_cache');
    print('--- DEBUG BANCO: EVENTOS ---');
    for (var row in eventos) {
      print(
        'Tipo: ${row['tipo']} | Atleta: ${row['atleta_id']} | Sincronizado: ${row['sincronizado']}',
      );
    }
  }

  // 5. AUXILIARES DE PERSISTÊNCIA
  Future<Map<String, dynamic>?> buscarSumulaCache(String partidaId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sumulas_cache',
      where: 'partida_id = ?',
      whereArgs: [partidaId],
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<void> _salvarPartidasNoCache(List<Partida> partidas) async {
    final db = await _dbHelper.database;

    for (var p in partidas) {
      // Salva dados estruturais da partida
      await db.insert('partidas_cache', {
        'id': p.id,
        'nomeTimeA': p.nomeTimeA,
        'nomeTimeB': p.nomeTimeB,
        'status': p.sumula.status.name,
        'dados_completos_json': jsonEncode(p.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Salva o estado atual da súmula (placar/status)
      await db.insert('sumulas_cache', {
        'id': p.sumula.id,
        'partida_id': p.id,
        'placar_a': p.sumula.placarTimeA,
        'placar_b': p.sumula.placarTimeB,
        'status': p.sumula.status.name,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}
