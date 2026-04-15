import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import 'package:kyarem_eventos/models/atleta_model.dart';
import '../../../services/admin_api_service.dart';
import 'atleta_form_screen.dart';

class InscritosEquipeScreen extends StatefulWidget {
  final Equipe equipe;

  const InscritosEquipeScreen({super.key, required this.equipe});

  @override
  State<InscritosEquipeScreen> createState() => _InscritosEquipeScreenState();
}

class _InscritosEquipeScreenState extends State<InscritosEquipeScreen> {
  final AdminApiService _apiService = AdminApiService();
  List<dynamic> _inscritos = [];
  bool _isLoading = true;

  // ─── Limites ───
  static const int _maxCapitoes = 1;
  static const int _maxGoleiros = 2;

  @override
  void initState() {
    super.initState();
    _carregarInscritos();
  }

  Future<void> _carregarInscritos() async {
    setState(() => _isLoading = true);
    final lista = await _apiService.listarInscritos(widget.equipe.id);
    setState(() {
      _inscritos = lista;
      _isLoading = false;
    });
  }

  // ── Contagens atuais ──
  int get _totalCapitoes => _inscritos.where((i) => i['isCapitao'] == true).length;
  int get _totalGoleiros => _inscritos.where((i) => i['isGoleiro'] == true).length;

  Future<void> _removerInscrito(String inscritoId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remover Atleta?'),
        content: const Text('O atleta será removido deste time, mas continuará cadastrado na base.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final sucesso = await _apiService.removerInscrito(widget.equipe.id, inscritoId);
      if (sucesso) {
        _carregarInscritos();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao remover inscrito.')),
          );
        }
      }
    }
  }

  Future<void> _toggleCapitao(Map<String, dynamic> inscrito) async {
    final isCapitaoAtual = inscrito['isCapitao'] == true;

    // Se está tentando ATIVAR e já bateu o limite
    if (!isCapitaoAtual && _totalCapitoes >= _maxCapitoes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Já existe um capitão neste time. Remova o atual antes de atribuir outro.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1A1A2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final novoValor = !isCapitaoAtual;
    final res = await _apiService.atualizarInscrito(
      widget.equipe.id,
      inscrito['id'].toString(),
      isCapitao: novoValor,
    );

    if (res != null) {
      _carregarInscritos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(novoValor ? '${inscrito['atletaNome']} definido como capitão!' : 'Capitão removido.'),
            backgroundColor: novoValor ? Colors.amber.shade700 : Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar função do atleta.')),
        );
      }
    }
  }

  Future<void> _toggleGoleiro(Map<String, dynamic> inscrito) async {
    final isGoleiroAtual = inscrito['isGoleiro'] == true;

    // Se está tentando ATIVAR e já bateu o limite
    if (!isGoleiroAtual && _totalGoleiros >= _maxGoleiros) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Este time já possui $_maxGoleiros goleiros. Remova um antes de adicionar outro.',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1A1A2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final novoValor = !isGoleiroAtual;
    final res = await _apiService.atualizarInscrito(
      widget.equipe.id,
      inscrito['id'].toString(),
      isGoleiro: novoValor,
    );

    if (res != null) {
      _carregarInscritos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(novoValor ? '${inscrito['atletaNome']} definido como goleiro!' : 'Goleiro removido.'),
            backgroundColor: novoValor ? Colors.blueGrey.shade700 : Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar função do atleta.')),
        );
      }
    }
  }

  void _abrirInscricaoLote() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: ModalVincularAtletas(equipe: widget.equipe),
      ),
    );

    if (result == true) {
      _carregarInscritos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF85C39), Color(0xFFE64A19)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('INSCRITOS',
                style: TextStyle(fontFamily: 'Bebas Neue', fontSize: 22, color: Colors.white, letterSpacing: 1)),
            Text(widget.equipe.nome,
                style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          // Contadores compactos na AppBar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                _AppBarBadge(
                  icon: Icons.sports_soccer,
                  count: _totalGoleiros,
                  max: _maxGoleiros,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 8),
                _AppBarBadge(
                  icon: Icons.military_tech,
                  count: _totalCapitoes,
                  max: _maxCapitoes,
                  color: Colors.amber,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirInscricaoLote,
        backgroundColor: const Color(0xFFF85C39),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Vincular Atletas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFF85C39)))
            : _inscritos.isEmpty
                ? const Center(
                    child: Text("Nenhum atleta inscrito nesta equipe.", style: TextStyle(color: Colors.black87)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
                    itemCount: _inscritos.length,
                    itemBuilder: (context, index) {
                      final i = _inscritos[index];
                      return _InscritoCard(
                        inscrito: i,
                        onToggleCapitao: () => _toggleCapitao(i),
                        onToggleGoleiro: () => _toggleGoleiro(i),
                        onRemover: () => _removerInscrito(i['id'].toString()),
                      );
                    },
                  ),
      ),
    );
  }
}

// ── Card do inscrito com PopupMenu ─────────────────────────────
class _InscritoCard extends StatelessWidget {
  final Map<String, dynamic> inscrito;
  final VoidCallback onToggleCapitao;
  final VoidCallback onToggleGoleiro;
  final VoidCallback onRemover;

