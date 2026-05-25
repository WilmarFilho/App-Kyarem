import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/api_client.dart';
import '../models/user_profile.dart';

class ProfileService {
  final ApiClient _apiClient = ApiClient();
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserProfile?> getMyProfile() async {
    try {
      final response = await _apiClient.get('/me');
      if (response.statusCode == 200) {
        return UserProfile.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<UserProfile>> searchProfiles(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _apiClient.get(
        '/profiles/search?query=${Uri.encodeQueryComponent(query)}',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => UserProfile.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<String?> uploadProfilePhoto(File imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      final token = _supabase.auth.currentSession?.accessToken;
      if (user == null || token == null || token.isEmpty) return null;

      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final filePath = '${user.id}/avatar.$fileExt';

      await _supabase.storage.from('avatars').upload(
        filePath,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
      final urlComTimestamp =
          '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      final response = await _apiClient.patch('/profiles/me/avatar', {
        'avatarUrl': urlComTimestamp,
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return urlComTimestamp;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch('/profiles/me', data);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
