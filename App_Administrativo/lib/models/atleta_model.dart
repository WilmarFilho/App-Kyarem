import 'package:flutter/material.dart';

class Atleta {
  final String id;
  final String atletaId;
  final String? equipeId;
  final String? atleticaId;
  final String nome;
  final int? numero;
  final bool? ativo;
  final String? documentoIdentificacao;
  final String? curso;
  final String? fotoUrl;
  final dynamic atletica; // Tipagem frouxa ou Atletica para evitar complicação de import circular

  // Campos que não vem da API
  Offset? posicao;
  Color? corTime;

  Atleta({
    required this.id,
    required this.atletaId,
    this.equipeId,
    this.atleticaId,
    required this.nome,
    this.numero,
    this.ativo,
    this.documentoIdentificacao,
    this.curso,
    this.fotoUrl,
    this.atletica,
    this.posicao,
    this.corTime,
  });

  factory Atleta.fromMap(Map<String, dynamic> map) {
    final status = (map['status'] ?? '').toString().toUpperCase();
    final numeroCamisa = map['numeroCamisa'] ?? map['numero_camisa'] ?? map['numero'];
    return Atleta(
      id: (map['id'] ?? '').toString(),
      equipeId: (map['equipeId'] ?? map['equipe_id'] ?? map['campeonatoTimeId'])?.toString(),
      atletaId: (map['atletaId'] ?? map['atleta_id'] ?? map['id'] ?? '').toString(),
      atleticaId: map['atleticaId'],
      nome: map['atletaNome'] ?? map['nome'] ?? 'Sem Nome',
      numero: numeroCamisa is num ? numeroCamisa.toInt() : int.tryParse(numeroCamisa?.toString() ?? ''),
      ativo: map['ativo'] == true || status == 'ATIVO',
      documentoIdentificacao: map['documentoIdentificacao'],
      curso: map['curso'],
      fotoUrl: map['fotoUrl'] ?? map['foto_url'],
    );
  }
}
