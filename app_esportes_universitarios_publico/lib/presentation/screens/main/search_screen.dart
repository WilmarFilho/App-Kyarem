import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // Sugestões rápidas
  final List<Map<String, dynamic>> _quickLinks = [
    {
      'title': 'Campeonatos',
      'subtitle': 'Ver todos os campeonatos ativos',
      'icon': Icons.emoji_events_rounded,
    },
    {
      'title': 'Atléticas',
      'subtitle': 'Explorar e seguir atléticas',
      'icon': Icons.groups_rounded,
    },
    {
      'title': 'Feed',
      'subtitle': 'Últimas novidades do ecossistema',
      'icon': Icons.dynamic_feed_rounded,
    },
  ];

  // Categorias de esporte
  final List<Map<String, dynamic>> _esportes = [
    {'nome': 'Futebol', 'icon': Icons.sports_soccer},
    {'nome': 'Futsal', 'icon': Icons.sports_soccer},
    {'nome': 'Vôlei', 'icon': Icons.sports_volleyball},
    {'nome': 'Basquete', 'icon': Icons.sports_basketball},
    {'nome': 'Handebol', 'icon': Icons.sports_handball},
    {'nome': 'Tênis', 'icon': Icons.sports_tennis},
    {'nome': 'Natação', 'icon': Icons.pool_rounded},
    {'nome': 'Atletismo', 'icon': Icons.directions_run_rounded},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredLinks {
    if (_query.trim().isEmpty) return _quickLinks;
    final q = _query.toLowerCase();
    return _quickLinks.where((item) {
      return item['title'].toString().toLowerCase().contains(q) ||
          item['subtitle'].toString().toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── barra superior
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
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
                              controller: _searchController,
                              autofocus: true,
                              cursorColor: AppColors.primary,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                hintText: 'Buscar campeonatos, atléticas...',
                                hintStyle: TextStyle(
                                  color: Color(0xFF99AABB),
                                  fontFamily: 'Poppins',
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (val) => setState(() => _query = val),
                            ),
                          ),
                          if (_query.isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF99AABB),
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── conteúdo
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  if (_query.isEmpty) ...[
                    // Esportes em destaque
                    Text(
                      'Esportes',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: _esportes.length,
                      itemBuilder: (context, i) {
                        final esporte = _esportes[i];
                        return InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  esporte['icon'] as IconData,
                                  size: 26,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  esporte['nome'] as String,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Links rápidos / resultados de busca
                  Text(
                    _query.isEmpty ? 'Atalhos' : 'Resultados',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_filteredLinks.isEmpty)
                    Padding(
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
                            'Nenhum resultado encontrado.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  else
                    ...(_filteredLinks.map((item) => _buildResultCard(item))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEFF4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        item['subtitle'] as String,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFFCCCCCC),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
