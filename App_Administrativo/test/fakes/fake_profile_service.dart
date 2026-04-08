import 'dart:io';

import 'package:kyarem_eventos/models/profile_model.dart';
import 'package:kyarem_eventos/services/profile_service.dart';

/// Implementação fake de [ProfileService] para uso exclusivo em testes de widget.
/// Não acessa Supabase nem nenhum recurso externo.
class FakeProfileService extends ProfileService {
  final Profile? profile;

  FakeProfileService({this.profile}) : super();

  @override
  Future<Profile?> fetchProfile() async => profile;

  @override
  Future<bool> updateProfile({
    required String nomeExibicao,
    String? telefone,
  }) async => true;

  @override
  Future<String?> uploadProfilePhoto(File imageFile) async => null;
}
