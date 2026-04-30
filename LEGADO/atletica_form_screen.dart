/*
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import '../App_Administrativo/lib/services/admin_api_service.dart';
import '../App_Administrativo/lib/presentation/widgets/presidente_selector_modal.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class AtleticaFormScreen extends StatefulWidget {
  final Atletica? atletica;

  const AtleticaFormScreen({super.key, this.atletica});

  @override
  State<AtleticaFormScreen> createState() => _AtleticaFormScreenState();
}

class _AtleticaFormScreenState extends State<AtleticaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminApiService _apiService = AdminApiService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nomeController;
  late TextEditingController _siglaController;

  Color _currentColor = const Color(0xFF2563EB);
  bool _isSaving = false;
  bool _isUploading = false;

  File? _selectedImage;
  String? _currentEscudoUrl;

  // ── Presidente ──
  Map<String, dynamic>? _presidenteSelecionado;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.atletica?.nome ?? '');
    _siglaController = TextEditingController(
      text: widget.atletica?.sigla ?? '',
    );
    _currentEscudoUrl = widget.atletica?.escudoUrl;

    if (widget.atletica != null &&
        widget.atletica!.corPrincipal != null &&
        widget.atletica!.corPrincipal!.isNotEmpty) {
      String hex = widget.atletica!.corPrincipal!.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      _currentColor = Color(int.tryParse('0x$hex') ?? 0xFF2563EB);
    }

    // Se editando e já tem presidenteId, pré-preenche o campo
    if (widget.atletica?.presidenteId != null) {
      _presidenteSelecionado = {
        'id': widget.atletica!.presidenteId,
        'nomeExibicao': 'Carregando...',
      };
      _carregarPresidente(widget.atletica!.presidenteId!);
    }
  }

  Future<void> _carregarPresidente(String presidenteId) async {
    final profiles = await _apiService.listarProfiles();
    final match = profiles
        .where((p) => p['id']?.toString() == presidenteId)
        .firstOrNull;
    if (match != null && mounted) {
      setState(() => _presidenteSelecionado = match);
    }
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Escolha uma cor',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _currentColor,
              onColorChanged: (color) {
                setState(() => _currentColor = color);
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _abrirSeletorPresidente() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PresidenteSelectorModal(),
    );

    if (result != null) {
      setState(() => _presidenteSelecionado = result);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    String? escudoUrl = _currentEscudoUrl;

    if (_selectedImage != null) {
      setState(() => _isUploading = true);
      escudoUrl = await _apiService.uploadEscudoAtletica(_selectedImage!);
      setState(() => _isUploading = false);

      if (escudoUrl == null) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao fazer upload do escudo.')),
          );
        }
        return;
      }
    }

    final data = {
      'nome': _nomeController.text,
      'sigla': _siglaController.text,
      'corPrincipal':
          '#${_currentColor.value.toRadixString(16).substring(2).toUpperCase()}',
      'escudoUrl': escudoUrl ?? '',
      if (_presidenteSelecionado != null &&
          _presidenteSelecionado!['id'] != null)
        'presidenteId': _presidenteSelecionado!['id'].toString(),
    };

    bool sucesso = false;
    if (widget.atletica == null) {
      final res = await _apiService.criarAtletica(data);
      sucesso = res != null;
    } else {
      final res = await _apiService.atualizarAtletica(
        widget.atletica!.id,
        data,
      );
      sucesso = res != null;
    }

    setState(() => _isSaving = false);

    if (sucesso) {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar Atlética.')),
        );
      }
    }
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Escudo da Atlética',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[300]!, width: 1.5),
            ),
            child: _buildImageContent(),
          ),
        ),
        if (_selectedImage != null || _currentEscudoUrl != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _currentEscudoUrl = null;
                });
              },
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 18,
              ),
              label: const Text('Remover', style: TextStyle(color: Colors.red)),
            ),
          ),
      ],
    );
  }

  Widget _buildImageContent() {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.file(
          _selectedImage!,
          fit: BoxFit.contain,
          width: double.infinity,
          height: 160,
        ),
      );
    }
    if (_currentEscudoUrl != null && _currentEscudoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          _currentEscudoUrl!,
          fit: BoxFit.contain,
          width: double.infinity,
          height: 160,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 8),
        Text(
          'Toque para selecionar imagem',
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
      ],
    );
  }

  /// Card clicável para seleção do presidente.
  Widget _buildPresidenteSelector() {
    final hasPresidente = _presidenteSelecionado != null;
    final nome = _presidenteSelecionado?['nomeExibicao']?.toString();
    final role = _presidenteSelecionado?['role']?.toString();
    final foto = _presidenteSelecionado?['fotoUrl']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Presidente da Atlética',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _abrirSeletorPresidente,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: hasPresidente
                  ? const Color(0xFFF85C39).withOpacity(0.04)
                  : Colors.white,
              border: Border.all(
                color: hasPresidente
                    ? const Color(0xFFF85C39).withOpacity(0.4)
                    : Colors.grey[300]!,
                width: hasPresidente ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasPresidente
                        ? const Color(0xFFF85C39).withOpacity(0.12)
                        : Colors.grey.shade100,
                    border: Border.all(
                      color: hasPresidente
                          ? const Color(0xFFF85C39).withOpacity(0.3)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: hasPresidente
                      ? (foto != null && foto.isNotEmpty
                            ? ClipOval(
                                child: Image.network(foto, fit: BoxFit.cover),
                              )
                            : Center(
                                child: Text(
                                  (nome?.isNotEmpty == true)
                                      ? nome![0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFFF85C39),
                                  ),
                                ),
                              ))
                      : const Icon(
                          Icons.person_search,
                          color: Colors.black38,
                          size: 22,
                        ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: hasPresidente
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nome ?? 'Presidente',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            if (role != null)
                              Container(
                                margin: const EdgeInsets.only(top: 3),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFF85C39,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _traduzirRole(role),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFE64A19),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        )
                      : const Text(
                          'Toque para selecionar ou criar presidente',
                          style: TextStyle(color: Colors.black38, fontSize: 14),
                        ),
                ),

                // Ação
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasPresidente)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _presidenteSelecionado = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: hasPresidente
                          ? const Color(0xFFF85C39)
                          : Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final title = widget.atletica == null ? 'NOVA ATLÉTICA' : 'EDITAR ATLÉTICA';

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
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Bebas Neue',
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const Text(
              'Gerenciamento',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Atlética',
                    ),
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _siglaController,
                    decoration: const InputDecoration(
                      labelText: 'Sigla (ex: AAAC)',
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Cor Principal',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickColor,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#${_currentColor.value.toRadixString(16).substring(2).toUpperCase()}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _currentColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildImagePicker(),
                  const SizedBox(height: 20),
                  _buildPresidenteSelector(),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF85C39),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isSaving
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isUploading
                                      ? 'Enviando imagem...'
                                      : 'Salvando...',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Salvar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

*/
