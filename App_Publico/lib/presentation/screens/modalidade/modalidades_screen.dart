import 'package:flutter/material.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';

import '../../../models/campeonato_model.dart';
import '../../../models/modalidade_model.dart';
import '../../../services/modalidade_service.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';
import 'partidas_modalidade_screen.dart';

class ModalidadesScreen extends StatefulWidget {
  final Campeonato campeonato;

  const ModalidadesScreen({super.key, required this.campeonato});

  @override
  State<ModalidadesScreen> createState() => _ModalidadesScreenState();
}

class _ModalidadesScreenState extends State<ModalidadesScreen> {
  final _service = ModalidadeService();
  late Future<List<Modalidade>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getModalities();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.getModalities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Voltar',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              return;
            }
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (route) => false);
          },
        ),
        title: Text(
          'Modalidades',
          style: const TextStyle(fontFamily: 'Bebas Neue', fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FutureBuilder<List<Modalidade>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final modalidades = snap.data ?? [];

              if (modalidades.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Nenhuma modalidade encontrada.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _reload,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _reload,
                color: AppColors.primary,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                  itemCount: modalidades.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final m = modalidades[i];
                    final titulo = (m.nome ?? 'Modalidade').trim().isNotEmpty
                        ? m.nome!
                        : 'Modalidade';
                    final subtitulo = (m.esporteNome ?? '').trim();

                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PartidasModalidadeScreen(modalidade: m),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.sports,
                                  color: Color(0xFFF85C39),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      titulo,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (subtitulo.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        subtitulo,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: BottomNavigationWidget(currentRoute: '/modalidades'),
          ),
        ],
      ),
    );
  }
}
