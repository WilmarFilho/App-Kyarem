import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../models/social_models.dart';

class SocialPostCard extends StatelessWidget {
  const SocialPostCard({
    super.key,
    required this.post,
    required this.onAuthorTap,
    required this.onToggleLike,
    required this.onOpenComments,
  });

  final SocialPost post;
  final ValueChanged<SocialAuthor> onAuthorTap;
  final Future<void> Function(SocialPost post) onToggleLike;
  final VoidCallback onOpenComments;

  @override
  Widget build(BuildContext context) {
    final athleticLabel = post.author.atleticaNome?.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => onAuthorTap(post.author),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFE9EEF7),
                      backgroundImage: post.author.fotoUrl != null
                          ? NetworkImage(post.author.fotoUrl!)
                          : null,
                      child: post.author.fotoUrl == null
                          ? Text(
                              _initials(post.author.nomeExibicao),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onAuthorTap(post.author),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.author.nomeExibicao,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          if (athleticLabel != null && athleticLabel.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              athleticLabel,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(post.createdAt),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (post.content != null && post.content!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Text(
                  post.content!,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.55,
                  ),
                ),
              ),
            if (post.imageUrl != null && post.imageUrl!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: Image.network(
                  post.imageUrl!,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  _EngagementPill(
                    icon: post.likedByMe
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: '${post.likeCount}',
                    active: post.likedByMe,
                    onTap: () => onToggleLike(post),
                  ),
                  const SizedBox(width: 8),
                  _EngagementPill(
                    icon: Icons.mode_comment_outlined,
                    label: '${post.commentCount}',
                    onTap: onOpenComments,
                  ),
                ],
              ),
            ),
            if (post.commentPreview.isNotEmpty) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFE),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...post.commentPreview.map(
                        (comment) => _CommentTile(
                          comment: comment,
                          onAuthorTap: onAuthorTap,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: onOpenComments,
                        child: const Text(
                          'Ver conversa completa',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: InkWell(
                onTap: onOpenComments,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Escrever comentário...',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.send_rounded,
                        color: AppColors.secondary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String _formatDate(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    if (difference.inMinutes < 1) return 'agora';
    if (difference.inHours < 1) return 'há ${difference.inMinutes} min';
    if (difference.inDays < 1) return 'há ${difference.inHours} h';
    if (difference.inDays == 1) return 'ontem';
    return '${difference.inDays} d';
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onAuthorTap,
    this.isReply = false,
  });

  final SocialComment comment;
  final ValueChanged<SocialAuthor> onAuthorTap;
  final bool isReply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isReply ? 0 : 12,
        left: isReply ? 18 : 0,
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
                  radius: isReply ? 14 : 16,
                  backgroundColor: const Color(0xFFE9EEF7),
                  backgroundImage: comment.author.fotoUrl != null
                      ? NetworkImage(comment.author.fotoUrl!)
                      : null,
                  child: comment.author.fotoUrl == null
                      ? Text(
                          comment.author.nomeExibicao.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
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
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            comment.author.nomeExibicao,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          if (comment.author.atleticaNome != null &&
                              comment.author.atleticaNome!.trim().isNotEmpty)
                            Text(
                              comment.author.atleticaNome!,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: AppColors.secondary,
                              ),
                            ),
                        ],
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
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...comment.replies.map(
              (reply) => _CommentTile(
                comment: reply,
                onAuthorTap: onAuthorTap,
                isReply: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EngagementPill extends StatelessWidget {
  const _EngagementPill({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AppColors.danger.withValues(alpha: 0.08)
                : const Color(0xFFF7FAFE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? AppColors.danger : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.danger : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
