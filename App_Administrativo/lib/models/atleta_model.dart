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
    return Atleta(
      id: map['id'] ?? '',
      equipeId: map['equipeId'],
      atletaId: map['atletaId'] ?? map['id'] ?? '',
      atleticaId: map['atleticaId'],
      nome: map['atletaNome'] ?? map['nome'] ?? 'Sem Nome',
      numero: map['numeroCamisa'],
      ativo: map['ativo'],
      documentoIdentificacao: map['documentoIdentificacao'],
      curso: map['curso'],
      fotoUrl: map['fotoUrl'],
    );
  }
}