  const _InscritoCard({
    required this.inscrito,
    required this.onToggleCapitao,
    required this.onToggleGoleiro,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    final nome = inscrito['atletaNome']?.toString() ?? 'Desconhecido';
    final fotoUrl = inscrito['atletaFotoUrl']?.toString();
    final numCamisa = inscrito['numeroCamisa'];
    final isCapitao = inscrito['isCapitao'] == true;
    final isGoleiro = inscrito['isGoleiro'] == true;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCapitao
                      ? Colors.amber
                      : isGoleiro
                          ? Colors.blueGrey.shade300
                          : Colors.grey.shade200,
                  width: isCapitao || isGoleiro ? 2.5 : 1.5,
                ),
              ),
              child: fotoUrl != null && fotoUrl.isNotEmpty
                  ? ClipOval(child: Image.network(fotoUrl, fit: BoxFit.cover))
                  : ClipOval(
                      child: Container(
                        color: Colors.purple.shade100,
                        child: Center(
                          child: Text(
                            numCamisa != null ? numCamisa.toString() : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 5),
                  if (isCapitao || isGoleiro)
                    Wrap(
                      spacing: 5,
                      children: [
                        if (isCapitao)
                          _FuncaoBadge(label: 'CAPITÃO', color: Colors.amber.shade700),
                        if (isGoleiro)
                          _FuncaoBadge(label: 'GOLEIRO', color: Colors.blueGrey.shade600),
                      ],
                    )
                  else
                    Text('Atleta', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),

            // Menu de ações
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 3,
              itemBuilder: (context) => [
                // Toggle Capitão
                PopupMenuItem<String>(
                  value: 'capitao',
                  child: Row(
                    children: [
                      Icon(
                        isCapitao ? Icons.remove_circle_outline : Icons.military_tech,
                        color: isCapitao ? Colors.red.shade400 : Colors.amber.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isCapitao ? 'Remover como Capitão' : 'Tornar Capitão',
                        style: TextStyle(
                          color: isCapitao ? Colors.red.shade400 : Colors.amber.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle Goleiro
                PopupMenuItem<String>(
                  value: 'goleiro',
                  child: Row(
                    children: [
                      Icon(
                        isGoleiro ? Icons.remove_circle_outline : Icons.sports_soccer,
                        color: isGoleiro ? Colors.red.shade400 : Colors.blueGrey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isGoleiro ? 'Remover como Goleiro' : 'Tornar Goleiro',
                        style: TextStyle(
                          color: isGoleiro ? Colors.red.shade400 : Colors.blueGrey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                // Remover do time
                PopupMenuItem<String>(
                  value: 'remover',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove_outlined, color: Colors.red.shade600, size: 20),
                      const SizedBox(width: 10),
                      Text('Remover do Time', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'capitao') onToggleCapitao();
                if (value == 'goleiro') onToggleGoleiro();
                if (value == 'remover') onRemover();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge de função (CAPITÃO / GOLEIRO) ───────────────────────
class _FuncaoBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _FuncaoBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

// ── Badge compacto na AppBar ───────────────────────────────────
class _AppBarBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final int max;
  final Color color;

  const _AppBarBadge({required this.icon, required this.count, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    final isFull = count >= max;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isFull ? color.withOpacity(0.9) : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text('$count/$max', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ── Modal Vincular Atletas (mantido igual) ─────────────────────
class ModalVincularAtletas extends StatefulWidget {
  final Equipe equipe;
  const ModalVincularAtletas({super.key, required this.equipe});

  @override
  State<ModalVincularAtletas> createState() => _ModalVincularAtletasState();
}

class _ModalVincularAtletasState extends State<ModalVincularAtletas> {
  final AdminApiService _apiService = AdminApiService();
  List<Atleta> _todosAtletas = [];
  final Set<String> _selecionados = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _carregarAtletas();
  }

  Future<void> _carregarAtletas() async {
    final atleticaId = widget.equipe.atletica?.id;
    if (atleticaId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final lista = await _apiService.listarAtletas(atleticaId);
    if (mounted) {
      setState(() {
        _todosAtletas = lista;
        _isLoading = false;
      });
    }
  }

  Future<void> _salvar() async {
    if (_selecionados.isEmpty) return;
    setState(() => _isSaving = true);

    final listaEnvio = _selecionados
        .map((id) => {
              'atletaId': id,
              'ativo': true,
            })
        .toList();

    final sucesso = await _apiService.adicionarInscritos(widget.equipe.id, listaEnvio);

    setState(() => _isSaving = false);
    if (sucesso) {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Erro ao vincular. Tente novamente.')));
      }
    }
  }

  void _abrirCadastroNovoAtleta() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AtletaFormScreen(atleticaIdSugerida: widget.equipe.atletica?.id)),
    );
    if (result == true) _carregarAtletas();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.equipe.atletica?.id == null) {
      return const Center(child: Text('Time sem Atlética associada.'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Vincular Atletas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context, false)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ElevatedButton.icon(
            onPressed: _abrirCadastroNovoAtleta,
            icon: const Icon(Icons.person_add),
            label: const Text('Cadastrar Novo Atleta na Base'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
          ),
        ),
        const Divider(),
        Expanded(
          child: _todosAtletas.isEmpty
              ? const Center(child: Text('Nenhum atleta nesta Atlética.'))
              : ListView.builder(
                  itemCount: _todosAtletas.length,
                  itemBuilder: (context, index) {
                    final a = _todosAtletas[index];
                    final isSelected = _selecionados.contains(a.id);
                    return CheckboxListTile(
                      title: Text(a.nome),
                      subtitle:
                          a.fotoUrl != null ? const Text('Com foto', style: TextStyle(fontSize: 12)) : null,
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selecionados.add(a.id);
                          } else {
                            _selecionados.remove(a.id);
                          }
                        });
                      },
                      secondary: a.fotoUrl != null && a.fotoUrl!.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(a.fotoUrl!),
                              backgroundColor: Colors.transparent,
                            )
                          : CircleAvatar(
                              backgroundColor: Colors.purple.shade50,
                              child: const Icon(Icons.person, color: Colors.purple),
                            ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, -3))],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selecionados.isEmpty || _isSaving ? null : _salvar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF85C39),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Adicionar ${_selecionados.length} Atleta(s)',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
