import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/campeonato_atletica_publica_model.dart';
import '../../../models/modalidade_model.dart';
import '../../../services/atletica_public_service.dart';
import '../../../services/modalidade_service.dart';
import '../atletica/atletica_detalhe_screen.dart';
import '../modalidade/partidas_modalidade_screen.dart';

class SearchScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const SearchScreen({super.key, this.onNavigateToTab});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ModalidadeService _modalidadeService = ModalidadeService();
  final AtleticaPublicService _atleticaService = AtleticaPublicService();
  String _query = '';
  List<Modalidade> _modalidades = [];
  List<CampeonatoAtleticaPublica> _atleticas = [];
  bool _isLoadingModalidades = true;
  bool _isLoadingAtleticas = true;

  // Sugestões padrão (links rápidos para outras áreas)
  final List<Map<String, dynamic>> _quickLinks = [
    {
      'title': 'Explorar Modalidades',
      'icon': Icons.sports_soccer,
      'tabIndex': 1,
      'type': 'tab',
    },
    {
      'title': 'Atléticas',
      'icon': Icons.groups_rounded,
      'tabIndex': 2,
      'type': 'tab',
    },
    {
      'title': 'Configurações',
      'icon': Icons.settings_outlined,
      'tabIndex': 3,
      'type': 'tab',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadModalidades();
    _loadAtleticas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadModalidades() async {
    try {
      final modalidades = await _modalidadeService.getModalities();
      if (!mounted) return;
      setState(() {
        _modalidades = modalidades;
        _isLoadingModalidades = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _modalidades = [];
        _isLoadingModalidades = false;
      });
    }
  }

  Future<void> _loadAtleticas() async {
    try {
      final atleticas = await _atleticaService.getAthletics();
      if (!mounted) return;
      setState(() {
        _atleticas = atleticas;
        _isLoadingAtleticas = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _atleticas = [];
        _isLoadingAtleticas = false;
      });
    }
  }

  List<Map<String, dynamic>> get _allItems {
    final modalidadeItems = _modalidades.map((modalidade) {
      final titulo = (modalidade.nome ?? 'Modalidade').trim();
      final subtitulo = (modalidade.esporteNome ?? '').trim();

      return <String, dynamic>{
        'title': titulo.isEmpty ? 'Modalidade' : titulo,
        'subtitle': subtitulo,
        'icon': _resolveIcon(modalidade.nome ?? modalidade.esporteNome ?? ''),
        'type': 'modalidade',
        'modalidade': modalidade,
      };
    });

    final atleticaItems = _atleticas.map((atletica) {
      return <String, dynamic>{
        'title': atletica.nome,
        'subtitle': atletica.sigla ?? 'Atlética inscrita',
        'icon': Icons.groups_rounded,
        'type': 'atletica',
        'atletica': atletica,
      };
    });

    return [..._quickLinks, ...modalidadeItems, ...atleticaItems];
  }

  // Lógica para filtrar as sugestões baseado no que é digitado
  List<Map<String, dynamic>> get _filteredItems {
    final items = _allItems;
    if (_query.trim().isEmpty) return items;

    final queryLower = _query.toLowerCase();
    return items.where((item) {
      final titleLower = item['title'].toString().toLowerCase();
      final subtitleLower = item['subtitle'].toString().toLowerCase();
      return titleLower.contains(queryLower) || subtitleLower.contains(queryLower);
    }).toList();
  }

  IconData _resolveIcon(String nome) {
    final nomeUpper = nome.toUpperCase();

    if (nomeUpper.contains('FUTSAL') || nomeUpper.contains('FUTEBOL')) {
      return Icons.sports_soccer;
    }
    if (nomeUpper.contains('VOLEI') || nomeUpper.contains('VÔLEI')) {
      return Icons.sports_volleyball;
    }
    if (nomeUpper.contains('BASQUETE') || nomeUpper.contains('BASKET')) {
      return Icons.sports_basketball;
    }
    if (nomeUpper.contains('HANDEBOL')) {
      return Icons.sports_handball;
    }
    if (nomeUpper.contains('TENIS') || nomeUpper.contains('TÊNIS')) {
      return Icons.sports_tennis;
    }

    return Icons.sports;
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold inteiro branco conforme solicitado
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // BARRA SUPERIOR (Search + Close)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  // Ícone de fechar (desce a tela novamente)
                  IconButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_up,
                      color: Color(0xFF555555),
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),

                  // Container de Busca (Input)
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.search,
                            color: Color(0xFF999999),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus:
                                  true, // Abre o teclado instantaneamente
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: Color(0xFF333333),
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Buscar partidas, times...',
                                hintStyle: TextStyle(color: Color(0xFF999999)),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _query = val;
                                });
                              },
                            ),
                          ),
                          if (_query.isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Color(0xFF999999),
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _query = '';
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // CONTEÚDO (Lista de sugestões)
            Expanded(child: _buildBodyContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    final results = _filteredItems;

    if (_isLoadingModalidades || _isLoadingAtleticas) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF22F1D)),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 60, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 16),
            Text(
              'Nenhum resultado encontrado.',
              style: GoogleFonts.oswald(
                fontSize: 20,
                color: const Color(0xFF555555),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return _buildSuggestionCard(item);
      },
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFFF22F1D).withValues(alpha: 0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            final type = item['type'] as String?;

            if (type == 'modalidade') {
              final modalidade = item['modalidade'] as Modalidade?;
              if (modalidade == null) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PartidasModalidadeScreen(modalidade: modalidade),
                ),
              );
              return;
            }

            if (type == 'atletica') {
              final atletica = item['atletica'] as CampeonatoAtleticaPublica?;
              if (atletica == null) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => AtleticaDetalheScreen(atletica: atletica),
                ),
              );
              return;
            }

            final tabIndex = item['tabIndex'] as int?;
            Navigator.pop(context);

            if (tabIndex != null && widget.onNavigateToTab != null) {
              widget.onNavigateToTab!(tabIndex);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF22F1D).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: const Color(0xFFF22F1D),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'],
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF260404),
                        ),
                      ),
                      if ((item['subtitle']?.toString().trim().isNotEmpty ?? false))
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            item['subtitle'],
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF777777),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
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
