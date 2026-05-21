import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_colors.dart';
import '../../../models/campeonato_atletica_publica_model.dart';
import '../../../services/public_interaction_service.dart';

class AtleticaTorcidometroCard extends StatefulWidget {
  final CampeonatoAtleticaPublica atletica;

  const AtleticaTorcidometroCard({super.key, required this.atletica});

  @override
  State<AtleticaTorcidometroCard> createState() =>
      _AtleticaTorcidometroCardState();
}

class _AtleticaTorcidometroCardState extends State<AtleticaTorcidometroCard> {
  final _supabase = Supabase.instance.client;
  final _interactionService = PublicInteractionService();

  String? _selectedAtleticaId;
  bool _isVoting = false;

  bool get _hasValidIds =>
      widget.atletica.campeonatoAtleticaId.trim().isNotEmpty &&
      widget.atletica.atleticaId.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadSelection();
  }

  Future<void> _loadSelection() async {
    final value = await _interactionService.getSavedAtleticaTorcida(
      widget.atletica.campeonatoAtleticaId,
    );
    if (!mounted) return;
    setState(() => _selectedAtleticaId = value);
  }

  Future<void> _vote() async {
    if (!_hasValidIds) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta atlética ainda não está pronta para receber torcida neste campeonato.',
          ),
        ),
      );
      return;
    }

    setState(() => _isVoting = true);
    final isRemovingVote = _selectedAtleticaId == widget.atletica.atleticaId;
    try {
      await _interactionService.submitAtleticaTorcida(
        campeonatoAtleticaId: widget.atletica.campeonatoAtleticaId,
        atleticaId: widget.atletica.atleticaId,
        removeVote: isRemovingVote,
      );
      if (!mounted) return;
      setState(() {
        _selectedAtleticaId = isRemovingVote ? null : widget.atletica.atleticaId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isRemovingVote
                ? 'Seu voto de torcida foi removido.'
                : 'Torcida da atlética registrada!',
          ),
        ),
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
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('atletica_torcida_votos')
          .stream(primaryKey: ['id'])
          .eq('campeonato_atletica_id', widget.atletica.campeonatoAtleticaId),
      builder: (context, snapshot) {
        final votes = snapshot.data ?? const <Map<String, dynamic>>[];
        final total = votes.length;
        final isSelected = _selectedAtleticaId == widget.atletica.atleticaId;
        final canVote = _hasValidIds && !_isVoting;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TORCIDÔMETRO',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                total == 0
                    ? 'Ainda não há torcida registrada para esta atlética.'
                    : '$total torcida(s) já declararam apoio.',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: canVote ? _vote : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isSelected ? AppColors.orange : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isVoting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isSelected
                              ? Icons.remove_circle_outline_rounded
                              : Icons.campaign_outlined,
                        ),
                  label: Text(
                    isSelected
                        ? 'Remover minha torcida'
                        : _hasValidIds
                        ? 'Torcer por esta atlética'
                        : 'Torcida indisponível no momento',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
