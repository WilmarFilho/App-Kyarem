import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../models/partida_feed_item.dart';
import '../../screens/main/match_details_screen.dart';
import '../../../services/favorite_service.dart';

class PartidaCardWidget extends StatefulWidget {
  const PartidaCardWidget({super.key, required this.partida});

  final PartidaFeedItem partida;

  @override
  State<PartidaCardWidget> createState() => _PartidaCardWidgetState();
}

class _PartidaCardWidgetState extends State<PartidaCardWidget> {
  bool _isFavorite = false;
  bool _isNotificationEnabled = false;
  final _favoriteService = FavoriteService();

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final isFav = await _favoriteService.isFavorite(partidaId: widget.partida.id);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteService.currentUserId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para favoritar a partida')),
      );
      return;
    }

    final previousState = _isFavorite;
    setState(() {
      _isFavorite = !_isFavorite;
    });

    try {
      await _favoriteService.toggleFavorite(partidaId: widget.partida.id);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFavorite = previousState;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao favoritar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final partida = widget.partida;
    final isLive = partida.isLive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isLive
            ? Border.all(
                color: AppColors.danger.withValues(alpha: 0.4),
                width: 1.2,
              )
            : Border.all(color: const Color(0xFFEBEFF4), width: 1),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? AppColors.danger.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MatchDetailsScreen(partida: partida),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _iconForSport(partida.esporteNome),
                                      size: 13,
                                      color: AppColors.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      partida.esporteNome,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.secondary,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isLive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 6,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Ao vivo',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 13,
                                backgroundColor: AppColors.background,
                                backgroundImage: (partida.campeonatoEscudoUrl != null &&
                                        partida.campeonatoEscudoUrl!.isNotEmpty)
                                    ? NetworkImage(partida.campeonatoEscudoUrl!)
                                    : null,
                                child: (partida.campeonatoEscudoUrl == null ||
                                        partida.campeonatoEscudoUrl!.isEmpty)
                                    ? const Icon(
                                        Icons.emoji_events_rounded,
                                        size: 14,
                                        color: AppColors.secondary,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  partida.campeonatoNome,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                    fontFamily: 'Poppins',
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _timeLabel(partida),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _TeamBlock(
                              name: partida.timeA,
                              subtitle: partida.atleticaNomeA,
                              logoUrl: partida.atleticaEscudoUrlA,
                              alignEnd: false,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isLive
                                  ? AppColors.danger.withValues(alpha: 0.08)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              partida.isLive ||
                                      partida.placarA > 0 ||
                                      partida.placarB > 0
                                  ? '${partida.placarA}  ×  ${partida.placarB}'
                                  : 'VS',
                              style: TextStyle(
                                fontSize: partida.isLive ? 15 : 13,
                                fontWeight: FontWeight.w800,
                                color: isLive
                                    ? AppColors.danger
                                    : partida.placarA > 0 || partida.placarB > 0
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                                fontFamily: 'Poppins',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _TeamBlock(
                              name: partida.timeB,
                              subtitle: partida.atleticaNomeB,
                              logoUrl: partida.atleticaEscudoUrlB,
                              alignEnd: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if ((partida.local ?? '').isNotEmpty ||
                    (partida.fase ?? '').isNotEmpty ||
                    (partida.categoria ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if ((partida.local ?? '').isNotEmpty)
                        _MetaChip(
                          icon: Icons.place_outlined,
                          label: partida.local!,
                        ),
                      if ((partida.fase ?? '').isNotEmpty)
                        _MetaChip(
                          icon: Icons.flag_outlined,
                          label: partida.fase!,
                        ),
                      if ((partida.categoria ?? '').isNotEmpty)
                        _MetaChip(
                          icon: Icons.shield_outlined,
                          label: partida.categoria!,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _isNotificationEnabled =
                              !_isNotificationEnabled);
                        },
                        icon: Icon(
                          _isNotificationEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _isNotificationEnabled ? 'Acompanhando' : 'Alertar',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                            color: AppColors.secondary.withValues(alpha: 0.18),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _toggleFavorite,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF4F7FB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(
                        _isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: _isFavorite
                            ? const Color(0xFFF3B63F)
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForSport(String sport) {
    final normalized = sport.trim().toLowerCase();
    if (normalized.contains('volei')) return Icons.sports_volleyball;
    if (normalized.contains('basquete')) return Icons.sports_basketball;
    if (normalized.contains('handebol')) return Icons.sports_handball;
    if (normalized.contains('tenis')) return Icons.sports_tennis;
    if (normalized.contains('nat')) return Icons.pool_rounded;
    return Icons.sports_soccer;
  }

  String _timeLabel(PartidaFeedItem partida) {
    final date = partida.agendadoPara ?? partida.iniciadaEm ?? partida.encerradaEm;
    if (date == null) return partida.status;
    final now = DateTime.now();
    final day = DateUtils.dateOnly(date);
    final today = DateUtils.dateOnly(now);
    final tomorrow = today.add(const Duration(days: 1));
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final dayLabel = day == today
        ? 'Hoje'
        : day == tomorrow
        ? 'Amanhã'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    return '$dayLabel  •  $time';
  }
}

class _TeamBlock extends StatelessWidget {
  const _TeamBlock({
    required this.name,
    required this.subtitle,
    required this.logoUrl,
    required this.alignEnd,
  });

  final String name;
  final String? subtitle;
  final String? logoUrl;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!alignEnd) ...[
              _TeamAvatar(logoUrl: logoUrl),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: alignEnd ? TextAlign.end : TextAlign.start,
              ),
            ),
            if (alignEnd) ...[
              const SizedBox(width: 8),
              _TeamAvatar(logoUrl: logoUrl),
            ],
          ],
        ),
        if ((subtitle ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontFamily: 'Poppins',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          ),
        ],
      ],
    );
  }
}

class _TeamAvatar extends StatelessWidget {
  const _TeamAvatar({required this.logoUrl});

  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 12,
      backgroundColor: const Color(0xFFF1F5FB),
      backgroundImage:
          logoUrl != null && logoUrl!.isNotEmpty ? NetworkImage(logoUrl!) : null,
      child: logoUrl == null || logoUrl!.isEmpty
          ? const Icon(
              Icons.shield_outlined,
              size: 13,
              color: AppColors.secondary,
            )
          : null,
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
