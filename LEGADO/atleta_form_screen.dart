/*

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../App_Administrativo/lib/services/admin_api_service.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import 'package:kyarem_eventos/models/atleta_model.dart';

class AtletaFormScreen extends StatefulWidget {
  final Atleta? atleta;
  final String? atleticaIdSugerida;

  const AtletaFormScreen({super.key, this.atleta, this.atleticaIdSugerida});

  @override
  State<AtletaFormScreen> createState() => _AtletaFormScreenState();
}

class _AtletaFormScreenState extends State<AtletaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminApiService _apiService = AdminApiService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nomeController;

  String? _selectedAtleticaId;
  List<Atletica> _atleticas = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;

  File? _selectedImage;
  String? _currentFotoUrl;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.atleta?.nome ?? '');

    _currentFotoUrl = widget.atleta?.fotoUrl;
    _selectedAtleticaId =
        widget.atleta?.atletica?.id ?? widget.atleticaIdSugerida;

    _carregarAtleticas();
  }

  Future<void> _carregarAtleticas() async {
    final list = await _apiService.listarAtleticas();
    if (mounted) {
      setState(() {
        _atleticas = list;
        _isLoading = false;

        if (_selectedAtleticaId != null &&
            !_atleticas.any((a) => a.id == _selectedAtleticaId)) {
          _selectedAtleticaId = null;
        }
      });
    }
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
    if (_selectedAtleticaId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione uma Atlética.')));
      return;
    }

    setState(() => _isSaving = true);

    String? fotoUrl = _currentFotoUrl;

    // Se selecionou uma nova imagem, faz upload primeiro
    if (_selectedImage != null) {
      setState(() => _isUploading = true);
      fotoUrl = await _apiService.uploadFotoAtleta(_selectedImage!);
      setState(() => _isUploading = false);

      if (fotoUrl == null) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao fazer upload da foto.')),
          );
        }
        return;
      }
    }

    final data = {
      'atleticaId': _selectedAtleticaId,
      'nome': _nomeController.text,
      'fotoUrl': fotoUrl ?? '',
    };

    bool sucesso = false;
    if (widget.atleta == null) {
      final res = await _apiService.criarAtleta(data);
      sucesso = res != null;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Edição de atleta ainda não disponível.')),
      );
      setState(() => _isSaving = false);
      return;
    }

    setState(() => _isSaving = false);

    if (sucesso) {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Erro ao salvar Atleta.')));
      }
    }
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto do Atleta',
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
        if (_selectedImage != null || _currentFotoUrl != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _currentFotoUrl = null;
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

    if (_currentFotoUrl != null && _currentFotoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          _currentFotoUrl!,
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
        Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          'Toque para selecionar uma foto',
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.atleta == null ? 'NOVO ATLETA' : 'EDITAR ATLETA';

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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFF85C39)),
              )
            : SingleChildScrollView(
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
                            labelText: 'Nome Completo',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Vínculo (Atlética)',
                            prefixIcon: Icon(Icons.shield),
                          ),
                          initialValue: _selectedAtleticaId,
                          items: _atleticas.map((a) {
                            return DropdownMenuItem(
                              value: a.id,
                              child: Text(
                                a.nome,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _selectedAtleticaId = v),
                          validator: (v) => v == null ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: 15),

                        _buildImagePicker(),
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
                                            ? 'Enviando foto...'
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
