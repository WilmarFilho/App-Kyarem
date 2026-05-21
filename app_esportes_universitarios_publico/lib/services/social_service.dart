import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/api_client.dart';
import '../models/social_models.dart';

class SocialService {
  final ApiClient _apiClient = ApiClient();
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<SocialPost>> fetchFeed({int limit = 20}) async {
    final response = await _apiClient.get('/social/feed?limit=$limit');
    if (response.statusCode != 200) {
      throw Exception('Não foi possível carregar o feed.');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data
        .map((item) => SocialPost.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<SocialPost>> fetchProfilePosts(
    String profileId, {
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      '/social/profiles/$profileId/posts?limit=$limit',
    );
    if (response.statusCode != 200) {
      throw Exception('Não foi possível carregar os posts do perfil.');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data
        .map((item) => SocialPost.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SocialPublicProfile> fetchPublicProfile(String profileId) async {
    final response = await _apiClient.get('/social/profiles/$profileId');
    if (response.statusCode != 200) {
      throw Exception('Não foi possível carregar o perfil.');
    }

    return SocialPublicProfile.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  Future<SocialPost> createPost({
    String? content,
    String? imageUrl,
  }) async {
    final response = await _apiClient.post('/social/posts', {
      'content': content,
      'imageUrl': imageUrl,
    });
    if (response.statusCode != 201) {
      throw Exception('Não foi possível publicar agora.');
    }

    return SocialPost.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  Future<SocialPost> likePost(String postId) async {
    final response = await _apiClient.post('/social/posts/$postId/likes', {});
    if (response.statusCode != 200) {
      throw Exception('Não foi possível curtir o post.');
    }
    return SocialPost.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  Future<SocialPost> unlikePost(String postId) async {
    final response = await _apiClient.delete('/social/posts/$postId/likes');
    if (response.statusCode != 200) {
      throw Exception('Não foi possível remover a curtida.');
    }
    return SocialPost.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  Future<List<SocialComment>> fetchComments(String postId) async {
    final response = await _apiClient.get('/social/posts/$postId/comments');
    if (response.statusCode != 200) {
      throw Exception('Não foi possível carregar os comentários.');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data
        .map((item) => SocialComment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SocialComment> createComment(
    String postId,
    String content, {
    String? parentCommentId,
  }) async {
    final response = await _apiClient.post('/social/posts/$postId/comments', {
      'content': content,
      'parentCommentId': parentCommentId,
    });
    if (response.statusCode != 201) {
      throw Exception('Não foi possível comentar agora.');
    }

    return SocialComment.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  Future<SocialComment> likeComment(String commentId) async {
    final response = await _apiClient.post('/social/comments/$commentId/likes', {});
    if (response.statusCode != 200) {
      throw Exception('Não foi possível curtir o comentário.');
    }

    return SocialComment.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  Future<SocialComment> unlikeComment(String commentId) async {
    final response = await _apiClient.delete('/social/comments/$commentId/likes');
    if (response.statusCode != 200) {
      throw Exception('Não foi possível remover a curtida do comentário.');
    }

    return SocialComment.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  Future<SocialPublicProfile> follow(String profileId) async {
    final response = await _apiClient.post('/social/profiles/$profileId/follow', {});
    if (response.statusCode != 200) {
      throw Exception('Não foi possível seguir esse perfil agora.');
    }
    return SocialPublicProfile.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  Future<SocialPublicProfile> unfollow(String profileId) async {
    final response = await _apiClient.delete('/social/profiles/$profileId/follow');
    if (response.statusCode != 200) {
      throw Exception('Não foi possível deixar de seguir esse perfil agora.');
    }
    return SocialPublicProfile.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  Future<String?> uploadPostImage(File imageFile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final fileExt = imageFile.path.split('.').last.toLowerCase();
    final filePath =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    await _supabase.storage.from('social-posts').upload(
      filePath,
      imageFile,
      fileOptions: const FileOptions(upsert: true),
    );

    return _supabase.storage.from('social-posts').getPublicUrl(filePath);
  }
}
