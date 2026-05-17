import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';

class PartidaMock {
  final String esporte;
  final IconData esporteIcon;
  final String campeonatoNome;
  final String campeonatoAvatarUrl;
  final String timeA;
  final String timeB;
  final String horario;
  final String dia;
  final bool aoVivo;
  final String? placarA;
  final String? placarB;

  const PartidaMock({
    required this.esporte,
    required this.esporteIcon,
    required this.campeonatoNome,
    required this.campeonatoAvatarUrl,
    required this.timeA,
    required this.timeB,
    required this.horario,
    required this.dia,
    this.aoVivo = false,
    this.placarA,
    this.placarB,
  });
}

class PartidaCardWidget extends StatefulWidget {
  const PartidaCardWidget({super.key, required this.partida});

  final PartidaMock partida;

  @override
  State<PartidaCardWidget> createState() => _PartidaCardWidgetState();
}

class _PartidaCardWidgetState extends State<PartidaCardWidget> {
  bool _isFavorite = false;
  bool _isNotificationEnabled = false;

  @override
  Widget build(BuildContext context) {
    final partida = widget.partida;
    final isLive = partida.aoVivo;

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
          onTap: () {},
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
                                      partida.esporteIcon,
                                      size: 13,
                                      color: AppColors.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      partida.esporte,
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
                                backgroundImage: NetworkImage(
                                  partida.campeonatoAvatarUrl,
                                ),
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
                      '${partida.dia}  •  ${partida.horario}',
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
                            child: Text(
                              partida.timeA,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                fontFamily: 'Poppins',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                            child:
                                (partida.placarA != null &&
                                    partida.placarB != null)
                                ? Text(
                                    '${partida.placarA}  ×  ${partida.placarB}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isLive
                                          ? AppColors.danger
                                          : AppColors.primary,
                                      fontFamily: 'Poppins',
                                      letterSpacing: 0.5,
                                    ),
                                  )
                                : const Text(
                                    'VS',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMuted,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                          ),
                          Expanded(
                            child: Text(
                              partida.timeB,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                fontFamily: 'Poppins',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _CardActionButton(
                        icon: _isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        active: _isFavorite,
                        onTap: () {
                          setState(() => _isFavorite = !_isFavorite);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CardActionButton(
                        icon: _isNotificationEnabled
                            ? Icons.notifications_rounded
                            : Icons.notifications_none_rounded,
                        active: _isNotificationEnabled,
                        onTap: () {
                          setState(
                            () => _isNotificationEnabled =
                                !_isNotificationEnabled,
                          );
                        },
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
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.secondary : const Color(0xFFF8FBFF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: active ? AppColors.secondary : const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? AppColors.secondary
                  : const Color(0xFFEBEFF4),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: active ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
