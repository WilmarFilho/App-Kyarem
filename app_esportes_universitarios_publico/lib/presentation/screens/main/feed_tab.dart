import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/app_colors.dart';
import '../../../../models/social_models.dart';
import '../../../../services/profile_service.dart';
import '../../../../services/social_realtime_service.dart';
import '../../../../services/social_service.dart';
import '../../widgets/layout/main_top_bar.dart';
import '../../widgets/social/social_comments_sheet.dart';
import '../../widgets/social/social_post_card.dart';
import 'public_profile_screen.dart';

class FeedTab extends StatefulWidget {
  const FeedTab({
    super.key,
    required this.onProfileTap,
    required this.hasPendingInvite,
  });

  final VoidCallback onProfileTap;
  final bool hasPendingInvite;

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  final SocialService _socialService = SocialService();
  final ProfileService _profileService = ProfileService();
  final SocialRealtimeService _realtimeService = SocialRealtimeService.instance;
  final ImagePicker _imagePicker = ImagePicker();

  List<SocialPost> _posts = const [];
  bool _loading = true;
  bool _publishing = false;
  String? _myUserId;
  String? _myAvatarUrl;
  StreamSubscription<void>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _loadMe();
    _realtimeService.start();
    _realtimeSubscription = _realtimeService.updates.listen((_) {
      if (mounted) _loadFeed(silent: true);
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMe() async {
    final profile = await _profileService.getMyProfile();
    if (!mounted || profile == null) return;
    setState(() {
      _myUserId = profile.id;
      _myAvatarUrl = profile.fotoUrl;
    });
  }

  Future<void> _loadFeed({bool silent = false}) async {
    if (!silent) {
      setState(() => _loading = true);
    }
    try {
      final posts = await _socialService.fetchFeed();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
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
          onAuthorTap: _openAuthorProfile,
        );
      },
    );
    await _loadFeed(silent: true);
  }

  Future<void> _openCreatePostSheet() async {
    final textController = TextEditingController();
    String? uploadedImageUrl;
    File? selectedImage;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickImage() async {
              final image = await _imagePicker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 88,
              );
              if (image == null) return;
              setSheetState(() => selectedImage = File(image.path));
            }

            Future<void> publish() async {
              if (_publishing) return;
              final text = textController.text.trim();
              if (text.isEmpty && selectedImage == null) return;

              setState(() => _publishing = true);
              try {
                if (selectedImage != null) {
                  uploadedImageUrl =
                      await _socialService.uploadPostImage(selectedImage!);
                }
                await _socialService.createPost(
                  content: text.isEmpty ? null : text,
                  imageUrl: uploadedImageUrl,
                );
                if (!mounted) return;
                Navigator.of(sheetContext).pop();
                await _loadFeed(silent: true);
              } catch (_) {
              } finally {
                if (mounted) {
                  setState(() => _publishing = false);
                }
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 18,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Novo post',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Compartilhe o clima da torcida, uma foto do evento ou um comentário rápido.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.textMuted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: textController,
                      maxLines: 5,
                      minLines: 4,
                      style: const TextStyle(fontFamily: 'Poppins'),
                      decoration: InputDecoration(
                        hintText: 'O que está rolando por aí?',
                        hintStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          color: AppColors.textMuted,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF4F7FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (selectedImage != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          selectedImage!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: pickImage,
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Adicionar imagem'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _publishing ? null : publish,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _publishing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Publicar',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openAuthorProfile(SocialAuthor author) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          profileId: author.id,
          currentUserId: _myUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPosts = _posts.length;
    final totalFotos = _posts.where((post) => (post.imageUrl ?? '').isNotEmpty).length;

    return RefreshIndicator(
      onRefresh: _loadFeed,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
        children: [
          MainTopBar(
            onProfileTap: widget.onProfileTap,
            hasPendingInvite: widget.hasPendingInvite,
            trailing: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _openCreatePostSheet,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.14),
                    ),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feed',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Acompanhe comentários, bastidores, fotos e reações das pessoas que você decidiu seguir.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A2342), Color(0xFF194B8F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Clima da sua bolha',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFAFC7F3),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Torcida aquecida, fotos novas subindo e comentários ao vivo de quem você acompanha.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _StatusChip(label: '$totalPosts posts'),
                                _StatusChip(label: '$totalFotos fotos'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        backgroundImage: _myAvatarUrl != null
                            ? NetworkImage(_myAvatarUrl!)
                            : null,
                        child: _myAvatarUrl == null
                            ? const Icon(
                                Icons.dynamic_feed_rounded,
                                size: 28,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_posts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE8EDF5)),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.groups_rounded,
                          size: 44,
                          color: AppColors.secondary,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Seu feed ainda está vazio.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Siga perfis pela busca e publique os primeiros bastidores para começar a conversa.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.textMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._posts.map(
                    (post) => SocialPostCard(
                      post: post,
                      onAuthorTap: _openAuthorProfile,
                      onToggleLike: _toggleLike,
                      onOpenComments: () => _openComments(post),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
