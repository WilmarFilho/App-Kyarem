import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // Sugestões padrão (links rápidos para outras áreas)
  final List<Map<String, dynamic>> _quickLinks = [
    {
      'title': 'Explorar Modalidades',
      'icon': Icons.sports_soccer,
      'route': '/modalidades',
    },
    {'title': 'Meu Perfil', 'icon': Icons.person_outline, 'route': '/perfil'},
    {
      'title': 'Configurações',
      'icon': Icons.settings_outlined,
      'route': '/configuracoes',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Lógica para filtrar as sugestões baseado no que é digitado
  List<Map<String, dynamic>> get _filteredLinks {
    if (_query.trim().isEmpty) return _quickLinks;

    final queryLower = _query.toLowerCase();
    return _quickLinks.where((link) {
      final titleLower = link['title'].toString().toLowerCase();
      return titleLower.contains(queryLower);
    }).toList();
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
    final results = _filteredLinks;

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
            // Fecha a tela de busca e navega para a rota sugerida
            if (mounted) {
              Navigator.pop(context);
              Navigator.pushNamed(context, item['route']);
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
                  child: Text(
                    item['title'],
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF260404),
                    ),
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
