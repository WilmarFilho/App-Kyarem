import 'package:flutter/material.dart';

import '../../../models/campeonato_model.dart';
import '../../../models/modalidade_model.dart';
import '../../../services/modalidade_service.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';
import '../modalidade/partidas_modalidade_screen.dart';

class ModalidadesScreen extends StatefulWidget {
  final Campeonato campeonato;
  final bool isMainScreenChild;

  const ModalidadesScreen({
    super.key, 
    required this.campeonato,
    this.isMainScreenChild = false,
  });

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
      backgroundColor: const Color(0xFF260404),
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
        title: const Text(
          'Modalidades',
          style: TextStyle(
            fontFamily: 'Oswald',
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF110101),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const GradientBackground(),
          FutureBuilder<List<Modalidade>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF22F1D)),
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
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF22F1D),
                            foregroundColor: Colors.white,
                          ),
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
                color: const Color(0xFFF22F1D),
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(18, 18, 18, widget.isMainScreenChild ? 80 : 100),
                  itemCount: modalidades.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final m = modalidades[i];
                    final titulo = (m.nome ?? 'Modalidade').trim().isNotEmpty
                        ? m.nome!
                        : 'Modalidade';
                    final subtitulo = (m.esporteNome ?? '').trim();

                    return Material(
                      color: const Color(0xFF110101),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PartidasModalidadeScreen(
                                modalidade: m,
                                campeonatoNome: widget.campeonato.nome,
                              ),
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
                                  color: const Color(
                                    0xFFF22F1D,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.sports,
                                  color: Color(0xFFF22F1D),
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
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (subtitulo.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        subtitulo,
                                        style: const TextStyle(
                                          color: Colors.white54,
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
                                color: Colors.white30,
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
          if (!widget.isMainScreenChild)
            const Align(
              alignment: Alignment.bottomCenter,
              child: BottomNavigationWidget(currentRoute: '/modalidades'),
            ),
        ],
      ),
    );
  }
}
