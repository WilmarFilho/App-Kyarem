import 'evento_model.dart';

enum StatusSumula { pendente, emAndamento, encerrada }

class Sumula {
  final String id;
  int placarTimeA;
  int placarTimeB;
  StatusSumula status;
  List<Evento> eventos; // Lista tipada corretamente

  Sumula({
    required this.id,
    this.placarTimeA = 0,
    this.placarTimeB = 0,
    this.status = StatusSumula.pendente,
    this.eventos = const [], // Aqui pode manter const se você sempre usar copyWith para trocar a lista toda
  });

  factory Sumula.fromMap(Map<String, dynamic> map) {
    return Sumula(
      id: map['id'],
      placarTimeA: map['placar_a'] ?? 0,
      placarTimeB: map['placar_b'] ?? 0,
      status: StatusSumula.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pendente'),
        orElse: () => StatusSumula.pendente,
      ),
      eventos: [], 
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'placarTimeA': placarTimeA,
        'placarTimeB': placarTimeB,
        'status': status.name,
        // Ajustado para toMap() que é o padrão que usamos no EventoModel
        'eventos': eventos.map((e) => e.toMap()).toList(), 
      };

  Sumula copyWith({
    int? placarTimeA,
    int? placarTimeB,
    StatusSumula? status,
    List<Evento>? eventos,
  }) {
    return Sumula(
      id: id,
      placarTimeA: placarTimeA ?? this.placarTimeA,
      placarTimeB: placarTimeB ?? this.placarTimeB,
      status: status ?? this.status,
      eventos: eventos ?? this.eventos,
    );
  }
}