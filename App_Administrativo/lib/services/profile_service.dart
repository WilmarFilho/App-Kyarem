import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/profile_model.dart';

/// Serviço de perfil do usuário.
///
/// ⚠️  A tabela de perfis NÃO fica em `public.profiles`.
///
/// Leitura do perfil (incluindo role/permissões) → REST do backend:
///   GET  /api/v1/profiles/me/access
///
/// Atualização e foto → Supabase Storage + tabela correta do schema `identity`.
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
              baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080/api/v1',
              connectTimeout: const Duration(seconds: 10),
            ),
          );

  /// Busca o perfil completo via REST do backend.
  /// O endpoint `/profiles/me/access` retorna o perfil com as flags de acesso.
  Future<Profile?> fetchProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final token = _supabase.auth.currentSession?.accessToken;
      if (token == null || token.isEmpty) return null;

      final res = await _dio.get(
        '/profiles/me/access',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = Map<String, dynamic>.from(res.data as Map);
      return Profile(
        id: data['id']?.toString() ?? user.id,
        nomeExibicao: data['nomeExibicao'],
        fotoUrl: data['fotoUrl'],
        role: data['role'] ?? 'user',
        email: data['email'] ?? user.email,
        telefone: data['telefone'],
        dataNascimento: data['dataNascimento']?.toString(),
        genero: data['genero']?.toString(),
      );
    } catch (e) {
      debugPrint('Erro ao buscar perfil: $e');
      return null;
    }
  }

  /// Atualiza nome de exibição e telefone.
  /// ⚠️  Caso o backend não tenha PUT /profiles/me, este método salva
  /// os dados diretamente no schema `identity` via Supabase RPC ou retorna false.
  /// Por enquanto, indica falha se o endpoint não existir.
  Future<bool> updateProfile({
    required String nomeExibicao,
    String? telefone,
  }) async {
    try {
      final token = _supabase.auth.currentSession?.accessToken;
      if (token == null || token.isEmpty) return false;

      await _dio.put(
        '/profiles/me',
        data: {'nomeExibicao': nomeExibicao, 'telefone': telefone},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar perfil: $e');
      return false;
    }
  }

  /// Faz upload de foto de perfil no Supabase Storage e persiste a URL no backend.
  Future<String?> uploadProfilePhoto(File imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final token = _supabase.auth.currentSession?.accessToken;
      if (token == null || token.isEmpty) return null;

      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final filePath = '${user.id}/avatar.$fileExt';

      // 1. Upload para o Supabase Storage
      await _supabase.storage
          .from('avatars')
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      // 2. Gera a URL pública com cache-bust
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);
      final urlComTimestamp =
          '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // 3. Persiste a URL no backend para que fique salva no banco
      await _dio.patch(
        '/profiles/me/avatar',
        data: {'avatarUrl': urlComTimestamp},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return urlComTimestamp;
    } catch (e) {
      debugPrint('Erro ao fazer upload da foto: $e');
      return null;
    }
  }
}
