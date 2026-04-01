import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import '../../../services/admin_api_service.dart';
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

  Color _currentColor = const Color(0xFF2563EB); // Cor padrão
  bool _isSaving = false;
  bool _isUploading = false;

  File? _selectedImage;
  String? _currentEscudoUrl;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.atletica?.nome ?? '');
    _siglaController = TextEditingController(text: widget.atletica?.sigla ?? '');
    _currentEscudoUrl = widget.atletica?.escudoUrl;

    if (widget.atletica != null && widget.atletica!.corPrincipal != null && widget.atletica!.corPrincipal!.isNotEmpty) {
      String hex = widget.atletica!.corPrincipal!.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      _currentColor = Color(int.tryParse('0x$hex') ?? 0xFF2563EB);
    }
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Escolha uma cor', style: TextStyle(fontWeight: FontWeight.bold)),
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
              onPressed: () {
                Navigator.of(context).pop();
              },
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
      'corPrincipal': '#${_currentColor.value.toRadixString(16).substring(2).toUpperCase()}',
      'escudoUrl': escudoUrl ?? '',
      // presidenteId opcional por enquanto
    };

    bool sucesso = false;
    if (widget.atletica == null) {
      final res = await _apiService.criarAtletica(data);
      sucesso = res != null;
    } else {
      final res = await _apiService.atualizarAtletica(widget.atletica!.id, data);
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
          style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
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
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
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
        Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          'Toque para selecionar imagem',
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
      ],
    );
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
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(labelText: 'Nome da Atlética'),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _siglaController,
                        decoration: const InputDecoration(labelText: 'Sigla (ex: AAAC)'),
                      ),
                      const SizedBox(height: 15),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Cor Principal',
                          style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _pickColor,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _salvar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF85C39),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: _isSaving
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _isUploading ? 'Enviando imagem...' : 'Salvando...',
                                      style: const TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                  ],
                                )
                              : const Text('Salvar', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
      );
  }
}
