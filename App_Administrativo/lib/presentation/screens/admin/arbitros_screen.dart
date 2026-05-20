import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/arbitro_model.dart';
import '../../../services/admin_api_service.dart';
import '../../../services/auth_service.dart';
import 'arbitro_detalhe_screen.dart';

class ArbitrosAdminScreen extends StatefulWidget {
  final bool canEdit;
  final AdminApiService? apiService;
  const ArbitrosAdminScreen({super.key, this.canEdit = false, this.apiService});

  @override
  State<ArbitrosAdminScreen> createState() => _ArbitrosScreenState();
}

class _ArbitrosScreenState extends State<ArbitrosAdminScreen>
    with SingleTickerProviderStateMixin {
  late final AdminApiService _api = widget.apiService ?? AdminApiService();
  final _authService = AuthService();
  bool _canEdit = false;
  final TextEditingController _searchCtrl = TextEditingController();

  static const int _itensPorPagina = 8;
  List<Arbitro> _todos = [];
  List<Arbitro> _filtrados = [];
  bool _isLoading = true;
  late AnimationController _animCtrl;
  String _roleSelecionado = 'TODAS';
  int _paginaAtual = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _searchCtrl.addListener(_filtrar);
    _resolverPermissaoECarregar();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Resolve a permissão do usuário via backend antes de carregar a lista.
  Future<void> _resolverPermissaoECarregar() async {
    final profile = await _authService.getUserProfile();
    final isAdmin =
        profile['isAdmin'] == true ||
        _authService.isAdminRole(profile['role'] as String? ?? '');
    if (mounted) {
      setState(() => _canEdit = isAdmin || _canEdit);
    }
    await _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _isLoading = true);
    final lista = await _api.listarArbitros();
    if (!mounted) return;
    setState(() {
      _todos = lista;
      _filtrados = lista;
      _isLoading = false;
      _paginaAtual = 0;
      _roleSelecionado = 'TODAS';
    });
    _animCtrl.reset();
    _animCtrl.forward();
  }

  void _filtrar() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtrados = _todos.where((a) {
        final matchesQuery = q.isEmpty || a.nome.toLowerCase().contains(q);

        final r = a.role.trim();
        final val = r.isEmpty ? 'INDEFINIDO' : r.toUpperCase();
        final matchesRole =
            _roleSelecionado == 'TODAS' || val == _roleSelecionado;

        return matchesQuery && matchesRole;
      }).toList();
      _paginaAtual = 0;
    });
  }

  List<_StatusOption> get _statusOptions {
    final options = <_StatusOption>[
      _StatusOption(
        value: 'TODAS',
        label: 'Todas',
        count: _todos.where((a) {
          final q = _searchCtrl.text.trim().toLowerCase();
          return q.isEmpty || a.nome.toLowerCase().contains(q);
        }).length,
        color: const Color(0xFFF85C39),
      ),
    ];

    final rolesUnicos =
        _todos
            .map((a) {
              final r = a.role.trim();
              return r.isEmpty ? 'INDEFINIDO' : r.toUpperCase();
            })
            .toSet()
            .toList()
          ..sort();

    for (final role in rolesUnicos) {
      final count = _todos.where((a) {
        final r = a.role.trim();
        final val = r.isEmpty ? 'INDEFINIDO' : r.toUpperCase();
        final q = _searchCtrl.text.trim().toLowerCase();
        final matchesQuery = q.isEmpty || a.nome.toLowerCase().contains(q);
        return val == role && matchesQuery;
      }).length;

      final roleLabel = switch (role) {
        'USER' || 'REFEREE' => 'Árbitro',
        'ADMIN' => 'Admin',
        'INDEFINIDO' => 'Indefinido',
        _ => role[0].toUpperCase() + role.substring(1).toLowerCase(),
      };

      options.add(
        _StatusOption(
          value: role,
          label: roleLabel,
          count: count,
          color: const Color(0xFFF85C39),
        ),
      );
    }

    return options;
  }

  int get _totalPaginas {
    if (_filtrados.isEmpty) return 1;
    return (_filtrados.length / _itensPorPagina).ceil();
  }

  List<Arbitro> get _filtradosPaginados {
    final inicio = _paginaAtual * _itensPorPagina;
    final fim = (inicio + _itensPorPagina).clamp(0, _filtrados.length);
    if (inicio >= _filtrados.length) {
      return const <Arbitro>[];
    }
    return _filtrados.sublist(inicio, fim);
  }

  void _selecionarRole(String role) {
    if (_roleSelecionado == role) return;
    setState(() {
      _roleSelecionado = role;
      _filtrar();
    });
  }

  void _mudarPagina(int pagina) {
    if (pagina < 0 || pagina >= _totalPaginas || pagina == _paginaAtual) {
      return;
    }
    setState(() => _paginaAtual = pagina);
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
            const Text(
              'ÁRBITROS',
              style: TextStyle(
                fontFamily: 'Bebas Neue',
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            Row(
              children: [
                const Text(
                  'Gestão de arbitragem',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                if (!_canEdit) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ðŸ‘ Leitura',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // â”€â”€ BARRA DE BUSCA â”€â”€
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: Color(0xFF1a1a2e)),
                      decoration: InputDecoration(
                        hintText: 'Buscar árbitro...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade400,
                        ),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey.shade400,
                                ),
                                onPressed: () {
                                  _searchCtrl.clear();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                // â”€â”€ LISTA â”€â”€
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFF85C39),
                          ),
                        )
                      : _filtrados.isEmpty
                      ? _buildEmpty()
                      : Column(
                          children: [
                            const SizedBox(height: 12),
                            _buildStatusFilterBar(),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  100,
                                ),
                                physics: const BouncingScrollPhysics(),
                                itemCount: _filtradosPaginados.length,
                                itemBuilder: (context, index) {
                                  final delay = index * 0.07;
                                  final anim = CurvedAnimation(
                                    parent: _animCtrl,
                                    curve: Interval(
                                      delay.clamp(0.0, 0.9),
                                      (delay + 0.5).clamp(0.1, 1.0),
                                      curve: Curves.easeOutCubic,
                                    ),
                                  );
                                  return FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.15),
                                        end: Offset.zero,
                                      ).animate(anim),
                                      child: _buildCard(
                                        _filtradosPaginados[index],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (_filtrados.isNotEmpty) _buildPaginationBar(),
                          ],
                        ),
                ),
              ],
            ),
            if (_canEdit && !_isLoading)
              Positioned(
                right: 16,
                bottom: 88,
                child: FloatingActionButton.extended(
                  onPressed: _showAddArbitroDialog,
                  backgroundColor: const Color(0xFFF85C39),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Adicionar Árbitro',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Arbitro arbitro) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ArbitroDetalheScreen(arbitro: arbitro, canEdit: _canEdit),
          ),
        );
        _resolverPermissaoECarregar();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(arbitro),
              const SizedBox(width: 14),
              // Nome
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      arbitro.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (arbitro.telefone != null &&
                        arbitro.telefone!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              arbitro.telefone!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Seta + Badge de árbitro
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF85C39).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          arbitro.role.toUpperCase() == 'ADMIN'
                              ? Icons.admin_panel_settings
                              : Icons.gavel,
                          size: 12,
                          color: const Color(0xFFF85C39),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          arbitro.role.toUpperCase() == 'ADMIN'
                              ? 'Administrador'
                              : 'Árbitro',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFF85C39),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Arbitro a) {
    if (a.fotoUrl != null && a.fotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(a.fotoUrl!),
      );
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor: const Color(0xFFF85C39).withValues(alpha: 0.12),
      child: Text(
        a.nome.isNotEmpty ? a.nome[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFF85C39),
        ),
      ),
    );
  }

  void _showAddArbitroDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Adicionar Árbitro',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.person_search,
                  color: Color(0xFFF85C39),
                ),
                title: const Text('Vincular usuário existente'),
                subtitle: const Text('Busque um usuário já cadastrado no app'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showVincularExistenteBottomSheet();
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add, color: Color(0xFFF85C39)),
                title: const Text('Criar novo usuário'),
                subtitle: const Text(
                  'Cadastre um novo árbitro com email e senha',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCriarNovoArbitroDialog();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showVincularExistenteBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _VincularExistenteView(api: _api, onVincular: _carregar);
      },
    );
  }

  void _showCriarNovoArbitroDialog() {
    final nomeCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final senhaCtrl = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Criar novo árbitro'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                      ),
                    ),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    TextField(
                      controller: senhaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Senha (mín. 6 chars)',
                      ),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              actions: [
                if (!loading)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                loading
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          if (nomeCtrl.text.isEmpty ||
                              emailCtrl.text.isEmpty ||
                              senhaCtrl.text.isEmpty) {
                            return;
                          }
                          setState(() => loading = true);
                          final arbitro = await _api.criarEAssociarArbitro(
                            nome: nomeCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            senha: senhaCtrl.text,
                          );
                          setState(() => loading = false);
                          if (arbitro != null) {
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              _resolverPermissaoECarregar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Árbitro criado com sucesso!'),
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Erro ao criar árbitro.'),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF85C39),
                        ),
                        child: const Text(
                          'Criar e Vincular',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(52.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gavel_outlined, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchCtrl.text.isNotEmpty
                  ? 'Nenhum árbitro encontrado'
                  : 'Nenhum árbitro cadastrado',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Os usuários vinculados ao quadro de arbitragem aparecerão aqui',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 18,
                color: Color(0xFFF85C39),
              ),
              const SizedBox(width: 8),
              const Text(
                'Filtrar por função',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Text(
                '${_filtrados.length} resultado(s)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statusOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = _statusOptions[index];
                final isSelected = item.value == _roleSelecionado;
                return ChoiceChip(
                  selected: isSelected,
                  label: Text('${item.label} (${item.count})'),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : item.color,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: item.color.withValues(alpha: 0.10),
                  selectedColor: item.color,
                  side: BorderSide(
                    color: isSelected
                        ? item.color
                        : item.color.withValues(alpha: 0.18),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (_) => _selecionarRole(item.value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Página ${_paginaAtual + 1} de $_totalPaginas',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: _paginaAtual > 0
                ? () => _mudarPagina(_paginaAtual - 1)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
            style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
          ),
          const SizedBox(width: 8),
          ...List.generate(_totalPaginas, (index) {
            final isSelected = index == _paginaAtual;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _mudarPagina(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF85C39)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
          IconButton(
            onPressed: _paginaAtual < _totalPaginas - 1
                ? () => _mudarPagina(_paginaAtual + 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
            style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
          ),
        ],
      ),
    );
  }
}

class _StatusOption {
  final String value;
  final String label;
  final int count;
  final Color color;

  _StatusOption({
    required this.value,
    required this.label,
    required this.count,
    required this.color,
  });
}

class _VincularExistenteView extends StatefulWidget {
  final AdminApiService api;
  final VoidCallback onVincular;
  const _VincularExistenteView({required this.api, required this.onVincular});

  @override
  State<_VincularExistenteView> createState() => _VincularExistenteViewState();
}

class _VincularExistenteViewState extends State<_VincularExistenteView> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _usuarios = [];
  List<Map<String, dynamic>> _filtrados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_filtrar);
    _carregar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final list = await widget.api.listarProfiles();
    if (!mounted) return;
    setState(() {
      _usuarios = list;
      _filtrados = list;
      _isLoading = false;
    });
  }

  void _filtrar() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtrados = q.isEmpty
          ? _usuarios
          : _usuarios.where((u) {
              final nome = (u['nomeExibicao'] ?? '').toString().toLowerCase();
              final email = (u['email'] ?? '').toString().toLowerCase();
              return nome.contains(q) || email.contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const Text(
              'Vincular usuário existente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou e-mail',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF85C39),
                      ),
                    )
                  : _filtrados.isEmpty
                  ? const Center(child: Text('Nenhum usuário encontrado.'))
                  : ListView.separated(
                      itemCount: _filtrados.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (ctx, i) {
                        final u = _filtrados[i];
                        final nome = u['nomeExibicao'] ?? 'Sem nome';
                        final role = u['role'] ?? 'USER';
                        return ListTile(
                          title: Text(
                            nome,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Role: $role'),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await widget.api.associarArbitro(
                                u['id'],
                              );
                              if (!mounted) return;
                              if (ok) {
                                navigator.pop();
                                widget.onVincular();
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Vinculado com sucesso!'),
                                  ),
                                );
                              } else {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Erro ao vincular usuário.'),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF85C39),
                            ),
                            child: const Text(
                              'Vincular',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
