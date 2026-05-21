import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/app_colors.dart';
import '../../../../models/user_profile.dart';
import '../../../../services/profile_service.dart';
import 'public_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProfileService _profileService = ProfileService();
  Timer? _debounce;
  String _query = '';
  bool _loading = false;
  List<UserProfile> _profiles = const [];

  final List<Map<String, dynamic>> _quickLinks = const [
    {
      'title': 'Perfis',
      'subtitle': 'Buscar pessoas e abrir o perfil público',
      'icon': Icons.person_search_rounded,
    },
    {
      'title': 'Atléticas',
      'subtitle': 'Explorar torcidas e elencos ativos',
      'icon': Icons.groups_rounded,
    },
    {
      'title': 'Feed',
      'subtitle': 'Ver as últimas postagens da sua rede',
      'icon': Icons.dynamic_feed_rounded,
    },
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchProfiles();
    });
  }

  Future<void> _searchProfiles() async {
    final query = _query.trim();
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _profiles = const [];
      });
      return;
    }

    setState(() => _loading = true);
    final profiles = await _profileService.searchProfiles(query);
    if (!mounted) return;
    setState(() {
      _profiles = profiles;
      _loading = false;
    });
  }

  void _openProfile(UserProfile profile) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          profileId: profile.id,
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showResults = _query.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF555555),
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FB),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF99AABB),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              cursorColor: AppColors.primary,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                hintText: 'Buscar perfis, atléticas, torcida...',
                                hintStyle: TextStyle(
                                  color: Color(0xFF99AABB),
                                  fontFamily: 'Poppins',
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: _onChanged,
                            ),
                          ),
                          if (_query.isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF99AABB),
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _onChanged('');
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  Text(
                    showResults ? 'Perfis encontrados' : 'Atalhos',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!showResults)
                    ..._quickLinks.map(_buildQuickCard)
                  else if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_profiles.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 56,
                            color: Color(0xFFCCCCCC),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum perfil encontrado.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._profiles.map(_buildProfileCard),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item['icon'] as IconData,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['subtitle'] as String,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(UserProfile profile) {
    return InkWell(
      onTap: () => _openProfile(profile),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EDF5)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFEAF0FA),
              backgroundImage: profile.fotoUrl != null
                  ? NetworkImage(profile.fotoUrl!)
                  : null,
              child: profile.fotoUrl == null
                  ? Text(
                      profile.nomeExibicao.characters.first.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.nomeExibicao,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _roleLabel(profile.role),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role.trim().toUpperCase()) {
      case 'ATHLETE':
        return 'Atleta';
      case 'DIRECTOR':
        return 'Diretoria';
      case 'PRESIDENT':
        return 'Presidente';
      case 'ADMIN':
        return 'Admin';
      default:
        return 'Perfil';
    }
  }
}
