class Profile {
  final String id;
  final String? nomeExibicao;
  final String? fotoUrl;
  final String role; // super_admin, admin, arbitro, delegado, presidente_atletica, aluno
  final String? email;
  final String? telefone;
  final String? universidade;

  Profile({
    required this.id,
    this.nomeExibicao,
    this.fotoUrl,
    required this.role,
    this.email,
    this.telefone,
    this.universidade,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      nomeExibicao: map['nome_exibicao'],
      fotoUrl: map['foto_url'],
      role: map['role'] ?? 'aluno',
      email: map['email'],
      telefone: map['telefone'],
      universidade: map['universidade'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome_exibicao': nomeExibicao,
      'foto_url': fotoUrl,
      'telefone': telefone,
      'universidade': universidade,
    };
  }

  String get roleLabel {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Administrador';
      case 'arbitro':
        return 'Árbitro';
      case 'delegado':
        return 'Delegado';
      case 'presidente_atletica':
        return 'Presidente de Atlética';
      case 'aluno':
        return 'Aluno';
      default:
        return role;
    }
  }
}
