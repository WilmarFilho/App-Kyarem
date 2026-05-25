import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../models/partida_feed_item.dart';

class MatchDetailsScreen extends StatelessWidget {
  const MatchDetailsScreen({super.key, required this.partida});

  final PartidaFeedItem partida;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: const Text(
          'Detalhes da Partida',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreBoard(),
            const SizedBox(height: 24),
            _buildSectionTitle('Estatísticas da Partida'),
            const SizedBox(height: 12),
            _buildMockedStats(),
            const SizedBox(height: 24),
            _buildSectionTitle('Escalação'),
            const SizedBox(height: 12),
            _buildMockedLineup(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    final isLive = partida.isLive;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            partida.campeonatoNome,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _timeLabel(partida),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _TeamColumn(
                  name: partida.timeA,
                  logoUrl: partida.atleticaEscudoUrlA,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isLive ? AppColors.danger.withValues(alpha: 0.08) : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  partida.isLive || partida.placarA > 0 || partida.placarB > 0
                      ? '${partida.placarA}  ×  ${partida.placarB}'
                      : 'VS',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isLive ? AppColors.danger : AppColors.primary,
                  ),
                ),
              ),
              Expanded(
                child: _TeamColumn(
                  name: partida.timeB,
                  logoUrl: partida.atleticaEscudoUrlB,
                ),
              ),
            ],
          ),
          if ((partida.local ?? '').isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.place_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  partida.local!,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Bebas Neue',
        fontSize: 22,
        letterSpacing: 1,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildMockedStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        children: [
          _StatRow(label: 'Posse de Bola', valA: '45%', valB: '55%'),
          const Divider(height: 24, color: Color(0xFFE8EDF5)),
          _StatRow(label: 'Faltas', valA: '12', valB: '9'),
          const Divider(height: 24, color: Color(0xFFE8EDF5)),
          _StatRow(label: 'Cartões', valA: '2', valB: '1'),
        ],
      ),
    );
  }

  Widget _buildMockedLineup() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                5,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Jogador A${i + 1}',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                5,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Jogador B${i + 1}',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeLabel(PartidaFeedItem partida) {
    final date = partida.agendadoPara ?? partida.iniciadaEm ?? partida.encerradaEm;
    if (date == null) return partida.status;
    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} • $time';
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({required this.name, required this.logoUrl});

  final String name;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFF1F5FB),
          backgroundImage: logoUrl != null && logoUrl!.isNotEmpty ? NetworkImage(logoUrl!) : null,
          child: logoUrl == null || logoUrl!.isEmpty
              ? const Icon(Icons.shield_outlined, size: 28, color: AppColors.secondary)
              : null,
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.valA,
    required this.valB,
  });

  final String label;
  final String valA;
  final String valB;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(valA, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textMuted)),
        Text(valB, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
      ],
    );
  }
}
