// ignore_for_file: deprecated_member_use, unnecessary_underscores
import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../models/atletica.dart';
import '../../../../models/time_atletica.dart';
import '../../../../models/modalidade_catalogo.dart';
import '../../../../services/time_service.dart';
import '../../../../services/modalidade_service.dart';

class AtleticaTeamsScreen extends StatefulWidget {
  final MinhaAtletica minhaAtletica;

  const AtleticaTeamsScreen({super.key, required this.minhaAtletica});

  @override
  State<AtleticaTeamsScreen> createState() => _AtleticaTeamsScreenState();
}

class _AtleticaTeamsScreenState extends State<AtleticaTeamsScreen> {
  final _timeService = TimeService();
  final _modalidadeService = ModalidadeService();

  bool _isLoading = true;
  List<TimeAtletica> _times = [];
  List<ModalidadeCatalogo> _modalidades = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final timesFuture = _timeService.getTimesPorAtletica(widget.minhaAtletica.atleticaId!);
      final modFuture = _modalidadeService.getModalidadesCatalogo();
      
      final results = await Future.wait([timesFuture, modFuture]);
      
      setState(() {
        _times = results[0] as List<TimeAtletica>;
        _modalidades = results[1] as List<ModalidadeCatalogo>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showCreateTimeModal() async {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController();
    ModalidadeCatalogo? selectedModalidade;
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                top: 24,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Criar Nova Equipe',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Modalidade',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FormField<ModalidadeCatalogo>(
                      initialValue: selectedModalidade,
                      validator: (val) => val == null ? 'Campo obrigatório' : null,
                      builder: (state) {
                        return InkWell(
                          onTap: () async {
                            final result = await showModalBottomSheet<ModalidadeCatalogo>(
                              context: ctx,
                              backgroundColor: Colors.transparent,
                              builder: (sheetCtx) {
                                return Container(
                                  constraints: BoxConstraints(
                                    maxHeight: MediaQuery.of(sheetCtx).size.height * 0.7,
                                  ),
                                  padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Selecione a Modalidade',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Flexible(
                                        child: ListView.separated(
                                          shrinkWrap: true,
                                          itemCount: _modalidades.length,
                                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                          itemBuilder: (context, index) {
                                            final m = _modalidades[index];
                                            final isSelected = selectedModalidade?.id == m.id;
                                            return ListTile(
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              tileColor: isSelected ? const Color(0xFFF1F5F9) : Colors.transparent,
                                              title: Text(
                                                '${m.nome} (${m.genero == 'M' ? 'Masculino' : m.genero == 'F' ? 'Feminino' : 'Misto'})',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                                  color: isSelected ? AppColors.primary : Colors.black87,
                                                ),
                                              ),
                                              trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                                              onTap: () => Navigator.of(context).pop(m),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                );
                              },
                            );
                            if (result != null) {
                              setModalState(() {
                                selectedModalidade = result;
                              });
                              state.didChange(result);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              errorText: state.errorText,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE8EDF5)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE8EDF5)),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectedModalidade != null
                                      ? '${selectedModalidade!.nome} (${selectedModalidade!.genero == 'M' ? 'Masculino' : selectedModalidade!.genero == 'F' ? 'Feminino' : 'Misto'})'
                                      : 'Selecione a modalidade',
                                  style: TextStyle(
                                    color: selectedModalidade != null ? Colors.black87 : Colors.black54,
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nome da Equipe (Ex: Principal, B)',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nomeController,
                      validator: (val) => val == null || val.isEmpty ? 'Campo obrigatório' : null,
                      decoration: InputDecoration(
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
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSaving = true);
                              try {
                                await _timeService.createTime({
                                  'atleticaId': widget.minhaAtletica.atleticaId,
                                  'modalidadeCatalogoId': selectedModalidade!.id,
                                  'nome': nomeController.text,
                                });
                                if (ctx.mounted) Navigator.of(ctx).pop(true);
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Erro: $e')),
                                  );
                                }
                              } finally {
                                if (ctx.mounted) setModalState(() => isSaving = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'CRIAR EQUIPE',
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
            );
          },
        );
      },
    );

    _loadData();
  }

  Future<void> _confirmDelete(TimeAtletica time) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Equipe'),
        content: Text('Tem certeza que deseja excluir a equipe "${time.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('EXCLUIR', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _timeService.deleteTime(time.id);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e')),
          );
          setState(() => _isLoading = false);
        }
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
          'Equipes Permanentes',
          style: TextStyle(
            color: AppColors.primary,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.secondary),
            onPressed: _showCreateTimeModal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : _times.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.group_off, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      const Text(
                        'Nenhuma equipe cadastrada.',
                        style: TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showCreateTimeModal,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Criar Equipe', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _times.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final t = _times[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8EDF5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.sports_basketball, color: AppColors.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.nome,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '${t.modalidadeNome} (${t.genero == 'M' ? 'Masculino' : t.genero == 'F' ? 'Feminino' : 'Misto'})',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                            onPressed: () => _confirmDelete(t),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
