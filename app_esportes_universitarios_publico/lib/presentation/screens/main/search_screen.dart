import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/app_colors.dart';
import '../../../../models/atletica.dart';
import '../../../../models/campeonato.dart';
import '../../../../models/user_profile.dart';
import '../../../../services/atletica_service.dart';
import '../../../../services/campeonato_service.dart';
import '../../../../services/profile_service.dart';
import 'public_profile_screen.dart';

// ── Enum de filtro ─────────────────────────────────────────────────────────────

enum _SearchFilter { todos, atleticas, campeonatos, perfis }

extension _SearchFilterExt on _SearchFilter {
  String get label {
    switch (this) {
      case _SearchFilter.todos:
        return 'Tudo';
      case _SearchFilter.atleticas:
        return 'Atléticas';
      case _SearchFilter.campeonatos:
        return 'Campeonatos';
      case _SearchFilter.perfis:
        return 'Perfis';
    }
  }

  IconData get icon {
    switch (this) {
      case _SearchFilter.todos:
        return Icons.search_rounded;
      case _SearchFilter.atleticas:
        return Icons.groups_rounded;
      case _SearchFilter.campeonatos:
        return Icons.emoji_events_rounded;
      case _SearchFilter.perfis:
        return Icons.person_search_rounded;
    }
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  final ProfileService _profileService = ProfileService();
  final AtleticaService _atleticaService = AtleticaService();
  final CampeonatoService _campeonatoService = CampeonatoService();

  Timer? _debounce;
  String _query = '';
  bool _loading = false;
  _SearchFilter _filter = _SearchFilter.todos;

  List<UserProfile> _profiles = const [];
  List<Atletica> _atleticas = const [];
  List<Campeonato> _campeonatos = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── Busca ──────────────────────────────────────────────────────────────────

  void _onChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _profiles = const [];
        _atleticas = const [];
        _campeonatos = const [];
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 380), _search);
  }

  Future<void> _search() async {
    final q = _query.trim();
    if (q.isEmpty) return;
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        // Perfis — só busca se filtro for todos ou perfis
        if (_filter == _SearchFilter.todos || _filter == _SearchFilter.perfis)
          _profileService.searchProfiles(q)
        else
          Future.value(<UserProfile>[]),

        // Atléticas — client-side filter na lista completa
        if (_filter == _SearchFilter.todos ||
            _filter == _SearchFilter.atleticas)
          _atleticaService.getAtleticas()
        else
          Future.value(<Atletica>[]),

        // Campeonatos — client-side filter
        if (_filter == _SearchFilter.todos ||
            _filter == _SearchFilter.campeonatos)
          _campeonatoService.getCampeonatos()
        else
          Future.value(<Campeonato>[]),
      ]);

      if (!mounted) return;

      final ql = q.toLowerCase();
      setState(() {
        _profiles = (results[0] as List<UserProfile>);
        _atleticas = (results[1] as List<Atletica>)
            .where(
              (a) =>
                  a.nome.toLowerCase().contains(ql) ||
                  (a.sigla?.toLowerCase().contains(ql) ?? false),
            )
            .toList();
        _campeonatos = (results[2] as List<Campeonato>)
            .where((c) => c.nome.toLowerCase().contains(ql))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _clearQuery() {
    _ctrl.clear();
    _onChanged('');
    _focus.requestFocus();
  }

  void _setFilter(_SearchFilter f) {
    setState(() => _filter = f);
    if (_query.trim().isNotEmpty) _search();
  }

  // ── Navegação ──────────────────────────────────────────────────────────────

  void _openProfile(UserProfile profile) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          profileId: profile.id,
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasQuery = _query.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de busca
            _buildSearchBar(),

            // Filtros / tags
            _buildFilterRow(hasQuery),

            // Conteúdo
            Expanded(child: hasQuery ? _buildResults() : _buildEmptyState()),
          ],
        ),
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF555555),
              size: 30,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF99AABB),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      autofocus: true,
                      cursorColor: AppColors.primary,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: _hintForFilter(),
                        hintStyle: const TextStyle(
                          color: Color(0xFF99AABB),
                          fontFamily: 'Poppins',
                          fontSize: 13,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: _onChanged,
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: _clearQuery,
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDE3EE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textMuted,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _hintForFilter() {
    switch (_filter) {
      case _SearchFilter.todos:
        return 'Buscar atléticas, campeonatos, perfis...';
      case _SearchFilter.atleticas:
        return 'Buscar atléticas...';
      case _SearchFilter.campeonatos:
        return 'Buscar campeonatos...';
      case _SearchFilter.perfis:
        return 'Buscar perfis...';
    }
  }

  // ── Filtros ────────────────────────────────────────────────────────────────

  Widget _buildFilterRow(bool hasQuery) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _SearchFilter.values.map((f) {
          final selected = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _setFilter(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: selected ? AppColors.secondary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppColors.secondary
                        : const Color(0xFFDDE3EE),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      f.icon,
                      size: 13,
                      color: selected ? Colors.white : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      f.label,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    // Botão X para limpar o filtro (apenas quando digitando e
                    // esse filtro está selecionado e não é "Tudo")
                    if (selected && hasQuery && f != _SearchFilter.todos) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _setFilter(_SearchFilter.todos),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Estado vazio (sem query) ───────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecione uma categoria ou pesquise livremente.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // ── Resultados ─────────────────────────────────────────────────────────────

  Widget _buildResults() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      );
    }

    final totalCount =
        _profiles.length + _atleticas.length + _campeonatos.length;

    if (totalCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 56,
                color: Color(0xFFCCCCCC),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum resultado para "$_query"',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tente outro termo ou mude o filtro.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        // ─ Atléticas ─
        if (_atleticas.isNotEmpty) ...[
          _SectionHeader(
            label: 'Atléticas',
            count: _atleticas.length,
            icon: Icons.groups_rounded,
          ),
          const SizedBox(height: 8),
          ..._atleticas.map((a) => _AtleticaResultCard(atletica: a)),
          const SizedBox(height: 16),
        ],

        // ─ Campeonatos ─
        if (_campeonatos.isNotEmpty) ...[
          _SectionHeader(
            label: 'Campeonatos',
            count: _campeonatos.length,
            icon: Icons.emoji_events_rounded,
          ),
          const SizedBox(height: 8),
          ..._campeonatos.map((c) => _CampeonatoResultCard(campeonato: c)),
          const SizedBox(height: 16),
        ],

        // ─ Perfis ─
        if (_profiles.isNotEmpty) ...[
          _SectionHeader(
            label: 'Perfis',
            count: _profiles.length,
            icon: Icons.person_search_rounded,
          ),
          const SizedBox(height: 8),
          ..._profiles.map(
            (p) => _ProfileResultCard(profile: p, onTap: () => _openProfile(p)),
          ),
        ],
      ],
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    required this.icon,
  });

  final String label;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.secondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _AtleticaResultCard extends StatelessWidget {
  const _AtleticaResultCard({required this.atletica});
  final Atletica atletica;

  @override
  Widget build(BuildContext context) {
    final Color cor = atletica.corPrincipal != null
        ? Color(
            int.tryParse(atletica.corPrincipal!.replaceFirst('#', '0xFF')) ??
                0xFF1667FF,
          )
        : AppColors.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Escudo ou iniciais
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: atletica.escudoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            atletica.escudoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.groups_rounded,
                              color: cor,
                              size: 22,
                            ),
                          ),
                        )
                      : Icon(Icons.groups_rounded, color: cor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        atletica.nome,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      if (atletica.sigla != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          atletica.sigla!,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _StatusPill(status: atletica.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CampeonatoResultCard extends StatelessWidget {
  const _CampeonatoResultCard({required this.campeonato});
  final Campeonato campeonato;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.secondary, Color(0xFF6EA3FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: campeonato.escudoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            campeonato.escudoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campeonato.nome,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      if (campeonato.edicao != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Edição ${campeonato.edicao}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _StatusPill(status: campeonato.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileResultCard extends StatelessWidget {
  const _ProfileResultCard({required this.profile, required this.onTap});
  final UserProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: const Color(0xFFEAF0FA),
                  backgroundImage: profile.fotoUrl != null
                      ? NetworkImage(profile.fotoUrl!)
                      : null,
                  child: profile.fotoUrl == null
                      ? Text(
                          profile.nomeExibicao.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.nomeExibicao,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _roleLabel(profile.role),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role.trim().toUpperCase()) {
      case 'ATHLETE':
        return 'Atleta';
      case 'DIRECTOR':
        return 'Diretoria';
      case 'PRESIDENT':
        return 'Presidente';
      case 'ADMIN':
        return 'Admin';
      default:
        return 'Perfil';
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.trim().toUpperCase();
    Color color;
    String label;

    if (s == 'ATIVA' || s == 'ACTIVE' || s == 'EM_ANDAMENTO') {
      color = AppColors.success;
      label = 'Ativo';
    } else if (s == 'INATIVA' || s == 'INACTIVE') {
      color = AppColors.textMuted;
      label = 'Inativo';
    } else {
      color = AppColors.secondary;
      label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
