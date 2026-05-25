import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_colors.dart';
import '../../../models/atletica.dart';
import '../../../models/user_profile.dart';
import '../../../services/atletica_service.dart';
import '../../../models/user_profile.dart';
import '../../../services/atletica_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../../widgets/profile/edit_profile_sheet.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab>
    with SingleTickerProviderStateMixin {
  final ProfileService _profileService = ProfileService();
  final AtleticaService _atleticaService = AtleticaService();
  final ImagePicker _picker = ImagePicker();
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  Future<_ProfileTabData>? _screenFuture;
  bool _uploadingPhoto = false;
  bool _isUpdatingInvite = false;
  bool _pendingInviteDialogShown = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _screenFuture = _loadScreenData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _reloadProfile() async {
    setState(() {
      _screenFuture = _loadScreenData();
    });
  }

  Future<_ProfileTabData> _loadScreenData() async {
    final profile = await _profileService.getMyProfile();
    List<MinhaAtletica> invites = const [];

    try {
      invites = await _atleticaService.getMeusConvites();
    } catch (_) {
      invites = const [];
    }

    return _ProfileTabData(
      profile: profile,
      invites: invites,
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_uploadingPhoto) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                color: AppColors.secondary,
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
                color: AppColors.secondarySoft,
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
      await _reloadProfile();
    } else {
      _showSnackBar('Não foi possível enviar a foto.', isError: true);
    }
  }

  Future<void> _handleLogout() async {
    try {
      await widget.authService.signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  Future<void> _respondToInvite(MinhaAtletica invite, bool accept) async {
    if (_isUpdatingInvite) return;

    setState(() => _isUpdatingInvite = true);

    try {
      if (accept) {
        await _atleticaService.aceitarConvite(invite.id);
      } else {
        await _atleticaService.recusarConvite(invite.id);
      }

      if (!mounted) return;
      _showSnackBar(
        accept
            ? 'Convocação aceita com sucesso.'
            : 'Convocação recusada com sucesso.',
      );
      await _reloadProfile();
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(
        accept
            ? 'Não foi possível aceitar a convocação.'
            : 'Não foi possível recusar a convocação.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingInvite = false);
      }
    }
  }

  void _maybeShowPendingInviteDialog(List<MinhaAtletica> invites) {
    if (_pendingInviteDialogShown) return;

    final pendingInvites = invites
        .where((invite) => invite.status.trim().toUpperCase() == 'CONVOCADO')
        .toList();
    if (pendingInvites.isEmpty) return;

    _pendingInviteDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return _InviteDecisionDialog(
            invite: pendingInvites.first,
            additionalPendingCount: pendingInvites.length - 1,
            isLoading: _isUpdatingInvite,
            onAccept: () async {
              Navigator.of(dialogContext).pop();
              await _respondToInvite(pendingInvites.first, true);
            },
            onReject: () async {
              Navigator.of(dialogContext).pop();
              await _respondToInvite(pendingInvites.first, false);
            },
          );
        },
      );
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.danger : AppColors.primary,
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
            child: FutureBuilder<_ProfileTabData>(
              future: _screenFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.secondary),
                  );
                }

                if (!_animController.isCompleted) {
                  _animController.forward();
                }

                final user = widget.authService.currentUser;
                final screenData = snapshot.data;
                final profile = screenData?.profile;
                final invites = screenData?.invites ?? const <MinhaAtletica>[];
                final nome = _resolveName(profile, user);
                final email = profile?.email ?? user?.email ?? '---';
                final cpf = _resolveCpf(user);
                final telefone = _resolveTelefone(profile, user);
                final genero = _resolveGenero(profile, user);
                final role = _resolveRole(profile, user);
                final photoUrl = profile?.fotoUrl;
                _maybeShowPendingInviteDialog(invites);

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    color: AppColors.secondary,
                    onRefresh: _reloadProfile,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 18),
                          _buildProfileSummaryCard(
                            nome: nome,
                            email: email,
                            telefone: telefone,
                            role: role,
                            photoUrl: photoUrl,
                          ),
                          const SizedBox(height: 18),
                            _buildInfoSection(
                              profile: profile,
                              nome: nome,
                              email: email,
                              cpf: cpf,
                              telefone: telefone,
                              genero: genero,
                              role: role,
                            ),
                          const SizedBox(height: 18),
                          _buildInviteSection(invites),
                          const SizedBox(height: 18),
                          _buildLogoutCard(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
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
              border: Border.all(color: AppColors.secondarySoft.withValues(alpha: 0.30)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.12),
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
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Conta pública do ecossistema esportivo',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSummaryCard({
    required String nome,
    required String email,
    required String telefone,
    required String role,
    String? photoUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.secondarySoft.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.12),
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
                    colors: [Color(0xFFEFF5FF), Color(0xFFD7E6FF)],
                  ),
                  border: Border.all(
                    color: AppColors.secondarySoft.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildAvatarFallback(nome),
                        )
                      : _buildAvatarFallback(nome),
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
                      color: AppColors.secondary,
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
                  nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildBadge(
                      label: _roleLabel(role),
                      color: AppColors.secondary,
                    ),
                    _buildBadge(
                      label: telefone == '---' ? 'Sem telefone' : telefone,
                      color: AppColors.primary,
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

  Widget _buildInfoSection({
    UserProfile? profile,
    required String nome,
    required String email,
    required String cpf,
    required String telefone,
    required String genero,
    required String role,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.secondarySoft.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DADOS DO PERFIL',
                style: TextStyle(
                  fontFamily: 'Bebas Neue',
                  fontSize: 24,
                  letterSpacing: 1,
                  color: AppColors.textPrimary,
                ),
              ),
              if (profile != null)
                TextButton.icon(
                  onPressed: () => _openEditProfile(profile),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Editar', style: TextStyle(fontFamily: 'Poppins')),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.person_outline,
            label: 'Nome de exibição',
            value: nome,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.alternate_email,
            label: 'E-mail',
            value: email,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.credit_card_outlined,
            label: 'CPF',
            value: cpf,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.phone_outlined,
            label: 'Telefone',
            value: telefone,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.wc_outlined,
            label: 'Gênero',
            value: genero,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.badge_outlined,
            label: 'Perfil de acesso',
            value: _roleLabel(role),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.secondarySoft.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SESSÃO',
            style: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: 22,
              letterSpacing: 1,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Encerrar a sessão atual neste dispositivo.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'SAIR DA CONTA',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteSection(List<MinhaAtletica> invites) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.secondarySoft.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONVITES DE ATLÉTICA',
            style: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: 24,
              letterSpacing: 1,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Acompanhe suas convocações para presidência, diretoria ou elenco e responda quando houver pendências.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          if (invites.isEmpty)
            _buildEmptyInviteState()
          else
            ...invites.map(
              (invite) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildInviteCard(invite),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openEditProfile(UserProfile profile) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(
        profile: profile,
        profileService: _profileService,
      ),
    );
    if (result == true) {
      _showSnackBar('Perfil atualizado com sucesso.');
      await _reloadProfile();
    }
  }

  Widget _buildEmptyInviteState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.secondarySoft.withValues(alpha: 0.22)),
      ),
      child: const Row(
        children: [
          Icon(Icons.mail_outline_rounded, color: AppColors.textMuted),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nenhum convite de atlética encontrado até agora.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCard(MinhaAtletica invite) {
    final status = invite.status.trim().toUpperCase();
    final isPending = status == 'CONVOCADO';
    final isAccepted = status == 'ATIVO';
    final statusColor = isPending
        ? AppColors.secondary
        : isAccepted
        ? const Color(0xFF2E8B57)
        : AppColors.danger;
    final roleLabel = _inviteRoleLabel(invite.papelCodigo);
    final roleIcon = _inviteRoleIcon(invite.papelCodigo);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: invite.atleticaEscudoUrl != null &&
                        invite.atleticaEscudoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          invite.atleticaEscudoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            roleIcon,
                            color: statusColor,
                          ),
                        ),
                      )
                    : Icon(roleIcon, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.atleticaNome ?? 'Atlética',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _inviteSubtitle(invite.papelCodigo, roleLabel),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status, statusColor),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _inviteStatusDescription(status, roleLabel),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
          if (isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isUpdatingInvite
                        ? null
                        : () => _respondToInvite(invite, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      side: BorderSide(color: statusColor.withValues(alpha: 0.34)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Recusar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isUpdatingInvite
                        ? null
                        : () => _respondToInvite(invite, true),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isUpdatingInvite
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Aceitar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _inviteStatusLabel(status),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
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
        border: Border.all(color: AppColors.secondarySoft.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.secondarySoft.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.secondary),
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
                    color: AppColors.textMuted,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    color: value == '---'
                        ? AppColors.textMuted.withValues(alpha: 0.65)
                        : AppColors.textPrimary,
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

  Widget _buildAvatarFallback(String nome) {
    return Center(
      child: Text(
        nome.isNotEmpty ? nome[0].toUpperCase() : 'U',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.secondary,
        ),
      ),
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

  String _resolveName(UserProfile? profile, User? user) {
    final fromProfile = profile?.nomeExibicao.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;

    final metadata = user?.userMetadata;
    final candidates = [
      metadata?['nome_exibicao'],
      metadata?['nomeExibicao'],
      metadata?['nome_completo'],
      metadata?['nomeCompleto'],
      user?.email,
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    return 'Usuário';
  }

  String _resolveCpf(User? user) {
    final metadata = user?.userMetadata;
    final value =
        metadata?['cpf']?.toString().trim() ??
        metadata?['CPF']?.toString().trim() ??
        '';
    return value.isEmpty ? '---' : value;
  }

  String _resolveTelefone(UserProfile? profile, User? user) {
    final profileValue = profile?.telefone?.trim() ?? '';
    if (profileValue.isNotEmpty) return profileValue;

    final metadata = user?.userMetadata;
    final value =
        metadata?['telefone']?.toString().trim() ??
        metadata?['phone']?.toString().trim() ??
        '';
    return value.isEmpty ? '---' : value;
  }

  String _resolveGenero(UserProfile? profile, User? user) {
    final profileValue = profile?.genero?.trim() ?? '';
    if (profileValue.isNotEmpty) return profileValue;

    final metadata = user?.userMetadata;
    final value = metadata?['genero']?.toString().trim() ?? '';
    return value.isEmpty ? '---' : value;
  }

  String _resolveRole(UserProfile? profile, User? user) {
    final profileRole = profile?.role.trim() ?? '';
    if (profileRole.isNotEmpty) return profileRole;

    final metadata = user?.userMetadata;
    final value =
        metadata?['role']?.toString().trim() ??
        metadata?['papel']?.toString().trim() ??
        'USER';
    return value.isEmpty ? 'USER' : value;
  }

  String _roleLabel(String role) {
    switch (role.trim().toUpperCase()) {
      case 'ADMIN':
        return 'Admin';
      case 'REFEREE':
        return 'Árbitro';
      case 'DIRECTOR':
        return 'Diretor';
      case 'PRESIDENT':
        return 'Presidente';
      case 'ATHLETE':
        return 'Atleta';
      default:
        return 'Usuário';
    }
  }

  String _inviteRoleLabel(String role) {
    switch (role.trim().toUpperCase()) {
      case 'PRESIDENT':
        return 'Presidente';
      case 'DIRECTOR':
        return 'Diretor';
      case 'ATHLETE':
        return 'Atleta';
      default:
        return 'Membro';
    }
  }

  IconData _inviteRoleIcon(String role) {
    switch (role.trim().toUpperCase()) {
      case 'PRESIDENT':
      case 'DIRECTOR':
        return Icons.shield_outlined;
      case 'ATHLETE':
        return Icons.sports_handball_outlined;
      default:
        return Icons.group_outlined;
    }
  }

  String _inviteSubtitle(String role, String roleLabel) {
    switch (role.trim().toUpperCase()) {
      case 'ATHLETE':
        return 'Convocação para entrar no elenco como $roleLabel';
      default:
        return 'Convite para atuar como $roleLabel';
    }
  }

  String _inviteStatusLabel(String status) {
    switch (status.trim().toUpperCase()) {
      case 'ATIVO':
        return 'Aceito';
      case 'RECUSADO':
        return 'Recusado';
      default:
        return 'Pendente';
    }
  }

  String _inviteStatusDescription(String status, String roleLabel) {
    final isAthlete = roleLabel == 'Atleta';
    switch (status.trim().toUpperCase()) {
      case 'ATIVO':
        return isAthlete
            ? 'Você aceitou esta convocação e já faz parte do elenco desta atlética como $roleLabel.'
            : 'Você aceitou este convite e já está vinculado como $roleLabel desta atlética.';
      case 'RECUSADO':
        return 'Você recusou este convite. Se precisar retomar o vínculo, será necessária uma nova convocação.';
      default:
        return isAthlete
            ? 'Existe uma convocação aguardando sua resposta para entrar no elenco desta atlética como $roleLabel.'
            : 'Existe uma convocação aguardando sua resposta para assumir o papel de $roleLabel nesta atlética.';
    }
  }
}

class _ProfileTabData {
  const _ProfileTabData({
    required this.profile,
    required this.invites,
  });

  final UserProfile? profile;
  final List<MinhaAtletica> invites;
}

class _InviteDecisionDialog extends StatelessWidget {
  const _InviteDecisionDialog({
    required this.invite,
    required this.additionalPendingCount,
    required this.isLoading,
    required this.onAccept,
    required this.onReject,
  });

  final MinhaAtletica invite;
  final int additionalPendingCount;
  final bool isLoading;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final roleCode = invite.papelCodigo.trim().toUpperCase();
    final roleLabel = switch (roleCode) {
      'PRESIDENT' => 'Presidente',
      'DIRECTOR' => 'Diretor',
      'ATHLETE' => 'Atleta',
      _ => 'Membro',
    };
    final invitationText = roleCode == 'ATHLETE'
        ? 'Você foi convocado para integrar o elenco de ${invite.atleticaNome ?? 'uma atlética'} como $roleLabel.'
        : 'Você foi convocado para atuar como $roleLabel em ${invite.atleticaNome ?? 'uma atlética'}.';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Convocação da atlética',
              style: TextStyle(
                fontFamily: 'Bebas Neue',
                fontSize: 28,
                letterSpacing: 1,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              invitationText,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            if (additionalPendingCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Existem mais $additionalPendingCount convite(s) pendente(s) na sua seção de perfil.',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Recusar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onAccept,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Aceitar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
