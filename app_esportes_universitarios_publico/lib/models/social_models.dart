class SocialAuthor {
  final String id;
  final String nomeExibicao;
  final String? fotoUrl;
  final String? atleticaId;
  final String? atleticaNome;
  final String? papelCodigo;

  const SocialAuthor({
    required this.id,
    required this.nomeExibicao,
    this.fotoUrl,
    this.atleticaId,
    this.atleticaNome,
    this.papelCodigo,
  });

  factory SocialAuthor.fromJson(Map<String, dynamic> json) {
    return SocialAuthor(
      id: json['id'].toString(),
      nomeExibicao: json['nomeExibicao'] ?? 'Usuário',
      fotoUrl: json['fotoUrl'],
      atleticaId: json['atleticaId']?.toString(),
      atleticaNome: json['atleticaNome'],
      papelCodigo: json['papelCodigo'],
    );
  }
}

class SocialComment {
  final String id;
  final SocialAuthor author;
  final String content;
  final int likeCount;
  final int replyCount;
  final bool likedByMe;
  final DateTime createdAt;
  final String? parentCommentId;
  final List<SocialComment> replies;

  const SocialComment({
    required this.id,
    required this.author,
    required this.content,
    required this.likeCount,
    required this.replyCount,
    required this.likedByMe,
    required this.createdAt,
    this.parentCommentId,
    this.replies = const [],
  });

  factory SocialComment.fromJson(Map<String, dynamic> json) {
    final rawReplies = json['replies'] as List<dynamic>? ?? const [];
    return SocialComment(
      id: json['id'].toString(),
      author: SocialAuthor.fromJson(json['author'] as Map<String, dynamic>),
      content: json['content'] ?? '',
      likeCount: json['likeCount'] ?? 0,
      replyCount: json['replyCount'] ?? 0,
      likedByMe: json['likedByMe'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      parentCommentId: json['parentCommentId']?.toString(),
      replies: rawReplies
          .map((item) => SocialComment.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SocialPost {
  final String id;
  final SocialAuthor author;
  final String? content;
  final String? imageUrl;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final DateTime createdAt;
  final List<SocialComment> commentPreview;

  const SocialPost({
    required this.id,
    required this.author,
    this.content,
    this.imageUrl,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
    required this.createdAt,
    this.commentPreview = const [],
  });

  factory SocialPost.fromJson(Map<String, dynamic> json) {
    final rawComments = json['commentPreview'] as List<dynamic>? ?? const [];
    return SocialPost(
      id: json['id'].toString(),
      author: SocialAuthor.fromJson(json['author'] as Map<String, dynamic>),
      content: json['content'],
      imageUrl: json['imageUrl'],
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      likedByMe: json['likedByMe'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      commentPreview: rawComments
          .map((item) => SocialComment.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SocialPublicProfile {
  final String id;
  final String nomeExibicao;
  final String? fotoUrl;
  final String? genero;
  final String? atleticaId;
  final String? atleticaNome;
  final String? papelCodigo;
  final int postCount;
  final int followerCount;
  final int followingCount;
  final bool following;

  const SocialPublicProfile({
    required this.id,
    required this.nomeExibicao,
    this.fotoUrl,
    this.genero,
    this.atleticaId,
    this.atleticaNome,
    this.papelCodigo,
    required this.postCount,
    required this.followerCount,
    required this.followingCount,
    required this.following,
  });

  factory SocialPublicProfile.fromJson(Map<String, dynamic> json) {
    return SocialPublicProfile(
      id: json['id'].toString(),
      nomeExibicao: json['nomeExibicao'] ?? 'Usuário',
      fotoUrl: json['fotoUrl'],
      genero: json['genero'],
      atleticaId: json['atleticaId']?.toString(),
      atleticaNome: json['atleticaNome'],
      papelCodigo: json['papelCodigo'],
      postCount: json['postCount'] ?? 0,
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      following: json['following'] ?? false,
    );
  }
}
