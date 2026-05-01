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

  late final TextEditingController _nomeController;
  late final TextEditingController _siglaController;
  
  Color _selectedColor = const Color(0xFFF85C39);
  
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _currentEscudoUrl;

  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.atletica?.nome ?? '');
    _siglaController = TextEditingController(text: widget.atletica?.sigla ?? '');
    
    _currentEscudoUrl = widget.atletica?.escudoUrl;

    if (widget.atletica?.corPrincipal != null && widget.atletica!.corPrincipal!.isNotEmpty) {
      try {
        String hex = widget.atletica!.corPrincipal!.replaceAll('#', '');
        if (hex.length == 6) {
          hex = 'FF$hex';
        }
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
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color tempColor = _selectedColor;
        return AlertDialog(
          title: const Text('Selecione uma cor'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _selectedColor,
              onColorChanged: (Color color) {
                tempColor = color;
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF85C39)),
              child: const Text('Selecionar', style: TextStyle(color: Colors.white)),
              onPressed: () {
                setState(() {
                  _selectedColor = tempColor;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    String? escudoUrl = _currentEscudoUrl;

    // Se selecionou uma nova imagem, faz upload primeiro
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

    final payload = {
      'nome': _nomeController.text.trim(),
      'sigla': _siglaController.text.trim(),
      'corPrincipal': '#${_selectedColor.value.toRadixString(16).substring(2, 8).toUpperCase()}',
      'escudoUrl': escudoUrl,
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro ao salvar atlética.')),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: ClipOval(
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                  : (_currentEscudoUrl != null && _currentEscudoUrl!.isNotEmpty)
                      ? Image.network(_currentEscudoUrl!, fit: BoxFit.cover)
                      : Icon(Icons.shield, size: 50, color: Colors.grey.shade400),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF85C39),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ),
          if (_selectedImage != null || _currentEscudoUrl != null)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImage = null;
                    _currentEscudoUrl = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
        ],
      ),
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
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePicker(),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nomeController,
                  decoration: _inputDecoration('Nome da atlética'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _siglaController,
                  decoration: _inputDecoration('Sigla'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Cor Principal',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showColorPicker,
                  child: Container(
                    height: 55,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
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
                          '#${_selectedColor.value.toRadixString(16).substring(2, 8).toUpperCase()}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        const Icon(Icons.color_lens, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_isSaving || _isUploading) ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF85C39),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: (_isSaving || _isUploading)
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isEditing ? 'Salvar alterações' : 'Criar atlética',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
