class UserProfile {
  final String id;
  final String nomeExibicao;
  final String? email;
  final String? fotoUrl;
  final String? telefone;
  final String? genero;
  final String role;

  UserProfile({
    required this.id,
    required this.nomeExibicao,
    this.email,
    this.fotoUrl,
    this.telefone,
    this.genero,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      nomeExibicao: json['nomeExibicao'] ?? 'Usuário',
      email: json['email'],
      fotoUrl: json['fotoUrl'] ?? json['avatarUrl'],
      telefone: json['telefone'],
      genero: json['genero'],
      role: json['role'] ?? 'USER',
    );
  }
}
