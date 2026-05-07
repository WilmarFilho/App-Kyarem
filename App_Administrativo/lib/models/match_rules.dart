/// Regras tipadas extraídas do JSON da modalidade.
class MatchRules {
  final int tempoPartidaMinutos;
  final int numeroPeriodosRegulares;
  final bool permiteProrrogacao;
  final bool permitePenaltis;
  final int duracaoIntervaloMinutos;
  final int tempoProrrogacaoMinutos;

  const MatchRules({
    this.tempoPartidaMinutos = 20,
    this.numeroPeriodosRegulares = 2,
    this.permiteProrrogacao = false,
    this.permitePenaltis = false,
    this.duracaoIntervaloMinutos = 10,
    this.tempoProrrogacaoMinutos = 5,
  });

  /// Duração de um único período em segundos
  int get duracaoPeriodoSegundos => tempoPartidaMinutos * 60;
  int get duracaoPrimeiroTempoSegundos => duracaoPeriodoSegundos;
  int get duracaoSegundoTempoSegundos => duracaoPeriodoSegundos * 2;
  int get duracaoIntervaloSegundos => duracaoIntervaloMinutos * 60;
  int get duracaoProrrogacaoSegundos => tempoProrrogacaoMinutos * 60;

  factory MatchRules.fromRegras(Map<String, dynamic>? regras) {
    if (regras == null) return const MatchRules();
    final base = regras['regrasBaseJson'] as Map<String, dynamic>?;
    final efetivas = regras['regrasEfetivasJson'] as Map<String, dynamic>?;
    final merged = {...?base, ...?efetivas};
    return MatchRules(
      tempoPartidaMinutos:
          (merged['tempoPartidaMinutos'] as num?)?.toInt() ?? 20,
      numeroPeriodosRegulares:
          (merged['numeroPeriodosRegulares'] as num?)?.toInt() ?? 2,
      permiteProrrogacao: merged['permiteProrrogacao'] as bool? ?? false,
      permitePenaltis: merged['permitePenaltis'] as bool? ?? false,
      duracaoIntervaloMinutos:
          (merged['duracaoIntervaloMinutos'] as num?)?.toInt() ?? 10,
      tempoProrrogacaoMinutos:
          (merged['tempoProrrogacaoMinutos'] as num?)?.toInt() ?? 5,
    );
  }

  factory MatchRules.fromPartida(Map<String, dynamic>? regrasPartida) =>
      MatchRules.fromRegras(regrasPartida);
}
