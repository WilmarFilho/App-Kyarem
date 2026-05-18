// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/app_colors.dart';
import '../../../../models/atletica.dart';
import '../../../../services/atletica_service.dart';

class AtleticaEditScreen extends StatefulWidget {
  final MinhaAtletica minhaAtletica;

  const AtleticaEditScreen({super.key, required this.minhaAtletica});

  @override
  State<AtleticaEditScreen> createState() => _AtleticaEditScreenState();
}

class _AtleticaEditScreenState extends State<AtleticaEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _atleticaService = AtleticaService();
  final _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingFoto = false;
  Atletica? _atletica;

  // Foto
  File? _novaFoto;
  String? _escudoUrlAtual;

  final _nomeController = TextEditingController();
  final _siglaController = TextEditingController();
  final _corPrincipalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAtletica();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _siglaController.dispose();
    _corPrincipalController.dispose();
    super.dispose();
  }

  Future<void> _loadAtletica() async {
    try {
      final data =
          await _atleticaService.getAtletica(widget.minhaAtletica.atleticaId!);
      setState(() {
        _atletica = data;
        _nomeController.text = data.nome;
        _siglaController.text = data.sigla ?? '';
        _corPrincipalController.text = data.corPrincipal ?? '#000000';
        _escudoUrlAtual = data.escudoUrl;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar atlética: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked != null) {
      setState(() => _novaFoto = File(picked.path));
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selecionar Foto',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeria',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Câmera',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.secondary),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      String? escudoUrl = _escudoUrlAtual;

      // Se o usuário selecionou nova foto, faz upload primeiro
      if (_novaFoto != null) {
        setState(() => _isUploadingFoto = true);
        escudoUrl = await _atleticaService.uploadEscudo(
          widget.minhaAtletica.atleticaId!,
          _novaFoto!,
        );
        setState(() => _isUploadingFoto = false);
      }

      final payload = {
        'nome': _nomeController.text.trim(),
        'sigla': _siglaController.text.trim(),
        'corPrincipal': _corPrincipalController.text.trim(),
        'escudoUrl': escudoUrl ?? '',
        'status': _atletica?.status ?? 'ATIVA',
      };

      await _atleticaService.updateAtletica(
          widget.minhaAtletica.atleticaId!, payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atlética atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploadingFoto = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Editar Atlética',
          style: TextStyle(
            color: AppColors.primary,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Foto / Escudo ---
                    _buildEscudoSection(),
                    const SizedBox(height: 24),

                    _buildTextField(
                      controller: _nomeController,
                      label: 'Nome da Atlética',
                      validator: (value) =>
                          value == null || value.isEmpty
                              ? 'Campo obrigatório'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _siglaController,
                      label: 'Sigla',
                    ),
                    const SizedBox(height: 16),
                    _buildColorField(),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isUploadingFoto
                                      ? 'Enviando foto...'
                                      : 'Salvando...',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'SALVAR ALTERAÇÕES',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEscudoSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _showImageSourceSheet,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    image: _novaFoto != null
                        ? DecorationImage(
                            image: FileImage(_novaFoto!),
                            fit: BoxFit.cover,
                          )
                        : _escudoUrlAtual != null && _escudoUrlAtual!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(_escudoUrlAtual!),
                                fit: BoxFit.cover,
                              )
                            : null,
                  ),
                  child: _novaFoto == null &&
                          (_escudoUrlAtual == null || _escudoUrlAtual!.isEmpty)
                      ? const Icon(Icons.shield, size: 48, color: AppColors.textMuted)
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _showImageSourceSheet,
            child: Text(
              _novaFoto != null ? 'Trocar foto selecionada' : 'Alterar escudo / logo',
              style: const TextStyle(
                color: AppColors.secondary,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          if (_novaFoto != null)
            Text(
              '✓ Nova foto selecionada',
              style: TextStyle(
                color: Colors.green[700],
                fontFamily: 'Poppins',
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColorField() {
    Color? previewColor;
    try {
      final hex = _corPrincipalController.text.replaceAll('#', '');
      if (hex.length == 6) {
        previewColor = Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cor Principal',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _corPrincipalController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '#FF0000',
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: previewColor ?? Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.black12),
                ),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8EDF5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8EDF5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8EDF5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8EDF5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondary),
            ),
          ),
        ),
      ],
    );
  }
}
