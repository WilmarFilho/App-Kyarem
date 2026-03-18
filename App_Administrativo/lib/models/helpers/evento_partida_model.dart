import 'package:flutter/material.dart';

class EventoPartida {
  final String tipo;
  final String? jogadorNome;
  final int? jogadorNumero;
  final Color? corTime;
  final String horario;
  final String? observacao;

  EventoPartida({
    required this.tipo,
    required this.horario,
    this.jogadorNome,
    this.jogadorNumero,
    this.corTime,
    this.observacao,
  });

  /// Getter que traduz o tipo técnico para uma string amigável para a UI
  String get descricao {
    switch (tipo) {
      case 'INICIO_1_TEMPO':
        return 'Início do 1º Tempo';
      case 'FIM_1_TEMPO':
        return 'Fim do 1º Tempo';
      case 'FIM_2_TEMPO':
        return 'Fim do 2º Tempo';
      case 'INICIO_2_TEMPO':
        return 'Início do 2º Tempo';
      case 'INTERVALO':
        return 'Partida no Intervalo';
      case 'PARTIDA_PAUSADA':
        return 'Partida Pausada';
      case 'PARTIDA_RETOMADA':
        return 'Partida Retomada';
      case 'PAUSA_TECNICA':
        return 'Pausa Técnica';
      case 'FIM_PAUSA_TECNICA':
        return 'Fim da Pausa Técnica';
      case 'ACRESCIMO':
        return 'Partida em Acréscimo';
      case 'ACRESCIMO_DADO':
        return 'Acréscimo concedido';
      case 'PRORROGACAO':
        return 'Partida em Prorrogação';
      case 'PRORROGACAO_DADA':
        return 'Prorrogação concedida';
      case 'FIM_PARTIDA':
        return 'Fim de Jogo';
      case 'SUBSTITUICAO':
        return 'Substituição';
      case 'GOL':
        return 'GOL';
      case 'CARTAO_AMARELO':
        return 'Cartão Amarelo';
      case 'CARTAO_VERMELHO':
        return 'Cartão Vermelho';
        case 'ARREMESO_DE_META':
        return 'Arremesso de Meta';
      case 'TIRO_DE_CANTO':
        return 'Tiro de Canto';
      case 'TIRO_DE_SAIDA':
        return 'Tiro de Saída';
      case 'TIRO_LATERAL':
        return 'Tiro Lateral';
      case 'PENALTI_PERDIDO':
        return 'Pênalti Perdido';
      case 'TIRO_LIVRE_DIRETO':
        return 'Tiro Livre Direto';
      case 'TIRO_LIVRE_INDIRETO':
        return 'Tiro Livre Indireto';
      case 'PENALTI_MARCADO':
        return 'Pênalti Marcado';
      case 'PENALTI':
        return 'Pênalti';
      case 'FALTA':
        return 'Falta';
      default:
        // Caso seja um evento de jogador não mapeado explicitamente acima
        if (jogadorNumero != null) {
          return '$tipo (#$jogadorNumero)';
        }
        return tipo;
    }
  }

  /// Verifica se o evento é um evento de sistema (sem jogador)
  bool get isSistematizado => jogadorNome == null;

  String get descricaoCompleta {
    final obs = observacao?.trim() ?? '';
    if (obs.isEmpty) return descricao;
    return '$descricao • $obs';
  }
}