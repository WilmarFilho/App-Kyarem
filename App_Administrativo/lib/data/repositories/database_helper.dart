import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sgeu_cache.db');
    return await openDatabase(
      path,
      version: 1,
      // ESTE PASSO É ESSENCIAL: Ativa o suporte a Foreign Keys
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        // Tabela de Partidas (Cache de Identificação)
        await db.execute('''
          CREATE TABLE partidas_cache (
            id TEXT PRIMARY KEY,
            nomeTimeA TEXT,
            nomeTimeB TEXT,
            status TEXT,
            dados_completos_json TEXT
          )
        ''');

        // Tabela de Súmulas (Estado do Jogo)
        await db.execute('''
          CREATE TABLE sumulas_cache (
            id TEXT PRIMARY KEY,
            partida_id TEXT,
            placar_a INTEGER DEFAULT 0,
            placar_b INTEGER DEFAULT 0,
            status TEXT,
            FOREIGN KEY (partida_id) REFERENCES partidas_cache (id) ON DELETE CASCADE
          )
        ''');

        // Tabela de Eventos (Histórico para imutabilidade e sincronia)
        await db.execute('''
          CREATE TABLE eventos_cache (
            id TEXT PRIMARY KEY,
            sumula_id TEXT,
            atleta_id TEXT,
            tipo TEXT, -- 'GOL', 'FALTA', 'AMARELO', 'VERMELHO'
            time TEXT, -- Adicionado para facilitar saber qual placar incrementar ('A' ou 'B')
            timestamp TEXT,
            sincronizado INTEGER DEFAULT 0, -- 0 = Pendente, 1 = Na API Java
            FOREIGN KEY (sumula_id) REFERENCES sumulas_cache (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }
}