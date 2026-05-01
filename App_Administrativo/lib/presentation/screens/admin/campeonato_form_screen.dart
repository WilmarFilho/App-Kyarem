import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kyarem_eventos/models/campeonato_model.dart';
import '../../../services/admin_api_service.dart';

class CampeonatoFormScreen extends StatefulWidget {
  final Campeonato? campeonato;

  const CampeonatoFormScreen({super.key, this.campeonato});

  @override
  State<CampeonatoFormScreen> createState() => _CampeonatoFormScreenState();
}

class _CampeonatoFormScreenState extends State<CampeonatoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminApiService _apiService = AdminApiService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nomeController;
  late TextEditingController _nivelController;
  late TextEditingController _dataInicioController;
  late TextEditingController _dataFimController;

  File? _selectedImage;
  String? _currentEscudoUrl;
  String? _selectedStatus;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(
      text: widget.campeonato?.nome ?? '',
    );
    _nivelController = TextEditingController(
      text: widget.campeonato?.nivel ?? '',
    );
    _dataInicioController = TextEditingController(
      text: _formatDate(widget.campeonato?.dataInicio),
    );
    _dataFimController = TextEditingController(
      text: _formatDate(widget.campeonato?.dataFim),
    );
    _currentEscudoUrl = widget.campeonato?.escudoUrl;
    _selectedStatus = widget.campeonato?.status ?? 'AGENDADO';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
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
      escudoUrl = await _apiService.uploadEscudoCampeonato(_selectedImage!);
      setState(() => _isUploading = false);

      if (escudoUrl == null) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao fazer upload da imagem.')),
          );
        }
        return;
      }
    }

    final data = {
      'nome': _nomeController.text,
      'nivel': _nivelController.text,
      'dataInicio': _dataInicioController.text.isNotEmpty
          ? _dataInicioController.text
          : null,
      'dataFim': _dataFimController.text.isNotEmpty
          ? _dataFimController.text
          : null,
      'escudoUrl': escudoUrl ?? '',
      'status': _selectedStatus,
    };

    bool sucesso = false;
    if (widget.campeonato == null) {
      final res = await _apiService.criarCampeonato(data);
      sucesso = res != null;
    } else {
      final res = await _apiService.atualizarCampeonato(
        widget.campeonato!.id,
        data,
      );
      sucesso = res != null;
    }

    setState(() => _isSaving = false);

    if (sucesso) {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Erro ao salvar.')));
      }
    }
  }

  Future<void> _selecionarData(TextEditingController controller) async {
    final hoje = DateTime.now();
    final selecionada = await showDatePicker(
      context: context,
      initialDate: hoje,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selecionada != null) {
      controller.text = _formatDate(selecionada);
    }
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
                'Status do Campeonato',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildOpcaoStatus(
              titulo: 'Agendado',
              valor: 'AGENDADO',
              icone: Icons.schedule,
              cor: Colors.blue,
            ),
            _buildOpcaoStatus(
              titulo: 'Em Andamento',
              valor: 'EM_ANDAMENTO',
              icone: Icons.play_circle_outline,
              cor: Colors.green,
            ),
            _buildOpcaoStatus(
              titulo: 'Finalizado',
              valor: 'FINALIZADO',
              icone: Icons.check_circle_outline,
              cor: Colors.grey[700]!,
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
          color: cor.withOpacity(0.1),
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
          ? Icon(Icons.check, color: Theme.of(context).primaryColor)
          : null,
      onTap: () {
        setState(() {
          _selectedStatus = valor;
        });
        Navigator.pop(context);
      },
    );
  }

  String _obterTextoStatus() {
    switch (_selectedStatus) {
      case 'AGENDADO':
        return 'Agendado';
      case 'EM_ANDAMENTO':
        return 'Em Andamento';
      case 'FINALIZADO':
        return 'Finalizado';
      default:
        return 'Agendado';
    }
  }

  Color _obterCorStatus() {
    switch (_selectedStatus) {
      case 'AGENDADO':
        return Colors.blue;
      case 'EM_ANDAMENTO':
        return Colors.green;
      case 'FINALIZADO':
        return Colors.grey[700]!;
      default:
        return Colors.blue;
    }
  }

  IconData _obterIconeStatus() {
    switch (_selectedStatus) {
      case 'AGENDADO':
        return Icons.schedule;
      case 'EM_ANDAMENTO':
        return Icons.play_circle_outline;
      case 'FINALIZADO':
        return Icons.check_circle_outline;
      default:
        return Icons.schedule;
    }
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Logo / Escudo',
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
          'Toque para selecionar uma imagem',
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.campeonato == null
        ? 'Novo Campeonato'
        : 'Editar Campeonato';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        toolbarHeight: 100,
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Bebas Neue',
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF85C39), Color(0xFFE64A19)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
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
                    labelText: 'Nome do Campeonato',
                  ),
                  validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _nivelController,
                  decoration: const InputDecoration(
                    labelText: 'Nível (ex: Estadual, Nacional, etc)',
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _dataInicioController,
                  decoration: const InputDecoration(
                    labelText: 'Data de Início (YYYY-MM-DD)',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selecionarData(_dataInicioController),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _dataFimController,
                  decoration: const InputDecoration(
                    labelText: 'Data de Fim (YYYY-MM-DD)',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selecionarData(_dataFimController),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _obterCorStatus().withOpacity(0.1),
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
                  ],
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
                                    ? 'Enviando imagem...'
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
    );
  }
}
