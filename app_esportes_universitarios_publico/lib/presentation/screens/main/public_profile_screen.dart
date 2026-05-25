import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../models/social_models.dart';
import '../../../../services/social_realtime_service.dart';
import '../../../../services/social_service.dart';
import '../../widgets/social/social_comments_sheet.dart';
import '../../widgets/social/social_post_card.dart';
import 'single_post_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({
    super.key,
    required this.profileId,
    this.currentUserId,
  });

  final String profileId;
  final String? currentUserId;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final SocialService _socialService = SocialService();
  final SocialRealtimeService _realtimeService = SocialRealtimeService.instance;

  SocialPublicProfile? _profile;
  List<SocialPost> _posts = const [];
  bool _loading = true;
  bool _updatingFollow = false;
  StreamSubscription<void>? _subscription;

  bool get _isOwnProfile => widget.currentUserId == widget.profileId;

  @override
  void initState() {
    super.initState();
    _load();
    _realtimeService.start();
    _subscription = _realtimeService.updates.listen((_) {
      if (mounted) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() => _loading = true);
    }
    try {
      final results = await Future.wait([
        _socialService.fetchPublicProfile(widget.profileId),
        _socialService.fetchProfilePosts(widget.profileId),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as SocialPublicProfile;
        _posts = results[1] as List<SocialPost>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final profile = _profile;
    if (profile == null || _isOwnProfile || _updatingFollow) return;

    setState(() => _updatingFollow = true);
    try {
      final updated = profile.following
          ? await _socialService.unfollow(profile.id)
          : await _socialService.follow(profile.id);
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _updatingFollow = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _updatingFollow = false);
    }
  }

  Future<void> _toggleLike(SocialPost post) async {
    try {
      final updated = post.likedByMe
          ? await _socialService.unlikePost(post.id)
          : await _socialService.likePost(post.id);
      if (!mounted) return;
      setState(() {
        _posts = _posts
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _openComments(SocialPost post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SocialCommentsSheet(
          post: post,
          socialService: _socialService,
          onAuthorTap: (author) {
            if (author.id == widget.profileId) return;
            Navigator.of(context).pop();
            Navigator.of(this.context).push(
              MaterialPageRoute(
                builder: (_) => PublicProfileScreen(
                  profileId: author.id,
                  currentUserId: widget.currentUserId,
                ),
              ),
            );
          },
        );
      },
    );
    await _load(silent: true);
  }

  Future<void> _openSinglePost(SocialPost post) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SinglePostScreen(
          post: post,
          socialService: _socialService,
          onAuthorTap: _openAuthorProfile,
          onToggleLike: _toggleLike,
        ),
      ),
    );
    await _load(silent: true);
  }

  void _openAuthorProfile(SocialAuthor author) {
    if (author.id == widget.profileId) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          profileId: author.id,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : profile == null
            ? const Center(
                child: Text(
                  'Não foi possível carregar esse perfil.',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'Perfil',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE8EDF5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: const Color(0xFFEAF0FA),
                            backgroundImage: profile.fotoUrl != null
                                ? NetworkImage(profile.fotoUrl!)
                                : null,
                            child: profile.fotoUrl == null
                                ? Text(
                                    profile.nomeExibicao.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            profile.nomeExibicao,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          if ((profile.atleticaNome ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              profile.atleticaNome!,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                          if ((profile.papelCodigo ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _labelFromRole(profile.papelCodigo!),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _CounterBlock(
                                label: 'Posts',
                                value: '${profile.postCount}',
                              ),
                              _CounterBlock(
                                label: 'Seguidores',
                                value: '${profile.followerCount}',
                              ),
                              _CounterBlock(
                                label: 'Seguindo',
                                value: '${profile.followingCount}',
                              ),
                            ],
                          ),
                          if (!_isOwnProfile) ...[
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _updatingFollow ? null : _toggleFollow,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: profile.following
                                      ? const Color(0xFFEAF0FA)
                                      : AppColors.secondary,
                                  foregroundColor: profile.following
                                      ? AppColors.primary
                                      : Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _updatingFollow
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: profile.following
                                              ? AppColors.primary
                                              : Colors.white,
                                        ),
                                      )
                                    : Text(
                                        profile.following
                                            ? 'Seguindo'
                                            : 'Seguir perfil',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Posts do perfil',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_posts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Esse perfil ainda não publicou nada por aqui.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    else
                      ..._posts.map(
                        (post) => SocialPostCard(
                          post: post,
                          onAuthorTap: _openAuthorProfile,
                          onToggleLike: _toggleLike,
                          onOpenComments: () => _openComments(post),
                          onPostTap: () => _openSinglePost(post),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  String _labelFromRole(String role) {
    switch (role.trim().toUpperCase()) {
      case 'PRESIDENT':
        return 'Presidente';
      case 'DIRECTOR':
        return 'Diretoria';
      case 'ATHLETE':
        return 'Atleta';
      default:
        return role;
    }
  }
}

class _CounterBlock extends StatelessWidget {
  const _CounterBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
