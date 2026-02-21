class TipoEventoEsporte {
  final String id;
  final String esporteId;
  final String nome;
  final int? idx; // Opcional, caso queira manter a ordem do arquivo txt

  TipoEventoEsporte({
    required this.id,
    required this.esporteId,
    required this.nome,
    this.idx,
  });

  // Transforma o JSON do Supabase ou do arquivo TXT em objeto Dart
  factory TipoEventoEsporte.fromJson(Map<String, dynamic> json) {
    return TipoEventoEsporte(
      id: json['id'] as String,
      esporteId: json['esporte_id'] as String,
      nome: json['nome'] as String,
      idx: json['idx'] as int?, // Trata como opcional pois nem sempre vem do banco
    );
  }

  // Útil para quando você precisar enviar dados de volta ou salvar localmente
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'esporte_id': esporteId,
      'nome': nome,
      if (idx != null) 'idx': idx,
    };
  }

  // Helper para exibir o nome formatado (ex: de "GOL" para "Gol")
  String get nomeFormatado {
    if (nome.isEmpty) return "";
    return nome.replaceAll('_', ' ').toLowerCase().replaceFirst(
      nome[0].toLowerCase(), 
      nome[0].toUpperCase()
    );
  }
}