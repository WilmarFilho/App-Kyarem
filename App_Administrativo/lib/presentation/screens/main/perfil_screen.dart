import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/profile_model.dart';
import '../../../services/profile_service.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';

class PerfilScreen extends StatefulWidget {
  final ProfileService? profileService;

  const PerfilScreen({super.key, this.profileService});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with SingleTickerProviderStateMixin {
  late final ProfileService _profileService;
  final ImagePicker _picker = ImagePicker();

  Profile? _profile;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  bool _uploadingPhoto = false;

  late final TextEditingController _nomeController;
  late final TextEditingController _telefoneController;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  bool get _isAdminRole => _profile?.role == 'admin';

  bool get _isPresidenteAtletica => false;

  bool get _isArbitro => _profile?.role == 'referee';

  @override
  void initState() {
    super.initState();
    _profileService = widget.profileService ?? ProfileService();
    _nomeController = TextEditingController();
    _telefoneController = TextEditingController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.fetchProfile();
    if (!mounted) return;

    setState(() {
      _profile = profile;
      _loading = false;
      _nomeController.text = profile?.nomeExibicao ?? '';
      _telefoneController.text = profile?.telefone ?? '';
    });

    if (!_animController.isCompleted) {
      _animController.forward();
    }
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final success = await _profileService.updateProfile(
      nomeExibicao: _nomeController.text.trim(),
      telefone: _telefoneController.text.trim().isEmpty
          ? null
          : _telefoneController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _saving = false;
      if (success) _editing = false;
    });

    if (success) {
      _showSnackBar('Perfil atualizado com sucesso.');
      await _loadProfile();
    } else {
      _showSnackBar('Não foi possível atualizar o perfil.', isError: true);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_uploadingPhoto) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF252525),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Atualizar foto',
                style: TextStyle(
                  fontFamily: 'Bebas Neue',
                  fontSize: 26,
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              _buildPhotoSourceTile(
                icon: Icons.camera_alt_outlined,
                title: 'Câmera',
                subtitle: 'Tirar uma nova foto',
                color: const Color(0xFFF85C39),
                onTap: () {
                  Navigator.pop(ctx);
                  _uploadPhoto(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              _buildPhotoSourceTile(
                icon: Icons.photo_library_outlined,
                title: 'Galeria',
                subtitle: 'Escolher imagem existente',
                color: const Color(0xFF2E9E56),
                onTap: () {
                  Navigator.pop(ctx);
                  _uploadPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadPhoto(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 82,
    );
    if (image == null) return;

    setState(() => _uploadingPhoto = true);
    final url = await _profileService.uploadProfilePhoto(File(image.path));
    if (!mounted) return;

    setState(() => _uploadingPhoto = false);

    if (url != null) {
      _showSnackBar('Foto atualizada com sucesso.');
      await _loadProfile();
    } else {
      _showSnackBar('Não foi possível enviar a foto.', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? const Color(0xFFB3261E)
            : const Color(0xFF252525),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: const Color(0xFFF7F7F7))),
          SafeArea(
            bottom: false,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF85C39)),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 130),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 18),
                          _buildProfileSummaryCard(),
                          const SizedBox(height: 18),
                          _buildEditableSection(),
                        ],
                      ),
                    ),
                  ),
          ),
          BottomNavigationWidget(
            currentRoute: '/perfil',
            isAdmin: _isAdminRole,
            isPresidenteAtletica: _isPresidenteAtletica,
            isArbitro: _isArbitro,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFE1D8)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF85C39).withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PERFIL',
                style: TextStyle(
                  fontFamily: 'Bebas Neue',
                  fontSize: 30,
                  letterSpacing: 1,
                  color: Color(0xFF111111),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFFE6DE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF85C39).withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFF2ED), Color(0xFFFFD7C9)],
                  ),
                  border: Border.all(
                    color: const Color(0xFFFFE1D8),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: _profile?.fotoUrl != null
                      ? Image.network(
                          _profile!.fotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildAvatarFallback(),
                        )
                      : _buildAvatarFallback(),
                ),
              ),
              Positioned(
                right: -6,
                bottom: -6,
                child: GestureDetector(
                  onTap: _pickAndUploadPhoto,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF85C39),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: _uploadingPhoto
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile?.nomeExibicao?.trim().isNotEmpty == true
                      ? _profile!.nomeExibicao!
                      : 'Usuário administrativo',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _profile?.email ?? '---',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF6E6E6E),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildBadge(
                      label: _profile?.roleLabel ?? 'Usuário',
                      color: const Color(0xFFF85C39),
                    ),
                    _buildBadge(
                      label: _telefoneController.text.trim().isEmpty
                          ? 'Sem telefone'
                          : _telefoneController.text.trim(),
                      color: const Color(0xFF2E9E56),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFFE6DE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF85C39).withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'DADOS DO PERFIL',
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontSize: 24,
                    letterSpacing: 1,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _saving
                    ? null
                    : () {
                        if (_editing) {
                          _saveProfile();
                        } else {
                          setState(() => _editing = true);
                        }
                      },
                icon: Icon(
                  _editing ? Icons.check_circle_outline : Icons.edit_outlined,
                  color: const Color(0xFFF85C39),
                  size: 18,
                ),
                label: Text(
                  _editing ? 'Salvar' : 'Editar',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFFF85C39),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFieldCard(
            icon: Icons.person_outline,
            label: 'Nome de exibição',
            controller: _nomeController,
            editable: _editing,
            placeholder: 'Como você quer aparecer no app',
          ),
          const SizedBox(height: 12),
          _buildFieldCard(
            icon: Icons.phone_outlined,
            label: 'Telefone',
            controller: _telefoneController,
            editable: _editing,
            keyboardType: TextInputType.phone,
            placeholder: 'Adicione um contato',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.badge_outlined,
            label: 'Perfil de acesso',
            value: _profile?.roleLabel ?? 'Usuário',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.alternate_email,
            label: 'E-mail',
            value: _profile?.email ?? '---',
          ),
          if (_editing) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF85C39),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'SALVAR ALTERAÇÕES',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldCard({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool editable,
    TextInputType keyboardType = TextInputType.text,
    required String placeholder,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE6DE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF85C39).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFF85C39)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Color(0xFF8A8A8A),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: editable
                      ? TextField(
                          key: ValueKey<String>('edit_$label'),
                          controller: controller,
                          keyboardType: keyboardType,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            color: Color(0xFF111111),
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: placeholder,
                            hintStyle: const TextStyle(
                              color: Color(0xFFBDBDBD),
                            ),
                            border: InputBorder.none,
                          ),
                        )
                      : Text(
                          controller.text.trim().isEmpty
                              ? placeholder
                              : controller.text.trim(),
                          key: ValueKey<String>('view_$label'),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            color: controller.text.trim().isEmpty
                                ? const Color(0xFFB0B0B0)
                                : const Color(0xFF111111),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE6DE)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2ED),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFF85C39)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Color(0xFF8A8A8A),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    color: Color(0xFF111111),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return const Center(
      child: Icon(Icons.person_outline, color: Color(0xFFF85C39), size: 42),
    );
  }

  Widget _buildPhotoSourceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
