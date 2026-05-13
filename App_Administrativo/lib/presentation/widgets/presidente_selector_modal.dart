import 'package:flutter/material.dart';
import '../../../services/admin_api_service.dart';

/// Modal refinado para seleção ou criação do presidente de atlética.
/// Retorna o Map do profile selecionado (com 'id' e 'nomeExibicao') ou null.
class PresidenteSelectorModal extends StatefulWidget {
  const PresidenteSelectorModal({super.key});

  @override
  State<PresidenteSelectorModal> createState() =>
      _PresidenteSelectorModalState();
}

class _PresidenteSelectorModalState extends State<PresidenteSelectorModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminApiService _api = AdminApiService();

  // ─── Aba Buscar Existente ───
  List<Map<String, dynamic>> _profiles = [];
  List<Map<String, dynamic>> _filteredProfiles = [];
  Map<String, dynamic>? _selected;
  bool _loadingProfiles = true;
  final _searchController = TextEditingController();

  // ─── Aba Criar Novo ───
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaVisible = false;
  bool _criando = false;
  String? _erroCreate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarProfiles();
    _searchController.addListener(_filtrar);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _carregarProfiles() async {
    final lista = await _api.listarProfiles();
    if (mounted) {
      setState(() {
        _profiles = lista;
        _filteredProfiles = lista;
        _loadingProfiles = false;
      });
    }
  }

  void _filtrar() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredProfiles = q.isEmpty
          ? _profiles
          : _profiles.where((p) {
              final nome = (p['nomeExibicao'] ?? '').toString().toLowerCase();
              final role = (p['role'] ?? '').toString().toLowerCase();
              return nome.contains(q) || role.contains(q);
            }).toList();
    });
  }

  Future<void> _criarNovoUsuario() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _criando = true;
      _erroCreate = null;
    });

    try {
      // Cria o usuário via Supabase Admin (requer service_role key no backend)
      // Chamamos o endpoint backend POST /api/v1/profiles/create-admin-user
      final res = await _api.criarPresidente(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        senha: _senhaController.text,
      );

      if (!mounted) return;

      if (res != null) {
        Navigator.of(context).pop(res);
      } else {
        setState(
          () => _erroCreate =
              'Erro ao criar usuário. Verifique os dados e tente novamente.',
        );
      }
    } catch (e) {
      setState(() => _erroCreate = e.toString());
    } finally {
      if (mounted) setState(() => _criando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Handle ──
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF85C39), Color(0xFFE64A19)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selecionar Presidente',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        'Busque um usuário ou crie um novo',
                        style: TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black45),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Tabs ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF85C39), Color(0xFFE64A19)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF85C39).withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black54,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Buscar Existente'),
                  Tab(text: 'Criar Novo'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Tab content ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildBuscarExistente(), _buildCriarNovo()],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── Aba Buscar Existente ───────────────────
  Widget _buildBuscarExistente() {
    return Column(
      children: [
        // Searchbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou perfil...',
              prefixIcon: const Icon(Icons.search, color: Colors.black38),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFF85C39),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Lista
        Expanded(
          child: _loadingProfiles
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF85C39)),
                )
              : _filteredProfiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_search,
                        size: 56,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Nenhum usuário cadastrado'
                            : 'Nenhum resultado encontrado',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredProfiles.length,
                  itemBuilder: (context, index) {
                    final p = _filteredProfiles[index];
                    final isSelected = _selected?['id'] == p['id'];
                    final nome = p['nomeExibicao']?.toString() ?? 'Sem nome';
                    final role = p['role']?.toString() ?? '';
                    final foto = p['fotoUrl']?.toString();

                    return _ProfileTile(
                      nome: nome,
                      role: _traduzirRole(role),
                      fotoUrl: foto,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selected = p),
                    );
                  },
                ),
        ),

        // Botão confirmar
        if (_selected != null)
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(_selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF85C39),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                ),
                label: Text(
                  'Confirmar — ${_selected!['nomeExibicao'] ?? 'Selecionado'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────── Aba Criar Novo ───────────────────
  Widget _buildCriarNovo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF85C39).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF85C39).withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFF85C39), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'O usuário será criado com o perfil de Presidente de Atlética e receberá acesso ao sistema.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFE64A19)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildInputLabel('Nome de Exibição'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nomeController,
              decoration: _inputDecoration(
                'Ex: João Silva',
                Icons.person_outline,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            _buildInputLabel('E-mail'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              decoration: _inputDecoration(
                'presidente@atletica.com',
                Icons.email_outlined,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                if (!v.contains('@')) return 'E-mail inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),

            _buildInputLabel('Senha Inicial'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _senhaController,
              obscureText: !_senhaVisible,
              decoration:
                  _inputDecoration(
                    'Mínimo 6 caracteres',
                    Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _senhaVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black38,
                      ),
                      onPressed: () =>
                          setState(() => _senhaVisible = !_senhaVisible),
                    ),
                  ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe a senha';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 24),

            if (_erroCreate != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _erroCreate!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _criando ? null : _criarNovoUsuario,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF85C39),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _criando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.person_add, color: Colors.white),
                label: Text(
                  _criando ? 'Criando usuário...' : 'Criar e Selecionar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF4A4A6A),
    ),
  );

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black26),
        prefixIcon: Icon(icon, color: Colors.black38, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF85C39), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      );

  String _traduzirRole(String role) {
    switch (role) {
      case 'presidente_atletica':
        return 'Presidente de Atlética';
      case 'admin':
        return 'Administrador';
      case 'super_admin':
        return 'Super Admin';
      case 'arbitro':
        return 'Árbitro';
      case 'delegado':
        return 'Delegado';
      case 'aluno':
        return 'Aluno';
      default:
        return role;
    }
  }
}

// ── Profile tile reutilizável ──────────────────────────────────
class _ProfileTile extends StatelessWidget {
  final String nome;
  final String role;
  final String? fotoUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.nome,
    required this.role,
    this.fotoUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF85C39).withValues(alpha: 0.07)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFF85C39) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFF85C39).withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: fotoUrl != null && fotoUrl!.isNotEmpty
                  ? ClipOval(child: Image.network(fotoUrl!, fit: BoxFit.cover))
                  : Center(
                      child: Text(
                        nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFFF85C39),
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
                  Text(
                    nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      role,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Check
            AnimatedOpacity(
              opacity: isSelected ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFF85C39),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
