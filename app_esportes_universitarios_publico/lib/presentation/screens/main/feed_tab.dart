import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';

class _FeedComment {
  final String author;
  final String athletic;
  final String avatarUrl;
  final String text;
  final String timeLabel;
  final List<_FeedComment> replies;

  const _FeedComment({
    required this.author,
    required this.athletic,
    required this.avatarUrl,
    required this.text,
    required this.timeLabel,
    this.replies = const [],
  });
}

class _FeedPost {
  final String author;
  final String athletic;
  final String avatarUrl;
  final String timeLabel;
  final String text;
  final String? imageUrl;
  final int likes;
  final int comments;
  final int shares;
  final bool liked;
  final List<_FeedComment> commentPreview;

  const _FeedPost({
    required this.author,
    required this.athletic,
    required this.avatarUrl,
    required this.timeLabel,
    required this.text,
    this.imageUrl,
    required this.likes,
    required this.comments,
    required this.shares,
    this.liked = false,
    this.commentPreview = const [],
  });
}

const _feedPosts = [
  _FeedPost(
    author: 'Marina Costa',
    athletic: 'Torcedora da AAAFEI',
    avatarUrl: 'https://i.pravatar.cc/160?img=12',
    timeLabel: 'Hoje, 14:12',
    text:
        'A energia no ginásio está absurda. AAAFEI começou pressionando desde o aquecimento e a bateria da torcida não parou um segundo.',
    likes: 128,
    comments: 18,
    shares: 7,
    liked: true,
    commentPreview: [
      _FeedComment(
        author: 'Leo Martins',
        athletic: 'CAASO',
        avatarUrl: 'https://i.pravatar.cc/160?img=24',
        text: 'Esse clima de jogo universitário é bom demais.',
        timeLabel: 'há 12 min',
        replies: [
          _FeedComment(
            author: 'Marina Costa',
            athletic: 'AAAFEI',
            avatarUrl: 'https://i.pravatar.cc/160?img=12',
            text: 'Total. E o pessoal ainda promete mosaico no segundo tempo.',
            timeLabel: 'há 8 min',
          ),
        ],
      ),
    ],
  ),
  _FeedPost(
    author: 'João Vilela',
    athletic: 'Torcedor da AAAUSP',
    avatarUrl: 'https://i.pravatar.cc/160?img=33',
    timeLabel: 'Hoje, 13:41',
    text:
        'Chegada das delegações no complexo. Organização caprichou demais nessa entrada.',
    imageUrl: 'https://picsum.photos/seed/delegacoes-feed/900/620',
    likes: 206,
    comments: 31,
    shares: 14,
    commentPreview: [
      _FeedComment(
        author: 'Bia Nogueira',
        athletic: 'UNESP Rio Claro',
        avatarUrl: 'https://i.pravatar.cc/160?img=41',
        text: 'Ficou lindo. A cobertura visual desse evento está muito boa.',
        timeLabel: 'há 20 min',
      ),
      _FeedComment(
        author: 'Gui Teles',
        athletic: 'Atlética Medicina',
        avatarUrl: 'https://i.pravatar.cc/160?img=56',
        text: 'Quero ver a quadra principal à noite também.',
        timeLabel: 'há 16 min',
      ),
    ],
  ),
  _FeedPost(
    author: 'Ana Luiza',
    athletic: 'Torcedora da AAUNICAMP',
    avatarUrl: 'https://i.pravatar.cc/160?img=47',
    timeLabel: 'Ontem, 22:08',
    text:
        'Resumo do dia: vôlei decidido no detalhe, ginásio cheio e muita gente nova conhecendo as atléticas pela primeira vez. Esse tipo de evento aproxima demais.',
    imageUrl: 'https://picsum.photos/seed/volei-noturno/900/620',
    likes: 94,
    comments: 12,
    shares: 5,
    commentPreview: [
      _FeedComment(
        author: 'Carol Prado',
        athletic: 'Torcedora da CAAFEA',
        avatarUrl: 'https://i.pravatar.cc/160?img=18',
        text: 'As fotos da noite ficaram incríveis.',
        timeLabel: 'há 1 h',
        replies: [
          _FeedComment(
            author: 'Ana Luiza',
            athletic: 'AAUNICAMP',
            avatarUrl: 'https://i.pravatar.cc/160?img=47',
            text: 'Vou subir mais algumas depois. Te marco lá.',
            timeLabel: 'há 53 min',
          ),
        ],
      ),
    ],
  ),
];

class FeedTab extends StatelessWidget {
  const FeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        Row(
          children: [
            Text(
              'Feed',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.tune_rounded,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Acompanhe comentários, bastidores, fotos e reações das atléticas em tempo real.',
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
                      'Clima do evento',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFAFC7F3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Torcida aquecida, quadras lotando e muita postagem nova subindo agora.',
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
                      children: const [
                        _StatusChip(label: '128 posts hoje'),
                        _StatusChip(label: '36 fotos novas'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.dynamic_feed_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ..._feedPosts.map((post) => _FeedPostCard(post: post)),
      ],
    );
  }
}

class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({required this.post});

  final _FeedPost post;

  @override
  Widget build(BuildContext context) {
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
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(post.avatarUrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        post.athletic,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post.timeLabel,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              post.text,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.55,
              ),
            ),
          ),
          if (post.imageUrl != null) ...[
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
                  icon: post.liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: '${post.likes}',
                  active: post.liked,
                ),
                const SizedBox(width: 8),
                _EngagementPill(
                  icon: Icons.mode_comment_outlined,
                  label: '${post.comments}',
                ),
                const SizedBox(width: 8),
                _EngagementPill(
                  icon: Icons.repeat_rounded,
                  label: '${post.shares}',
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
                  children: post.commentPreview
                      .map((comment) => _CommentTile(comment: comment))
                      .toList(),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Escrever comentário...',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
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

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, this.isReply = false});

  final _FeedComment comment;
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
              CircleAvatar(
                radius: isReply ? 14 : 16,
                backgroundImage: NetworkImage(comment.avatarUrl),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          comment.author,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          comment.athletic,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.secondary,
                          ),
                        ),
                        Text(
                          comment.timeLabel,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.text,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                    if (!isReply) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Curtir  •  Responder',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...comment.replies.map(
              (reply) => _CommentTile(comment: reply, isReply: true),
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
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
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
