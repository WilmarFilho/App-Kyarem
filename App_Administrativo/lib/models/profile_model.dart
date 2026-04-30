class Profile {
  final String id;
  final String? nomeExibicao;
  final String? fotoUrl;
  final String role; // admin, referee, user
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
      id: map['id']?.toString() ?? '',
      // backend retorna camelCase; Supabase legado retornava snake_case
      nomeExibicao: map['nomeExibicao'] ?? map['nome_exibicao'],
      fotoUrl:
          map['fotoUrl'] ??
          map['foto_url'] ??
          map['avatarUrl'] ??
          map['avatar_url'],
      role: map['role'] ?? 'user',
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
      case 'admin':
        return 'Administrador';
      case 'referee':
        return 'Árbitro';
      case 'user':
        return 'Usuário';
      default:
        return role;
    }
  }
}
