// ignore_for_file: deprecated_member_use
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/app_colors.dart';
import '../../../../models/atletica.dart';
import '../../../../services/atletica_service.dart';
import 'atletica_enrollment_screen.dart';
import 'atletica_roster_screen.dart';

class AtleticaManagementScreen extends StatefulWidget {
  final MinhaAtletica minhaAtletica;

  const AtleticaManagementScreen({super.key, required this.minhaAtletica});

  @override
  State<AtleticaManagementScreen> createState() =>
      _AtleticaManagementScreenState();
}

class _AtleticaManagementScreenState extends State<AtleticaManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _atleticaService = AtleticaService();
  final _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingFoto = false;
  Atletica? _atletica;

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
      final data = await _atleticaService.getAtletica(
        widget.minhaAtletica.atleticaId!,
      );
      if (!mounted) return;
      setState(() {
        _atletica = data;
        _nomeController.text = data.nome;
        _siglaController.text = data.sigla ?? '';
        _corPrincipalController.text = data.corPrincipal ?? '#000000';
        _escudoUrlAtual = data.escudoUrl;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar atlética: $e')),
      );
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null || !mounted) return;
    setState(() => _novaFoto = File(picked.path));
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
            color: AppColors.secondary.withValues(alpha: 0.3),
          ),
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

      final updated = await _atleticaService.updateAtletica(
        widget.minhaAtletica.atleticaId!,
        payload,
      );

      if (!mounted) return;
      setState(() {
        _atletica = updated;
        _escudoUrlAtual = updated.escudoUrl;
        _novaFoto = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Atlética atualizada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isUploadingFoto = false;
      });
    }
  }

  Color? _parsePreviewColor() {
    try {
      final hex = _corPrincipalController.text.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 7, 106, 227), const Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        widget.minhaAtletica.atleticaNome ?? 'Atlética',
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Acesse as informações da atlética, organize a participação em campeonatos e gerencie o elenco.',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Color(0xFFD7E0EA),
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.secondary,
                          ),
                        )
                      : Form(
                          key: _formKey,
                          child: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              _buildAtleticaInfoEditor(),
                              const SizedBox(height: 16),
                              _buildManagementCard(
                                context,
                                title: 'Participação em Campeonatos',
                                description:
                                    'Gerencie e inscreva equipes e controle o elenco em campeonatos ativos.',
                                icon: Icons.emoji_events_outlined,
                                color: const Color(0xFF7C3AED),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AtleticaEnrollmentScreen(
                                        minhaAtletica: widget.minhaAtletica,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildManagementCard(
                                context,
                                title: 'Elenco de Atletas',
                                description:
                                    'Convoque alunos do app para o quadro de atletas da atlética.',
                                icon: Icons.person_add,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AtleticaRosterScreen(
                                        minhaAtletica: widget.minhaAtletica,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAtleticaInfoEditor() {
    final previewColor = _parsePreviewColor();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildEscudoSection(),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _nomeController,
            label: 'Nome da Atlética',
            validator: (value) =>
                value == null || value.isEmpty ? 'Campo obrigatório' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(controller: _siglaController, label: 'Sigla'),
          const SizedBox(height: 16),
          Column(
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _corPrincipalController,
                      decoration: InputDecoration(
                        hintText: '#0A2342',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE8EDF5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE8EDF5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        final isValid = RegExp(
                          r'^#?[0-9A-Fa-f]{6}$',
                        ).hasMatch(text);
                        return isValid ? null : 'Informe uma cor hexadecimal válida';
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: previewColor ?? const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8EDF5)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1667FF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
                        _isUploadingFoto ? 'Enviando foto...' : 'Salvando...',
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
                  child:
                      _novaFoto == null &&
                          (_escudoUrlAtual == null || _escudoUrlAtual!.isEmpty)
                      ? const Icon(
                          Icons.shield,
                          size: 48,
                          color: AppColors.textMuted,
                        )
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _showImageSourceSheet,
            child: Text(
              _novaFoto != null
                  ? 'Trocar foto selecionada'
                  : 'Alterar escudo / logo',
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
              'Nova foto selecionada',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
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
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE8EDF5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE8EDF5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.secondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final iconColor = color ?? AppColors.secondary;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EDF5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
