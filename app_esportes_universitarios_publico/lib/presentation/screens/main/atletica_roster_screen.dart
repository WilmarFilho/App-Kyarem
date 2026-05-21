// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../models/atletica.dart';
import '../../../../models/atletica_membro.dart';
import '../../../../models/campeonato.dart';
import '../../../../models/modalidade_catalogo.dart';
import '../../../../models/time_atletica.dart';
import '../../../../models/user_profile.dart';
import '../../../../services/campeonato_service.dart';
import '../../../../services/membro_service.dart';
import '../../../../services/modalidade_service.dart';
import '../../../../services/profile_service.dart';
import '../../../../services/time_service.dart';

class AtleticaRosterScreen extends StatefulWidget {
  final MinhaAtletica minhaAtletica;

  const AtleticaRosterScreen({super.key, required this.minhaAtletica});

  @override
  State<AtleticaRosterScreen> createState() => _AtleticaRosterScreenState();
}

class _AtleticaRosterScreenState extends State<AtleticaRosterScreen> {
  final _membroService = MembroService();
  final _campeonatoService = CampeonatoService();
  final _modalidadeService = ModalidadeService();
  final _timeService = TimeService();

  bool _isLoading = true;
  List<AtleticaMembro> _membros = [];
  List<TimeAtletica> _times = [];
  _RosterView _selectedView = _RosterView.elenco;
  String _selectedRoleFilter = 'ALL';
  String _selectedModalidadeFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _membroService.getMembros(widget.minhaAtletica.atleticaId!),
        _timeService.getTimesPorAtletica(widget.minhaAtletica.atleticaId!),
      ]);
      if (!mounted) return;
      setState(() {
        _membros = results[0] as List<AtleticaMembro>;
        _times = results[1] as List<TimeAtletica>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar membros: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddAtletaModal() async {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController();
    final emailController = TextEditingController();
    final senhaController = TextEditingController();
    final cpfController = TextEditingController();
    final buscaController = TextEditingController();
    final profileService = ProfileService();

    const selectedPapel = 'ATHLETE';
    bool isSaving = false;
    bool isExistingUser = false;
    UserProfile? selectedUser;
    List<UserProfile> searchResults = [];
    bool isSearching = false;
    Timer? debounce;

    Future<void> runSearch(
      String query,
      StateSetter setModalState,
    ) async {
      final trimmed = query.trim();
      if (trimmed.length < 3) {
        setModalState(() {
          isSearching = false;
          searchResults = [];
          if (selectedUser != null &&
              selectedUser!.nomeExibicao != buscaController.text.trim()) {
            selectedUser = null;
          }
        });
        return;
      }

      setModalState(() {
        isSearching = true;
        if (selectedUser != null &&
            selectedUser!.nomeExibicao != buscaController.text.trim()) {
          selectedUser = null;
        }
      });

      final results = await profileService.searchProfiles(trimmed);
      if (!mounted) return;
      if (buscaController.text.trim() != trimmed) return;
      setModalState(() {
        searchResults = results;
        isSearching = false;
      });
    }

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final currentStep = isExistingUser ? 1 : 0;

            return SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.of(ctx).size.height * 0.86,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  top: 20,
                  left: 20,
                  right: 20,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9E0EA),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Convocar atleta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentStep == 0
                            ? 'Escolha como deseja adicionar ao elenco.'
                            : isExistingUser
                            ? 'Encontre um usuário já cadastrado e confirme a convocação.'
                            : 'Cadastre um novo usuário e envie a convocação para a atlética.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildStepToggle(
                        currentIndex: currentStep,
                        labels: const ['Novo Usuário', 'Usuário Existente'],
                        onTap: (index) {
                          setModalState(() {
                            isExistingUser = index == 1;
                            selectedUser = null;
                            searchResults = [];
                            buscaController.clear();
                            emailController.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: isExistingUser
                            ? _buildExistingUserStep(
                                buscaController: buscaController,
                                selectedUser: selectedUser,
                                searchResults: searchResults,
                                isSearching: isSearching,
                                onChanged: (value) {
                                  debounce?.cancel();
                                  debounce = Timer(
                                    const Duration(milliseconds: 350),
                                    () => runSearch(value, setModalState),
                                  );
                                },
                                onSelect: (user) {
                                  setModalState(() {
                                    selectedUser = user;
                                    buscaController.text =
                                        user.nomeExibicao.isNotEmpty
                                        ? user.nomeExibicao
                                        : (user.email ?? '');
                                    emailController.text = user.email ?? '';
                                    searchResults = [];
                                  });
                                },
                                onClear: () {
                                  setModalState(() {
                                    selectedUser = null;
                                    buscaController.clear();
                                    emailController.clear();
                                    searchResults = [];
                                  });
                                },
                              )
                            : _buildNewUserStep(
                                nomeController: nomeController,
                                emailController: emailController,
                                senhaController: senhaController,
                                cpfController: cpfController,
                              ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                if (isExistingUser && selectedUser == null) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Selecione um usuário para continuar.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isSaving = true);
                                try {
                                  if (isExistingUser) {
                                    await _membroService.associarUsuarioExistente(
                                      widget.minhaAtletica.atleticaId!,
                                      {
                                        'email': selectedUser!.email?.trim(),
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
                                        'cpf': _digitsOnly(cpfController.text),
                                        'papelCodigo': selectedPapel,
                                      },
                                    );
                                  }

                                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                                } catch (e) {
                                  if (!ctx.mounted) return;
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Erro: $e')),
                                  );
                                } finally {
                                  if (ctx.mounted) {
                                    setModalState(() => isSaving = false);
                                  }
                                }
                              },
                        icon: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                isExistingUser
                                    ? Icons.person_add_alt_1_rounded
                                    : Icons.how_to_reg_rounded,
                              ),
                        label: Text(
                          isExistingUser
                              ? 'CONVOCAR USUÁRIO'
                              : 'CRIAR E CONVOCAR',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    debounce?.cancel();
    await _loadData();
  }

  Future<void> _showCriarTimeModal() async {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController();
    String? selectedCampeonatoId;
    Campeonato? selectedCampeonato;
    CampeonatoModalidade? selectedModalidade;
    List<String> selectedAtletaIds = [];
    bool isSaving = false;
    bool isLoadingModalidades = false;
    bool shouldShowErrors = false;
    List<Campeonato> campeonatos = [];
    List<CampeonatoModalidade> modalidadesDoCampeonato = [];
    final atletasDisponiveis = _membros.where(_isMembroElegivelParaTime).toList();

    try {
      campeonatos = await _campeonatoService.getCampeonatos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar campeonatos')),
      );
      return;
    }

    Future<void> carregarModalidades(
      String campeonatoId,
      StateSetter setModalState,
    ) async {
      setModalState(() {
        isLoadingModalidades = true;
        modalidadesDoCampeonato = [];
        selectedModalidade = null;
      });

      try {
        final data = await _campeonatoService.getModalidadesDoCampeonato(
          campeonatoId,
        );
        setModalState(() {
          modalidadesDoCampeonato = data;
          isLoadingModalidades = false;
        });
      } catch (_) {
        setModalState(() => isLoadingModalidades = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar modalidades')),
        );
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.of(ctx).size.height * 0.88,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  top: 20,
                  left: 20,
                  right: 20,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9E0EA),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Novo time permanente',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Defina o campeonato para filtrar as modalidades.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: nomeController,
                        label: 'Nome do Time',
                        hintText: 'Ex: Futsal Principal',
                        validator: (v) => v == null || v.isEmpty
                            ? 'Campo obrigatório'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildSelectorField(
                        label: 'Campeonato que vai inscrever o time',
                        value: selectedCampeonato?.nome,
                        hintText: 'Escolha um campeonato',
                        icon: Icons.emoji_events_rounded,
                        onTap: () async {
                          final result = await _showSelectionSheet<Campeonato>(
                            ctx,
                            title: 'Selecione o campeonato',
                            items: campeonatos,
                            selected: selectedCampeonato,
                            itemBuilder: (campeonato, isSelected) {
                              return _SelectionTile(
                                title: campeonato.nome,
                                subtitle:
                                    campeonato.edicao?.isNotEmpty == true
                                    ? campeonato.edicao
                                    : _campeonatoStatusLabel(
                                        campeonato.status,
                                      ),
                                selected: isSelected,
                              );
                            },
                          );

                          if (result == null) return;
                          setModalState(() {
                            selectedCampeonato = result;
                            selectedCampeonatoId = result.id;
                          });
                          await carregarModalidades(result.id, setModalState);
                        },
                        validator: () => selectedCampeonatoId == null
                            ? (shouldShowErrors
                                  ? 'Selecione um campeonato'
                                  : null)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildSelectorField(
                        label: 'Modalidade do catálogo',
                        value: selectedModalidade == null
                            ? null
                            : '${selectedModalidade!.modalidadeNome} • ${selectedModalidade!.generoLabel}',
                        hintText: selectedCampeonatoId == null
                            ? 'Escolha um campeonato primeiro'
                            : isLoadingModalidades
                            ? 'Carregando modalidades...'
                            : modalidadesDoCampeonato.isEmpty
                            ? 'Nenhuma modalidade vinculada'
                            : 'Escolha uma modalidade',
                        icon: Icons.sports_volleyball_rounded,
                        enabled:
                            selectedCampeonatoId != null && !isLoadingModalidades,
                        onTap: () async {
                          if (selectedCampeonatoId == null ||
                              isLoadingModalidades ||
                              modalidadesDoCampeonato.isEmpty) {
                            return;
                          }

                          final result =
                              await _showSelectionSheet<CampeonatoModalidade>(
                                ctx,
                                title: 'Selecione a modalidade',
                                items: modalidadesDoCampeonato,
                                selected: selectedModalidade,
                                itemBuilder: (modalidade, isSelected) {
                                  return _SelectionTile(
                                    title: modalidade.modalidadeNome,
                                    subtitle: modalidade.generoLabel,
                                    selected: isSelected,
                                  );
                                },
                              );

                          if (result == null) return;
                          setModalState(() => selectedModalidade = result);
                        },
                        validator: () => selectedModalidade == null
                            ? (shouldShowErrors
                                  ? 'Selecione uma modalidade'
                                  : null)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Atletas do Time',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${selectedAtletaIds.length} selecionado(s)',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            border: Border.all(color: const Color(0xFFE8EDF5)),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: atletasDisponiveis.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Nenhum atleta disponível na atlética.',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: atletasDisponiveis.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final atleta = atletasDisponiveis[index];
                                    final atletaId = atleta.userId;
                                    final isSelected = selectedAtletaIds
                                        .contains(atletaId);

                                    return InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        setModalState(() {
                                          if (isSelected) {
                                            selectedAtletaIds.remove(atletaId);
                                          } else {
                                            selectedAtletaIds.add(atletaId);
                                          }
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 160,
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.secondary.withValues(
                                                  alpha: 0.12,
                                                )
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.secondary
                                                : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 22,
                                              backgroundColor:
                                                  AppColors.surface,
                                              backgroundImage:
                                                  atleta.fotoUrl != null
                                                  ? NetworkImage(
                                                      atleta.fotoUrl!,
                                                    )
                                                  : null,
                                              child: atleta.fotoUrl == null
                                                  ? const Icon(
                                                      Icons.person,
                                                      color:
                                                          AppColors.textMuted,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    atleta.nomeExibicao ??
                                                        atleta.email ??
                                                        'Atleta',
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppColors.primary,
                                                    ),
                                                  ),
                                                  if (atleta.email?.isNotEmpty ==
                                                      true)
                                                    Text(
                                                      atleta.email!,
                                                      style: const TextStyle(
                                                        fontFamily: 'Poppins',
                                                        color:
                                                            AppColors.textMuted,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 160,
                                              ),
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppColors.secondary
                                                    : Colors.transparent,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? AppColors.secondary
                                                      : const Color(
                                                          0xFFCBD5E1,
                                                        ),
                                                ),
                                              ),
                                              child: isSelected
                                                  ? const Icon(
                                                      Icons.check,
                                                      size: 16,
                                                      color: Colors.white,
                                                    )
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                                setModalState(() => shouldShowErrors = true);
                                final campeonatoError =
                                    selectedCampeonatoId == null;
                                final modalidadeError =
                                    selectedModalidade == null;
                                if (!formKey.currentState!.validate() ||
                                    campeonatoError ||
                                    modalidadeError) {
                                  setModalState(() {});
                                  return;
                                }

                                setModalState(() => isSaving = true);
                                try {
                                  await _timeService.createTime({
                                    'atleticaId':
                                        widget.minhaAtletica.atleticaId,
                                    'modalidadeCatalogoId':
                                        selectedModalidade!.modalidadeId,
                                    'nome': nomeController.text.trim(),
                                    'atletaIds': selectedAtletaIds,
                                  });

                                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Time criado com sucesso!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  if (!ctx.mounted) return;
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Erro: $e')),
                                  );
                                } finally {
                                  if (ctx.mounted) {
                                    setModalState(() => isSaving = false);
                                  }
                                }
                              },
                        icon: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.shield_rounded),
                        label: const Text(
                          'CRIAR TIME',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await _loadData();
  }

  Future<void> _showEditarTimeModal(TimeAtletica time) async {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController(text: time.nome);
    bool isSaving = false;
    bool shouldShowErrors = false;
    ModalidadeCatalogo? selectedModalidade;
    List<ModalidadeCatalogo> modalidadesCatalogo = [];
    List<String> selectedAtletaIds = [];
    final atletasDisponiveis = _membros.where(_isMembroElegivelParaTime).toList();

    try {
      final results = await Future.wait([
        _modalidadeService.getModalidadesCatalogo(),
        _timeService.getAtletasTimePermanente(time.id),
      ]);
      modalidadesCatalogo = results[0] as List<ModalidadeCatalogo>;
      final atletasDoTime = results[1] as List<TimeAtleticaAtleta>;
      final atletaIdsElegiveis = atletasDisponiveis.map((m) => m.userId).toSet();
      selectedAtletaIds = atletasDoTime
          .map((atleta) => atleta.id)
          .where(atletaIdsElegiveis.contains)
          .toList();
      for (final modalidade in modalidadesCatalogo) {
        if (modalidade.id == time.modalidadeCatalogoId) {
          selectedModalidade = modalidade;
          break;
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados do time: $e')),
      );
      return;
    }

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.of(ctx).size.height * 0.88,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  top: 20,
                  left: 20,
                  right: 20,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9E0EA),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Editar time permanente',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Atualize modalidade, nome e os atletas vinculados a este time.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: nomeController,
                        label: 'Nome do Time',
                        hintText: 'Ex: Futsal Principal',
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Campo obrigatório'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildSelectorField(
                        label: 'Modalidade do time',
                        value: selectedModalidade == null
                            ? null
                            : '${selectedModalidade!.nome} • ${_generoLabel(selectedModalidade!.genero)}',
                        hintText: 'Escolha a modalidade',
                        icon: Icons.sports_volleyball_rounded,
                        onTap: () async {
                          final result =
                              await _showSelectionSheet<ModalidadeCatalogo>(
                                ctx,
                                title: 'Selecione a modalidade',
                                items: modalidadesCatalogo,
                                selected: selectedModalidade,
                                itemBuilder: (modalidade, isSelected) {
                                  return _SelectionTile(
                                    title: modalidade.nome,
                                    subtitle: _generoLabel(modalidade.genero),
                                    selected: isSelected,
                                  );
                                },
                              );

                          if (result == null) return;
                          setModalState(() => selectedModalidade = result);
                        },
                        validator: () => selectedModalidade == null
                            ? (shouldShowErrors
                                  ? 'Selecione uma modalidade'
                                  : null)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Atletas do Time',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${selectedAtletaIds.length} selecionado(s)',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            border: Border.all(color: const Color(0xFFE8EDF5)),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: atletasDisponiveis.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Nenhum atleta disponível na atlética.',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: atletasDisponiveis.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final atleta = atletasDisponiveis[index];
                                    final atletaId = atleta.userId;
                                    final isSelected = selectedAtletaIds
                                        .contains(atletaId);

                                    return InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        setModalState(() {
                                          if (isSelected) {
                                            selectedAtletaIds.remove(atletaId);
                                          } else {
                                            selectedAtletaIds.add(atletaId);
                                          }
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 160,
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.secondary.withValues(
                                                  alpha: 0.12,
                                                )
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.secondary
                                                : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 22,
                                              backgroundColor:
                                                  AppColors.surface,
                                              backgroundImage:
                                                  atleta.fotoUrl != null
                                                  ? NetworkImage(
                                                      atleta.fotoUrl!,
                                                    )
                                                  : null,
                                              child: atleta.fotoUrl == null
                                                  ? const Icon(
                                                      Icons.person,
                                                      color:
                                                          AppColors.textMuted,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    atleta.nomeExibicao ??
                                                        atleta.email ??
                                                        'Atleta',
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppColors.primary,
                                                    ),
                                                  ),
                                                  if (atleta.email?.isNotEmpty ==
                                                      true)
                                                    Text(
                                                      atleta.email!,
                                                      style: const TextStyle(
                                                        fontFamily: 'Poppins',
                                                        color:
                                                            AppColors.textMuted,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 160,
                                              ),
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppColors.secondary
                                                    : Colors.transparent,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? AppColors.secondary
                                                      : const Color(
                                                          0xFFCBD5E1,
                                                        ),
                                                ),
                                              ),
                                              child: isSelected
                                                  ? const Icon(
                                                      Icons.check,
                                                      size: 16,
                                                      color: Colors.white,
                                                    )
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                                setModalState(() => shouldShowErrors = true);
                                if (!formKey.currentState!.validate() ||
                                    selectedModalidade == null) {
                                  setModalState(() {});
                                  return;
                                }

                                setModalState(() => isSaving = true);
                                try {
                                  await _timeService.updateTime(time.id, {
                                    'nome': nomeController.text.trim(),
                                    'modalidadeCatalogoId':
                                        selectedModalidade!.id,
                                    'atletaIds': selectedAtletaIds,
                                  });

                                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Time atualizado com sucesso!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  if (!ctx.mounted) return;
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Erro: $e')),
                                  );
                                } finally {
                                  if (ctx.mounted) {
                                    setModalState(() => isSaving = false);
                                  }
                                }
                              },
                        icon: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: const Text(
                          'SALVAR ALTERAÇÕES',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await _loadData();
  }

  Widget _buildExistingUserStep({
    required TextEditingController buscaController,
    required UserProfile? selectedUser,
    required List<UserProfile> searchResults,
    required bool isSearching,
    required ValueChanged<String> onChanged,
    required ValueChanged<UserProfile> onSelect,
    required VoidCallback onClear,
  }) {
    return Column(
      key: const ValueKey('existing-user-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: buscaController,
          label: 'Buscar usuário',
          hintText: 'Digite nome ou e-mail',
          onChanged: onChanged,
          validator: (_) {
            if (selectedUser == null) {
              return 'Selecione um usuário existente';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        if (selectedUser != null)
          _SelectedUserCard(user: selectedUser, onClear: onClear)
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(
                  isSearching ? Icons.hourglass_top_rounded : Icons.search,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    buscaController.text.trim().length < 3
                        ? 'Digite ao menos 3 caracteres para começar a busca.'
                        : isSearching
                        ? 'Buscando usuários...'
                        : searchResults.isEmpty
                        ? 'Nenhum usuário encontrado para essa busca.'
                        : 'Selecione um resultado abaixo.',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: searchResults.isEmpty
              ? const SizedBox.shrink()
              : ListView.separated(
                  itemCount: searchResults.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = searchResults[index];
                    return _SearchUserTile(
                      user: user,
                      onTap: () => onSelect(user),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNewUserStep({
    required TextEditingController nomeController,
    required TextEditingController emailController,
    required TextEditingController senhaController,
    required TextEditingController cpfController,
  }) {
    return ListView(
      key: const ValueKey('new-user-step'),
      padding: EdgeInsets.zero,
      children: [
        _buildTextField(
          controller: nomeController,
          label: 'Nome completo',
          hintText: 'Digite o nome do atleta',
          validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: emailController,
          label: 'E-mail',
          hintText: 'Digite o e-mail do novo usuário',
          validator: (v) =>
              v == null || !v.contains('@') ? 'E-mail inválido' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: cpfController,
          label: 'CPF',
          hintText: '000.000.000-00',
          keyboardType: TextInputType.number,
          validator: (v) {
            final digits = _digitsOnly(v ?? '');
            if (digits.length != 11) {
              return 'Informe um CPF com 11 dígitos';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: senhaController,
          label: 'Senha inicial',
          hintText: 'Mínimo de 6 caracteres',
          obscureText: true,
          validator: (v) =>
              v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
        ),
      ],
    );
  }

  Widget _buildStepToggle({
    required int currentIndex,
    required List<String> labels,
    required ValueChanged<int> onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = currentIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: selected
                        ? AppColors.secondary
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectorField({
    required String label,
    required String? value,
    required String hintText,
    required IconData icon,
    required VoidCallback onTap,
    required String? Function() validator,
    bool enabled = true,
  }) {
    final errorText = validator();

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
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: InputDecorator(
            decoration: InputDecoration(
              errorText: errorText,
              filled: true,
              fillColor: enabled ? Colors.white : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
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
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: enabled ? AppColors.secondary : AppColors.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value ?? hintText,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: value != null
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: enabled ? AppColors.primary : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<T?> _showSelectionSheet<T>(
    BuildContext context, {
    required String title,
    required List<T> items,
    required T? selected,
    required Widget Function(T item, bool isSelected) itemBuilder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.7,
          ),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.of(context).pop(item),
                      child: itemBuilder(item, item == selected),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
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
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
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

  List<AtleticaMembro> get _membrosFiltrados {
    if (_selectedRoleFilter == 'ALL') return _membros;
    return _membros
        .where((m) => m.papelCodigo.toUpperCase() == _selectedRoleFilter)
        .toList();
  }

  bool _isMembroElegivelParaTime(AtleticaMembro membro) {
    return membro.papelCodigo.toUpperCase() == 'ATHLETE' &&
        membro.status.trim().toUpperCase() == 'ATIVO';
  }

  String _membroStatusLabel(String status) {
    switch (status.trim().toUpperCase()) {
      case 'ATIVO':
        return 'Convocação aceita';
      case 'CONVOCADO':
        return 'Aguardando aceite';
      case 'RECUSADO':
        return 'Convocação recusada';
      default:
        return status
            .toLowerCase()
            .replaceAll('_', ' ')
            .split(' ')
            .map((part) => part.isEmpty
                ? part
                : '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
    }
  }

  Color _membroStatusColor(String status) {
    switch (status.trim().toUpperCase()) {
      case 'ATIVO':
        return Colors.green;
      case 'CONVOCADO':
        return Colors.orange;
      case 'RECUSADO':
        return Colors.redAccent;
      default:
        return AppColors.textMuted;
    }
  }

  List<TimeAtletica> get _timesFiltrados {
    if (_selectedModalidadeFilter == 'ALL') return _times;
    return _times
        .where((t) => t.modalidadeCatalogoId == _selectedModalidadeFilter)
        .toList();
  }

  List<_FilterOption> get _roleFilters => const [
    _FilterOption(value: 'ALL', label: 'Todos'),
    _FilterOption(value: 'PRESIDENT', label: 'Presidente'),
    _FilterOption(value: 'DIRECTOR', label: 'Diretor'),
    _FilterOption(value: 'ATHLETE', label: 'Atleta'),
  ];

  List<_FilterOption> get _modalidadeFilters {
    final seen = <String>{};
    final options = <_FilterOption>[
      const _FilterOption(value: 'ALL', label: 'Todas'),
    ];

    for (final time in _times) {
      if (!seen.add(time.modalidadeCatalogoId)) continue;
      options.add(
        _FilterOption(
          value: time.modalidadeCatalogoId,
          label: time.modalidadeNome ?? 'Modalidade',
        ),
      );
    }
    return options;
  }

  String _campeonatoStatusLabel(String status) {
    switch (status.trim().toUpperCase()) {
      case 'EM_ANDAMENTO':
        return 'Em andamento';
      case 'AGENDADO':
        return 'Agendado';
      case 'FINALIZADO':
        return 'Finalizado';
      case 'CANCELADO':
        return 'Cancelado';
      default:
        return status
            .toLowerCase()
            .replaceAll('_', ' ')
            .split(' ')
            .map((part) => part.isEmpty
                ? part
                : '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
    }
  }

  Widget _buildContentToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TopSegmentButton(
              label: 'Elenco',
              icon: Icons.groups_rounded,
              selected: _selectedView == _RosterView.elenco,
              onTap: () {
                setState(() => _selectedView = _RosterView.elenco);
              },
            ),
          ),
          Expanded(
            child: _TopSegmentButton(
              label: 'Times permanentes',
              icon: Icons.shield_rounded,
              selected: _selectedView == _RosterView.times,
              onTap: () {
                setState(() => _selectedView = _RosterView.times);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTags() {
    final options = _selectedView == _RosterView.elenco
        ? _roleFilters
        : _modalidadeFilters;
    final selectedValue = _selectedView == _RosterView.elenco
        ? _selectedRoleFilter
        : _selectedModalidadeFilter;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final selected = option.value == selectedValue;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: selected,
              label: Text(option.label),
              onSelected: (_) {
                setState(() {
                  if (_selectedView == _RosterView.elenco) {
                    _selectedRoleFilter = option.value;
                  } else {
                    _selectedModalidadeFilter = option.value;
                  }
                });
              },
              selectedColor: AppColors.secondary.withValues(alpha: 0.14),
              checkmarkColor: AppColors.secondary,
              side: BorderSide(
                color: selected
                    ? AppColors.secondary
                    : const Color(0xFFD7E0EA),
              ),
              labelStyle: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.secondary : AppColors.textMuted,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMembersList() {
    final items = _membrosFiltrados;
    if (items.isEmpty) {
      return const _EmptyState(
        icon: Icons.person_search_rounded,
        message: 'Nenhum membro encontrado para esse filtro.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 108),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final m = items[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EDF5)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surface,
                backgroundImage:
                    m.fotoUrl != null ? NetworkImage(m.fotoUrl!) : null,
                child: m.fotoUrl == null
                    ? const Icon(Icons.person, color: AppColors.textMuted)
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
                    if (m.email?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        m.email!,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            m.papelLabel,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: AppColors.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            final statusColor = _membroStatusColor(m.status);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _membroStatusLabel(m.status),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamsList() {
    final items = _timesFiltrados;
    if (items.isEmpty) {
      return const _EmptyState(
        icon: Icons.shield_outlined,
        message: 'Nenhum time permanente encontrado para esse filtro.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 108),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final time = items[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EDF5)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time.nome,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time.modalidadeNome ?? 'Modalidade não informada',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (time.genero?.isNotEmpty == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _generoLabel(time.genero),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => _showEditarTimeModal(time),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Editar',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _generoLabel(String? genero) {
    switch ((genero ?? '').toUpperCase()) {
      case 'M':
        return 'Masculino';
      case 'F':
        return 'Feminino';
      default:
        return 'Misto';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMembers = _membros.isNotEmpty;
    final hasTeams = _times.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Elenco de Membros',
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
              child: CircularProgressIndicator(color: AppColors.secondary),
            )
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                  child: Column(
                    children: [
                      _buildContentToggle(),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildFilterTags(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _selectedView == _RosterView.elenco
                      ? hasMembers
                            ? _buildMembersList()
                            : const _EmptyState(
                                icon: Icons.person_off,
                                message: 'Nenhum membro cadastrado.',
                              )
                      : hasTeams
                      ? _buildTeamsList()
                      : const _EmptyState(
                          icon: Icons.shield_outlined,
                          message: 'Nenhum time permanente cadastrado.',
                        ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _BottomActionButton(
                  icon: Icons.shield_rounded,
                  label: 'Criar time',
                  onTap: _showCriarTimeModal,
                ),
              ),
              Expanded(
                child: _BottomActionButton(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'Convocar atleta',
                  onTap: _showAddAtletaModal,
                  highlighted: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _RosterView { elenco, times }

class _FilterOption {
  final String value;
  final String label;

  const _FilterOption({required this.value, required this.label});
}

class _TopSegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TopSegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.secondary : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.secondary : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  const _BottomActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Material(
        color: highlighted ? AppColors.secondary : Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: highlighted ? Colors.white : AppColors.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: highlighted ? Colors.white : AppColors.primary,
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

class _SelectionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;

  const _SelectionTile({
    required this.title,
    this.subtitle,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.secondary.withValues(alpha: 0.12)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? AppColors.secondary : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                if (subtitle?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (selected)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.secondary,
            ),
        ],
      ),
    );
  }
}

class _SearchUserTile extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onTap;

  const _SearchUserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.surface,
              backgroundImage:
                  user.fotoUrl != null ? NetworkImage(user.fotoUrl!) : null,
              child: user.fotoUrl == null
                  ? const Icon(Icons.person, color: AppColors.textMuted)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nomeExibicao,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    user.email ?? 'Sem e-mail',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedUserCard extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onClear;

  const _SelectedUserCard({required this.user, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            backgroundImage:
                user.fotoUrl != null ? NetworkImage(user.fotoUrl!) : null,
            child: user.fotoUrl == null
                ? const Icon(Icons.person, color: AppColors.textMuted)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nomeExibicao,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  user.email ?? 'Sem e-mail',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');
