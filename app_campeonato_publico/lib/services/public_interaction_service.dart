import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'device_identity_service.dart';

class PublicInteractionService {
  final SupabaseClient _supabase;
  final DeviceIdentityService _deviceIdentityService;

  PublicInteractionService({
    SupabaseClient? supabaseClient,
    DeviceIdentityService? deviceIdentityService,
  }) : _supabase = supabaseClient ?? Supabase.instance.client,
       _deviceIdentityService =
           deviceIdentityService ?? DeviceIdentityService();

  Future<String> getDeviceId() => _deviceIdentityService.getDeviceId();

  Future<String?> getSavedChatName(String partidaId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chatNameKey(partidaId));
  }

  Future<void> saveChatName(String partidaId, String displayName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chatNameKey(partidaId), displayName.trim());
  }

  Future<String?> getSavedPartidaTorcida(String partidaId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_partidaTorcidaKey(partidaId));
  }

  Future<void> savePartidaTorcida(String partidaId, String atleticaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_partidaTorcidaKey(partidaId), atleticaId);
  }

  Future<String?> getSavedAtleticaTorcida(String campeonatoAtleticaId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_atleticaTorcidaKey(campeonatoAtleticaId));
  }

  Future<void> saveAtleticaTorcida(
    String campeonatoAtleticaId,
    String atleticaId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_atleticaTorcidaKey(campeonatoAtleticaId), atleticaId);
  }

  Future<void> submitChatMessage({
    required String partidaId,
    required String displayName,
    required String message,
  }) async {
    final response = await _supabase.functions.invoke(
      'public-chat-send',
      body: {
        'partidaId': partidaId,
        'deviceId': await getDeviceId(),
        'displayName': displayName,
        'message': message,
      },
    );

    _throwIfFunctionFailed(response.data);
  }

  Future<void> submitPartidaTorcida({
    required String partidaId,
    required String atleticaId,
  }) async {
    final response = await _supabase.functions.invoke(
      'public-vote-submit',
      body: {
        'scope': 'partida',
        'partidaId': partidaId,
        'atleticaId': atleticaId,
        'deviceId': await getDeviceId(),
      },
    );

    _throwIfFunctionFailed(response.data);
    await savePartidaTorcida(partidaId, atleticaId);
  }

  Future<void> submitAtleticaTorcida({
    required String campeonatoAtleticaId,
    required String atleticaId,
  }) async {
    final response = await _supabase.functions.invoke(
      'public-vote-submit',
      body: {
        'scope': 'atletica',
        'campeonatoAtleticaId': campeonatoAtleticaId,
        'atleticaId': atleticaId,
        'deviceId': await getDeviceId(),
      },
    );

    _throwIfFunctionFailed(response.data);
    await saveAtleticaTorcida(campeonatoAtleticaId, atleticaId);
  }

  void _throwIfFunctionFailed(dynamic data) {
    if (data is Map<String, dynamic> && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
  }

  String _chatNameKey(String partidaId) => 'chat_name_$partidaId';
  String _partidaTorcidaKey(String partidaId) => 'torcida_partida_$partidaId';
  String _atleticaTorcidaKey(String campeonatoAtleticaId) =>
      'torcida_atletica_$campeonatoAtleticaId';
}
