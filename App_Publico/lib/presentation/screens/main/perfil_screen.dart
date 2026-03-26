import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/profile_model.dart';
import '../../../services/profile_service.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with SingleTickerProviderStateMixin {
  final ProfileService _profileService = ProfileService();
  final ImagePicker _picker = ImagePicker();

  Profile? _profile;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;

  late TextEditingController _nomeController;
  late TextEditingController _telefoneController;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
    _telefoneController = TextEditingController();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
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
    if (mounted) {
      setState(() {
        _profile = profile;
        _loading = false;
        if (profile != null) {
          _nomeController.text = profile.nomeExibicao ?? '';
          _telefoneController.text = profile.telefone ?? '';
        }
      });
      _animController.forward();
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final success = await _profileService.updateProfile(
      nomeExibicao: _nomeController.text.trim(),
      telefone: _telefoneController.text.trim().isEmpty
          ? null
          : _telefoneController.text.trim(),
    );
    if (mounted) {
      setState(() {
        _saving = false;
        _editing = false;
      });
      if (success) {
        _loadProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro ao atualizar perfil'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A0202),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Escolher foto',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF22F1D).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFFF22F1D)),
              ),
              title: const Text(
                'Câmera',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _uploadPhoto(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF22F1D).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Color(0xFFF22F1D),
                ),
              ),
              title: const Text(
                'Galeria',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _uploadPhoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPhoto(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image == null) return;

    final url = await _profileService.uploadProfilePhoto(File(image.path));
    if (mounted) {
      if (url != null) {
        _loadProfile();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF85C39)),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        const SliverToBoxAdapter(child: SizedBox(height: 60)),
                        SliverToBoxAdapter(child: _buildHeader()),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),

                        // MUDANÇA AQUI: Trocamos SliverToBoxAdapter por SliverFillRemaining
                        SliverFillRemaining(
                          hasScrollBody:
                              false, // Permite que a Column interna use Spacer
                          child: _buildProfileCard(),
                        ),
                      ],
                    ),
                  ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: BottomNavigationWidget(currentRoute: '/perfil'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Coluna da Esquerda: Foto
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF5F5F5), width: 3),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFEEEEEE),
                  backgroundImage: _profile?.fotoUrl != null
                      ? NetworkImage(_profile!.fotoUrl!)
                      : null,
                  child: _profile?.fotoUrl == null
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
              GestureDetector(
                onTap: _pickAndUploadPhoto,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF22F1D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Coluna da Direita: Nome e Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile?.nomeExibicao ?? 'Usuário',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  _profile?.email ?? '---',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                // Badge de Role
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: const Color(0xFFF22F1D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _profile?.roleLabel.toUpperCase() ?? 'ALUNO',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF22F1D),
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

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF110101).withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
      ),
      child: Column(
        // MainAxisSize.max garante que a coluna tente ocupar o espaço total do Container
        mainAxisSize: MainAxisSize.max,
        children: [
          const SizedBox(height: 30),
          _buildField(
            icon: Icons.person_outline,
            label: 'Nome de Exibição',
            controller: _nomeController,
            editable: _editing,
          ),
          _buildDivider(),
          _buildField(
            icon: Icons.phone_outlined,
            label: 'Telefone',
            controller: _telefoneController,
            editable: _editing,
            keyboardType: TextInputType.phone,
          ),
          _buildDivider(),
          _buildInfoField(
            icon: Icons.badge_outlined,
            label: 'Cargo',
            value: _profile?.roleLabel ?? 'Aluno',
          ),

          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : () {
                        if (_editing) {
                          _saveProfile(); // Se estiver editando, salva
                        } else {
                          setState(
                            () => _editing = true,
                          ); // Se não, entra em modo edição
                        }
                      },
                style: ElevatedButton.styleFrom(
                  // Se estiver salvando, deixa o botão um pouco mais escuro/desabilitado
                  backgroundColor: _saving
                      // ignore: deprecated_member_use
                      ? const Color(0xFFF22F1D).withOpacity(0.7)
                      : const Color.fromARGB(255, 255, 255, 255),
                  foregroundColor:
                      Colors.white, // Define a cor do texto/ripple como branco
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Color.fromARGB(255, 14, 14, 14),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _editing ? 'SALVAR ALTERAÇÕES' : 'EDITAR PERFIL',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color.fromARGB(
                            255,
                            25,
                            25,
                            25,
                          ), // Garante que o texto seja branco
                        ),
                      ),
              ),
            ),
          ),

          // Este Spacer ou Expanded empurra o conteúdo para cima
          // e garante que o fundo preto continue até o final
          const Spacer(),

          // Margem final para não ficar colado na BottomNavigation
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool editable,
    TextInputType keyboardType = TextInputType.text,
    String? placeholder,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF22F1D).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFF22F1D), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: editable
                      ? TextField(
                          key: ValueKey<String>('edit_$label'),
                          controller: controller,
                          keyboardType: keyboardType,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 4,
                            ),
                            hintText: placeholder,
                            hintStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              color: Colors.white30,
                            ),
                            border: InputBorder.none,
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFFF22F1D),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFFF22F1D),
                                width: 2,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          key: ValueKey<String>('read_$label'),
                          width: double.infinity,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            controller.text.isEmpty
                                ? (placeholder ?? '---')
                                : controller.text,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: controller.text.isEmpty
                                  ? Colors.white30
                                  : Colors.white,
                            ),
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

  Widget _buildInfoField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0202),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white70, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (_editing)
            Icon(Icons.lock_outline, color: Colors.white30, size: 18),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
    );
  }
}
