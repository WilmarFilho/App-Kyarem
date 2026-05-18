// ignore_for_file: deprecated_member_use, unnecessary_underscores
import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../models/atletica.dart';
import '../../../../models/atletica_membro.dart';
import '../../../../models/user_profile.dart';
import '../../../../services/membro_service.dart';
import '../../../../services/profile_service.dart';
import '../../../../services/time_service.dart';
import '../../../../services/modalidade_service.dart';
import '../../../../models/modalidade_catalogo.dart';

class AtleticaRosterScreen extends StatefulWidget {
  final MinhaAtletica minhaAtletica;

  const AtleticaRosterScreen({super.key, required this.minhaAtletica});

  @override
  State<AtleticaRosterScreen> createState() => _AtleticaRosterScreenState();
}

class _AtleticaRosterScreenState extends State<AtleticaRosterScreen> {
  final _membroService = MembroService();

  bool _isLoading = true;
  List<AtleticaMembro> _membros = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _membroService.getMembros(
        widget.minhaAtletica.atleticaId!,
      );
      setState(() {
        _membros = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar membros: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddAtletaModal() async {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController();
    final emailController = TextEditingController();
    final senhaController = TextEditingController();
    final String selectedPapel = 'ATHLETE';
    bool isSaving = false;
    bool isExistingUser = false;

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
                      'Adicionar Membro',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('Novo Usuário'),
                          selected: !isExistingUser,
                          onSelected: (val) =>
                              setModalState(() => isExistingUser = false),
                          selectedColor: AppColors.secondary.withValues(
                            alpha: 0.2,
                          ),
                          labelStyle: TextStyle(
                            color: !isExistingUser
                                ? AppColors.secondary
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text('Usuário Existente'),
                          selected: isExistingUser,
                          onSelected: (val) =>
                              setModalState(() => isExistingUser = true),
                          selectedColor: AppColors.secondary.withValues(
                            alpha: 0.2,
                          ),
                          labelStyle: TextStyle(
                            color: isExistingUser
                                ? AppColors.secondary
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // A função é fixa como ATHLETE
                    const SizedBox(height: 16),
                    if (!isExistingUser) ...[
                      _buildTextField(
                        controller: nomeController,
                        label: 'Nome Completo',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: emailController,
                        label: 'Email do Usuário',
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Email inválido'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: senhaController,
                        label: 'Senha Inicial',
                        validator: (v) => v == null || v.length < 6
                            ? 'Mínimo 6 caracteres'
                            : null,
                      ),
                    ] else ...[
                      const Text(
                        'Buscar Usuário',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Autocomplete<UserProfile>(
                        optionsBuilder:
                            (TextEditingValue textEditingValue) async {
                              if (textEditingValue.text.length < 3) {
                                return const Iterable<UserProfile>.empty();
                              }
                              return await ProfileService().searchProfiles(
                                textEditingValue.text,
                              );
                            },
                        displayStringForOption: (UserProfile option) =>
                            option.nomeExibicao,
                        onSelected: (UserProfile selection) {
                          emailController.text = selection.email ?? '';
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: 'Digite o nome ou e-mail',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE8EDF5),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE8EDF5),
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if (isExistingUser &&
                                      emailController.text.isEmpty) {
                                    return 'Selecione um usuário da lista';
                                  }
                                  return null;
                                },
                              );
                            },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: MediaQuery.of(context).size.width - 40,
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                        final UserProfile option = options
                                            .elementAt(index);
                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: AppColors.surface,
                                            backgroundImage:
                                                option.fotoUrl != null
                                                ? NetworkImage(option.fotoUrl!)
                                                : null,
                                            child: option.fotoUrl == null
                                                ? const Icon(
                                                    Icons.person,
                                                    color: AppColors.textMuted,
                                                  )
                                                : null,
                                          ),
                                          title: Text(
                                            option.nomeExibicao,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          subtitle: Text(
                                            option.email ?? 'Sem e-mail',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          onTap: () {
                                            onSelected(option);
                                          },
                                        );
                                      },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSaving = true);
                              try {
                                if (isExistingUser) {
                                  await _membroService.associarUsuarioExistente(
                                    widget.minhaAtletica.atleticaId!,
                                    {
                                      'email': emailController.text.trim(),
                                      'papelCodigo': selectedPapel,
                                    },
                                  );
                                } else {
                                  await _membroService.criarUsuarioEAssociar(
                                    widget.minhaAtletica.atleticaId!,
                                    {
                                      'nomeExibicao': nomeController.text
                                          .trim(),
                                      'email': emailController.text.trim(),
                                      'senha': senhaController.text,
                                      'papelCodigo': selectedPapel,
                                    },
                                  );
                                }
                                if (ctx.mounted) Navigator.of(ctx).pop(true);
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Erro: $e')),
                                  );
                                }
                              } finally {
                                if (ctx.mounted) {
                                  setModalState(() => isSaving = false);
                                }
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
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'CRIAR E ASSOCIAR',
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

  Future<void> _showCriarTimeModal() async {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController();
    String? selectedModalidadeId;
    List<String> selectedAtletaIds = [];
    bool isSaving = false;

    // Apenas atletas podem ser selecionados para o time
    final atletasDisponiveis = _membros
        .where((m) => m.papelCodigo == 'ATHLETE')
        .toList();

    // Carregar modalidades
    List<ModalidadeCatalogo>? modalidades;
    try {
      modalidades = await ModalidadeService().getModalidadesCatalogo();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar modalidades')),
        );
      }
      return;
    }

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.85,
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
                      'Criar Time Permanente',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: nomeController,
                      label: 'Nome do Time',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
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
                    DropdownButtonFormField<String>(
                      value: selectedModalidadeId,
                      items: modalidades!
                          .map((m) => DropdownMenuItem(
                                value: m.id,
                                child: Text('${m.nome} - ${m.genero}'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setModalState(() => selectedModalidadeId = val);
                      },
                      validator: (v) =>
                          v == null ? 'Selecione uma modalidade' : null,
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
                    const SizedBox(height: 16),
                    const Text(
                      'Atletas do Time',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE8EDF5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: atletasDisponiveis.isEmpty
                            ? const Center(
                                child: Text(
                                  'Nenhum atleta disponível na atlética',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              )
                            : ListView.separated(
                                itemCount: atletasDisponiveis.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final atleta = atletasDisponiveis[index];
                                  final atletaId = atleta.userId;
                                  if (atletaId.isEmpty) return const SizedBox();

                                  final isSelected =
                                      selectedAtletaIds.contains(atletaId);
                                  return CheckboxListTile(
                                    title: Text(
                                      atleta.nomeExibicao ??
                                          atleta.email ??
                                          'Atleta',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                      ),
                                    ),
                                    value: isSelected,
                                    activeColor: AppColors.secondary,
                                    onChanged: (bool? checked) {
                                      setModalState(() {
                                        if (checked == true) {
                                          selectedAtletaIds.add(atletaId);
                                        } else {
                                          selectedAtletaIds.remove(atletaId);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSaving = true);
                              try {
                                // 1. Criar o time
                                final novoTime = await TimeService().createTime({
                                  'atleticaId':
                                      widget.minhaAtletica.atleticaId,
                                  'modalidadeCatalogoId':
                                      selectedModalidadeId,
                                  'nome': nomeController.text.trim(),
                                });

                                // 2. Adicionar atletas ao time permanente
                                if (selectedAtletaIds.isNotEmpty) {
                                  await TimeService().adicionarAtletasTimePermanente(
                                    novoTime.id,
                                    selectedAtletaIds,
                                  );
                                }

                                if (ctx.mounted) Navigator.of(ctx).pop(true);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Time criado com sucesso!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Erro: $e')),
                                  );
                                }
                              } finally {
                                if (ctx.mounted) {
                                  setModalState(() => isSaving = false);
                                }
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
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'CRIAR TIME',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Elenco',
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
            icon: const Icon(Icons.group_add, color: AppColors.secondary),
            tooltip: 'Criar Time',
            onPressed: _showCriarTimeModal,
          ),
          IconButton(
            icon: const Icon(Icons.person_add, color: AppColors.secondary),
            tooltip: 'Adicionar Atleta',
            onPressed: _showAddAtletaModal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            )
          : _membros.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_off,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum membro cadastrado.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _membros.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final m = _membros[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8EDF5)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.surface,
                        backgroundImage: m.fotoUrl != null
                            ? NetworkImage(m.fotoUrl!)
                            : null,
                        child: m.fotoUrl == null
                            ? const Icon(
                                Icons.person,
                                color: AppColors.textMuted,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.nomeExibicao ?? m.email ?? 'Sem Nome',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              m.papelCodigo,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
