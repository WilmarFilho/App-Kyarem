import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../models/social_models.dart';
import '../../../services/social_realtime_service.dart';
import '../../../services/social_service.dart';
import '../../widgets/social/social_comments_sheet.dart';
import '../../widgets/social/social_post_card.dart';

class SinglePostScreen extends StatefulWidget {
  const SinglePostScreen({
    super.key,
    required this.post,
    required this.socialService,
    required this.onAuthorTap,
    required this.onToggleLike,
  });

  final SocialPost post;
  final SocialService socialService;
  final ValueChanged<SocialAuthor> onAuthorTap;
  final Future<void> Function(SocialPost) onToggleLike;

  @override
  State<SinglePostScreen> createState() => _SinglePostScreenState();
}

class _SinglePostScreenState extends State<SinglePostScreen> {
  final TextEditingController _controller = TextEditingController();
  final SocialRealtimeService _realtime = SocialRealtimeService.instance;
  SocialComment? _replyTarget;
  List<SocialComment> _comments = const [];
  bool _loading = true;
  bool _sending = false;
  StreamSubscription<void>? _subscription;

  late SocialPost _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _load();
    _realtime.start();
    _subscription = _realtime.updates.listen((_) {
      if (mounted) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() => _loading = true);
    }
    try {
      final comments = await widget.socialService.fetchComments(_post.id);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await widget.socialService.createComment(
        _post.id,
        text,
        parentCommentId: _replyTarget?.id,
      );
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _replyTarget = null;
        _sending = false;
      });
      await _load(silent: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
    }
  }

  Future<void> _toggleCommentLike(SocialComment comment) async {
    try {
      if (comment.likedByMe) {
        await widget.socialService.unlikeComment(comment.id);
      } else {
        await widget.socialService.likeComment(comment.id);
      }
      await _load(silent: true);
    } catch (_) {}
  }

  Future<void> _handlePostLike(SocialPost post) async {
    await widget.onToggleLike(post);
    // Para simplificar, atualizamos o estado local do post para refletir no card (se fosse necessário).
    // O widget.onToggleLike pode não atualizar a variável local se for deep copy, mas assumimos que sim.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: const Text(
          'Post',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: SocialPostCard(
                        post: _post,
                        onAuthorTap: widget.onAuthorTap,
                        onToggleLike: _handlePostLike,
                        onOpenComments: () {
                          // Opcional: focar no campo de comentário
                        },
                        // onPostTap null por padrão para não recursivamente abrir a tela
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Comentários',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Text(
                            '${_comments.length}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_loading)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else if (_comments.isEmpty)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                          child: Text(
                            'Ainda não há comentários aqui. Puxa a conversa e abre o clima da torcida.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: AppColors.textMuted,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final comment = _comments[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: SocialCommentThread(
                              comment: comment,
                              onAuthorTap: widget.onAuthorTap,
                              onReply: (target) => setState(() {
                                _replyTarget = target;
                              }),
                              onToggleLike: _toggleCommentLike,
                            ),
                          );
                        },
                        childCount: _comments.length,
                      ),
                    ),
                ],
              ),
            ),
            // Input Area
            if (_replyTarget != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Respondendo ${_replyTarget!.author.nomeExibicao}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _replyTarget = null),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FB),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(fontFamily: 'Poppins'),
                        decoration: const InputDecoration(
                          hintText: 'Comente o post...',
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.zero,
                        elevation: 0,
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
