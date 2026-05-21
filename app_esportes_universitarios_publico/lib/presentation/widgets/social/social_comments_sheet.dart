import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../models/social_models.dart';
import '../../../services/social_realtime_service.dart';
import '../../../services/social_service.dart';

class SocialCommentsSheet extends StatefulWidget {
  const SocialCommentsSheet({
    super.key,
    required this.post,
    required this.socialService,
    required this.onAuthorTap,
  });

  final SocialPost post;
  final SocialService socialService;
  final ValueChanged<SocialAuthor> onAuthorTap;

  @override
  State<SocialCommentsSheet> createState() => _SocialCommentsSheetState();
}

class _SocialCommentsSheetState extends State<SocialCommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  final SocialRealtimeService _realtime = SocialRealtimeService.instance;
  SocialComment? _replyTarget;
  List<SocialComment> _comments = const [];
  bool _loading = true;
  bool _sending = false;
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
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
      final comments = await widget.socialService.fetchComments(widget.post.id);
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
        widget.post.id,
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

  Future<void> _toggleLike(SocialComment comment) async {
    try {
      if (comment.likedByMe) {
        await widget.socialService.unlikeComment(comment.id);
      } else {
        await widget.socialService.likeComment(comment.id);
      }
      await _load(silent: true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.82,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9E2EE),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Comentários',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
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
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _comments.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 28),
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
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                        children: _comments
                            .map(
                              (comment) => _CommentThread(
                                comment: comment,
                                onAuthorTap: widget.onAuthorTap,
                                onReply: (target) => setState(() {
                                  _replyTarget = target;
                                }),
                                onToggleLike: _toggleLike,
                              ),
                            )
                            .toList(),
                      ),
              ),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
      ),
    );
  }
}

class _CommentThread extends StatelessWidget {
  const _CommentThread({
    required this.comment,
    required this.onAuthorTap,
    required this.onReply,
    required this.onToggleLike,
    this.isReply = false,
  });

  final SocialComment comment;
  final ValueChanged<SocialAuthor> onAuthorTap;
  final ValueChanged<SocialComment> onReply;
  final ValueChanged<SocialComment> onToggleLike;
  final bool isReply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 14,
        left: isReply ? 24 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => onAuthorTap(comment.author),
                child: CircleAvatar(
                  radius: isReply ? 15 : 18,
                  backgroundColor: const Color(0xFFE9EEF7),
                  backgroundImage: comment.author.fotoUrl != null
                      ? NetworkImage(comment.author.fotoUrl!)
                      : null,
                  child: comment.author.fotoUrl == null
                      ? Text(
                          comment.author.nomeExibicao.characters.first
                              .toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => onAuthorTap(comment.author),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.author.nomeExibicao,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.content,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => onToggleLike(comment),
                            child: Text(
                              comment.likedByMe
                                  ? 'Curtido (${comment.likeCount})'
                                  : 'Curtir (${comment.likeCount})',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: comment.likedByMe
                                    ? AppColors.danger
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          if (!isReply)
                            GestureDetector(
                              onTap: () => onReply(comment),
                              child: const Text(
                                'Responder',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...comment.replies.map(
              (reply) => _CommentThread(
                comment: reply,
                onAuthorTap: onAuthorTap,
                onReply: onReply,
                onToggleLike: onToggleLike,
                isReply: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
