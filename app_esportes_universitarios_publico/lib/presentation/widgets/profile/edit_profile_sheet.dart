import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../models/user_profile.dart';
import '../../../../services/profile_service.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({
    super.key,
    required this.profile,
    required this.profileService,
  });

  final UserProfile profile;
  final ProfileService profileService;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String? _selectedGenero;
  bool _saving = false;

  final _generos = ['Masculino', 'Feminino', 'Outro', 'Prefiro não dizer'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.nomeExibicao);
    _phoneController = TextEditingController(text: widget.profile.telefone ?? '');
    
    if (widget.profile.genero != null && _generos.contains(widget.profile.genero)) {
      _selectedGenero = widget.profile.genero;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome não pode ser vazio.')),
      );
      return;
    }

    setState(() => _saving = true);

    final success = await widget.profileService.updateProfile({
      'nomeExibicao': _nameController.text.trim(),
      'telefone': _phoneController.text.trim(),
      'genero': _selectedGenero,
    });

    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar as alterações.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9E2EE),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: const Text(
                    'Editar Perfil',
                    style: TextStyle(
                      fontFamily: 'Bebas Neue',
                      fontSize: 26,
                      letterSpacing: 1,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: 'Nome de exibição',
              hint: 'Seu nome ou apelido',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Telefone',
              hint: '(00) 00000-0000',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            const Text(
              'Gênero',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8EDF5)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGenero,
                  hint: const Text(
                    'Selecione...',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  items: _generos.map((g) {
                    return DropdownMenuItem(
                      value: g,
                      child: Text(g),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedGenero = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'SALVAR ALTERAÇÕES',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EDF5)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textMuted,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
