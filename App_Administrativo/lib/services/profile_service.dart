import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';

class ProfileService {
  final SupabaseClient? _supabaseOverride;
  final Dio _dio;

  SupabaseClient get _supabase => _supabaseOverride ?? Supabase.instance.client;

  ProfileService({SupabaseClient? supabase, Dio? dio})
    : _supabaseOverride = supabase,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'http://10.0.2.2:8080/api/v1',
              connectTimeout: const Duration(seconds: 10),
            ),
          );

  Future<Profile?> fetchProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      final token = _supabase.auth.currentSession?.accessToken;
      if (token != null && token.isNotEmpty) {
        try {
          final accessRes = await _dio.get(
            '/profiles/me/access',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
          final access = Map<String, dynamic>.from(accessRes.data as Map);
          data['role'] = access['role'] ?? 'user';
        } catch (_) {
          data['role'] = 'user';
        }
      } else {
        data['role'] = 'user';
      }

      data['email'] = user.email;
      return Profile.fromMap(data);
    } catch (e) {
      debugPrint('Erro ao buscar perfil: $e');
      return null;
    }
  }

  Future<bool> updateProfile({
    required String nomeExibicao,
    String? telefone,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('profiles')
          .update({'nome_exibicao': nomeExibicao, 'telefone': telefone})
          .eq('id', user.id);

      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar perfil: $e');
      return false;
    }
  }

  Future<String?> uploadProfilePhoto(File imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final fileExt = imageFile.path.split('.').last;
      final filePath = '${user.id}/avatar.$fileExt';

      await _supabase.storage.from('avatars').upload(
        filePath,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
      final urlWithCacheBust =
          '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      await _supabase
          .from('profiles')
          .update({'foto_url': urlWithCacheBust})
          .eq('id', user.id);

      return urlWithCacheBust;
    } catch (e) {
      debugPrint('Erro ao fazer upload da foto: $e');
      return null;
    }
  }
}
