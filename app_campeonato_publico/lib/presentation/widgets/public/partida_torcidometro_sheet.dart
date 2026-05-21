import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_colors.dart';
import '../../../services/game_service.dart';
import '../../../services/public_interaction_service.dart';

class PartidaTorcidometroSheet extends StatefulWidget {
  final String partidaId;
  final String timeA;
  final String timeB;
  final String? escudoTimeA;
  final String? escudoTimeB;

  const PartidaTorcidometroSheet({
    super.key,
    required this.partidaId,
    required this.timeA,
    required this.timeB,
    this.escudoTimeA,
    this.escudoTimeB,
  });

  @override
  State<PartidaTorcidometroSheet> createState() =>
      _PartidaTorcidometroSheetState();
}

class _PartidaTorcidometroSheetState extends State<PartidaTorcidometroSheet> {
  final _supabase = Supabase.instance.client;
  final _interactionService = PublicInteractionService();
  final _gameService = GameService();

  Map<String, dynamic>? _equipes;
  bool _isLoadingMeta = true;
  bool _isVoting = false;
  String? _selectedAtleticaId;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    try {
      final equipes = await _gameService.getPartidaEquipes(widget.partidaId);
      final saved = await _interactionService.getSavedPartidaTorcida(
        widget.partidaId,
      );
      if (!mounted) return;
      setState(() {
        _equipes = equipes;
        _selectedAtleticaId = saved;
        _isLoadingMeta = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMeta = false);
    }
  }

  Future<void> _vote(String atleticaId) async {
    setState(() => _isVoting = true);
    try {
      await _interactionService.submitPartidaTorcida(
        partidaId: widget.partidaId,
        atleticaId: atleticaId,
      );
      if (!mounted) return;
      setState(() => _selectedAtleticaId = atleticaId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Torcida registrada com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isVoting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.74,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 46,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.campaign_outlined, color: AppColors.orange),
                SizedBox(width: 10),
                Text(
                  'Torcidômetro da partida',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.bgDeep,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingMeta
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _supabase
                        .from('partida_torcida_votos')
                        .stream(primaryKey: ['id'])
                        .eq('partida_id', widget.partidaId),
                    builder: (context, snapshot) {
                      final votes =
                          snapshot.data ?? const <Map<String, dynamic>>[];
                      final atleticaAId = _equipes?['atletica_a_id']?.toString();
                      final atleticaBId = _equipes?['atletica_b_id']?.toString();
                      final votosA = votes
                          .where((v) => v['atletica_id']?.toString() == atleticaAId)
                          .length;
                      final votosB = votes
                          .where((v) => v['atletica_id']?.toString() == atleticaBId)
                          .length;
                      final total = votosA + votosB;
                      final percentA = total == 0 ? 0.0 : votosA / total;
                      final percentB = total == 0 ? 0.0 : votosB / total;

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          children: [
                            _TorcidaTeamVoteCard(
                              teamName: widget.timeA,
                              shieldUrl: widget.escudoTimeA,
                              voteCount: votosA,
                              percentage: percentA,
                              isSelected: _selectedAtleticaId == atleticaAId,
                              onTap: atleticaAId == null || _isVoting
                                  ? null
                                  : () => _vote(atleticaAId),
                            ),
                            const SizedBox(height: 12),
                            _TorcidaTeamVoteCard(
                              teamName: widget.timeB,
                              shieldUrl: widget.escudoTimeB,
                              voteCount: votosB,
                              percentage: percentB,
                              isSelected: _selectedAtleticaId == atleticaBId,
                              onTap: atleticaBId == null || _isVoting
                                  ? null
                                  : () => _vote(atleticaBId),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFE8EDF5),
                                ),
                              ),
                              child: Text(
                                total == 0
                                    ? 'Ainda não há torcida registrada. Seja o primeiro a marcar presença.'
                                    : '$total torcida(s) já registradas nesta partida.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: AppColors.bgDeep,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TorcidaTeamVoteCard extends StatelessWidget {
  final String teamName;
  final String? shieldUrl;
  final int voteCount;
  final double percentage;
  final bool isSelected;
  final VoidCallback? onTap;

  const _TorcidaTeamVoteCard({
    required this.teamName,
    this.shieldUrl,
    required this.voteCount,
    required this.percentage,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percentLabel = '${(percentage * 100).toStringAsFixed(0)}%';
    final hasShield = shieldUrl != null && shieldUrl!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.orange.withValues(alpha: 0.1)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.orange : const Color(0xFFE8EDF5),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  backgroundImage: hasShield ? NetworkImage(shieldUrl!) : null,
                  child: !hasShield
                      ? Text(
                          teamName.isNotEmpty ? teamName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: AppColors.bgDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    teamName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.bgDeep,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, color: AppColors.orange),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(AppColors.orange),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '$voteCount voto(s)',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  percentLabel,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: AppColors.bgDeep,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
