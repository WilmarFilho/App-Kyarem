import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import 'package:kyarem_eventos/services/admin_api_service.dart';

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

  late final TextEditingController _nomeController;
  late final TextEditingController _siglaController;

  Color _selectedColor = const Color(0xFFF85C39);
  String? _selectedStatus;

  File? _selectedImage;
  String? _currentEscudoUrl;

  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.atletica?.nome ?? '');
    _siglaController = TextEditingController(
      text: widget.atletica?.sigla ?? '',
    );
    _currentEscudoUrl = widget.atletica?.escudoUrl;
    _selectedStatus = widget.atletica?.status ?? 'ATIVA';

    if (widget.atletica?.corPrincipal != null &&
        widget.atletica!.corPrincipal!.isNotEmpty) {
      try {
        String hex = widget.atletica!.corPrincipal!.replaceAll('#', '');
        if (hex.length == 6) hex = 'FF$hex';
        _selectedColor = Color(int.parse(hex, radix: 16));
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _siglaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color tempColor = _selectedColor;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Selecione a cor principal'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _selectedColor,
              onColorChanged: (Color color) => tempColor = color,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF85C39),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                setState(() => _selectedColor = tempColor);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Selecionar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarModalStatus() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Status da Atlética',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildOpcaoStatus(
              titulo: 'Ativa',
              valor: 'ATIVA',
              icone: Icons.check_circle_outline,
              cor: Colors.green,
            ),
            _buildOpcaoStatus(
              titulo: 'Inativa',
              valor: 'INATIVA',
              icone: Icons.pause_circle_outline,
              cor: Colors.orange,
            ),
            _buildOpcaoStatus(
              titulo: 'Suspensa',
              valor: 'SUSPENSA',
              icone: Icons.block,
              cor: Colors.red,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcaoStatus({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color cor,
  }) {
    final bool selecionado = _selectedStatus == valor;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icone, color: cor),
      ),
      title: Text(
        titulo,
        style: TextStyle(
          fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: selecionado
          ? const Icon(Icons.check, color: Color(0xFFF85C39))
          : null,
      onTap: () {
        setState(() => _selectedStatus = valor);
        Navigator.pop(context);
      },
    );
  }

  String _obterTextoStatus() {
    switch (_selectedStatus) {
      case 'ATIVA':
        return 'Ativa';
      case 'INATIVA':
        return 'Inativa';
      case 'SUSPENSA':
        return 'Suspensa';
      default:
        return 'Ativa';
    }
  }

  Color _obterCorStatus() {
    switch (_selectedStatus) {
      case 'ATIVA':
        return Colors.green;
      case 'INATIVA':
        return Colors.orange;
      case 'SUSPENSA':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  IconData _obterIconeStatus() {
    switch (_selectedStatus) {
      case 'ATIVA':
        return Icons.check_circle_outline;
      case 'INATIVA':
        return Icons.pause_circle_outline;
      case 'SUSPENSA':
        return Icons.block;
      default:
        return Icons.check_circle_outline;
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
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao fazer upload do escudo.')),
        );
        return;
      }
    }

    final corHex =
        '#${_selectedColor.toARGB32().toRadixString(16).substring(2, 8).toUpperCase()}';

    final payload = {
      'nome': _nomeController.text.trim(),
      'sigla': _siglaController.text.trim(),
      'corPrincipal': corHex,
      'escudoUrl': escudoUrl,
      'status': _selectedStatus ?? 'ATIVA',
    };

    final sucesso = widget.atletica == null
        ? await _apiService.criarAtletica(payload)
        : await _apiService.atualizarAtletica(widget.atletica!.id, payload);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (sucesso != null) {
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Erro ao salvar atlética.')));
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Escudo / Logo',
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
        if (_selectedImage != null ||
            (_currentEscudoUrl != null && _currentEscudoUrl!.isNotEmpty))
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
          'Toque para selecionar um escudo',
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.atletica != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF85C39), Color(0xFFE64A19)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          isEditing ? 'Editar Atlética' : 'Nova Atlética',
          style: const TextStyle(
            fontFamily: 'Bebas Neue',
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nomeController,
                  decoration: _inputDecoration('Nome da Atlética'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _siglaController,
                  decoration: _inputDecoration('Sigla'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 15),

                // ── Status selector ──────────────────────────────────────
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _mostrarModalStatus,
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[300]!, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _obterCorStatus().withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _obterIconeStatus(),
                            color: _obterCorStatus(),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _obterTextoStatus(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // ── Color picker ─────────────────────────────────────────
                const Text(
                  'Cor Principal',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showColorPicker,
                  child: Container(
                    height: 55,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!, width: 1.5),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '#${_selectedColor.toARGB32().toRadixString(16).substring(2, 8).toUpperCase()}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        const Icon(Icons.color_lens, color: Colors.black54),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                _buildImagePicker(),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isSaving || _isUploading) ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF85C39),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: (_isSaving || _isUploading)
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
                                    ? 'Enviando escudo...'
                                    : 'Salvando...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            isEditing ? 'Salvar alterações' : 'Criar atlética',
                            style: const TextStyle(
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
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelStyle: const TextStyle(color: Color(0xFFF85C39)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF85C39), width: 1.5),
      ),
    );
  }
}
