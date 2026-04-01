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

  Future<void> _removerInscrito(String inscritoId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Atleta?'),
        content: const Text('O atleta será removido deste time, mas continuará cadastrado na base.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar == true) {
      final sucesso = await _apiService.removerInscrito(widget.equipe.id, inscritoId);
      if (sucesso) {
        _carregarInscritos();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao remover inscrito.')));
        }
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
            const Text('INSCRITOS', style: TextStyle(fontFamily: 'Bebas Neue', fontSize: 22, color: Colors.white, letterSpacing: 1)),
            Text(widget.equipe.nome, style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.normal)),
          ],
        ),
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
                ? const Center(child: Text("Nenhum atleta inscrito nesta equipe.", style: TextStyle(color: Colors.black87)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
                        itemCount: _inscritos.length,
                        itemBuilder: (context, index) {
                          final i = _inscritos[index];
                          final nome = i['atletaNome'] ?? 'Desconhecido';
                          final fotoUrl = i['atletaFotoUrl']?.toString();
                          final numCamisa = i['numeroCamisa'];
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: fotoUrl != null && fotoUrl.isNotEmpty
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(fotoUrl),
                                    backgroundColor: Colors.transparent,
                                  )
                                : CircleAvatar(
                                    backgroundColor: Colors.purple.shade100,
                                    child: Text(numCamisa != null ? numCamisa.toString() : '?', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                                  ),
                              title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Row(
                                children: [
                                  if (i['isCapitao'] == true)
                                    Container(
                                      margin: const EdgeInsets.only(right: 5),
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(5)),
                                      child: const Text('CAPITÃO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  if (i['isGoleiro'] == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.blueGrey, borderRadius: BorderRadius.circular(5)),
                                      child: const Text('GOLEIRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () => _removerInscrito(i['id']),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

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

    final listaEnvio = _selecionados.map((id) => {
      'atletaId': id,
      'ativo': true,
      // outros campos opcionais como numeroCamisa, isGoleiro podem ser estendidos aqui
    }).toList();

    final sucesso = await _apiService.adicionarInscritos(widget.equipe.id, listaEnvio);

    setState(() => _isSaving = false);
    if (sucesso) {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao vincular. Tente novamente.')));
      }
    }
  }

  void _abrirCadastroNovoAtleta() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AtletaFormScreen(atleticaIdSugerida: widget.equipe.atletica?.id)),
    );
    if (result == true) {
      _carregarAtletas(); // recarrega a lista
    }
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
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),
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
                    subtitle: a.fotoUrl != null ? const Text('Com foto', style: TextStyle(fontSize: 12)) : null,
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
                  : Text('Adicionar ${_selecionados.length} Atleta(s)', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}
