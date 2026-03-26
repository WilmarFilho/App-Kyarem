import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Profile?> fetchProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      // Adiciona o email do auth ao mapa antes de criar o Profile
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

      // Upload ao bucket 'avatars'
      await _supabase.storage
          .from('avatars')
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      // Pega a URL pública
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);

      // Adiciona timestamp para cache busting
      final urlWithCacheBust =
          '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // Atualiza no perfil
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
