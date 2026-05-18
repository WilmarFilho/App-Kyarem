import 'dart:convert';
import '../core/api_client.dart';
import '../models/user_profile.dart';

class ProfileService {
  final ApiClient _apiClient = ApiClient();

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
}
