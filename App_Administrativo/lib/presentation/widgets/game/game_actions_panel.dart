import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/atleta_model.dart';
import 'package:kyarem_eventos/models/tipo_evento_model.dart';
import '../../screens/game/partida_screen.dart';

class GameActionsPanel extends StatelessWidget {
  final Atleta? jogadorSelecionado;
  final PeriodoPartida periodoAtual;
  final Future<void> Function(TipoEventoEsporte tipo) onRegistrarEvento;
  final List<TipoEventoEsporte> tiposDeEventos;

  const GameActionsPanel({
    super.key,
    required this.jogadorSelecionado,
    required this.periodoAtual,
    required this.onRegistrarEvento,
    required this.tiposDeEventos,
  });

  /// Busca o tipo de evento na lista carregada do banco
  TipoEventoEsporte? _buscarTipo(String nome) {
    try {
      return tiposDeEventos.firstWhere(
        (e) =>
            e.nome.trim().toLowerCase() == nome.trim().toLowerCase() ||
            e.codigo.trim().toLowerCase() == nome.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  bool _podeAcionar(TipoEventoEsporte tipo) {
    // Nenhuma ação é permitida quando parado (exceto se você quiser permitir na pausa, etc. Mas mantemos a regra original)
    const estadosBloqueados = [
      PeriodoPartida.naoIniciada,
      PeriodoPartida.pausada,
      PeriodoPartida.intervalo,
      PeriodoPartida.finalizada,
      PeriodoPartida.fechada,
    ];
    if (estadosBloqueados.contains(periodoAtual)) return false;

    // Se for um evento sistêmico (Início/Fim de tempo) que foi acidentalmente passado, desabilita
    final nomeLow = tipo.nome.toLowerCase();
    final sistemicos = [
      'inicio_1_tempo',
      'fim_1_tempo',
      'inicio_2_tempo',
      'fim_2_tempo',
    ];
    if (sistemicos.contains(nomeLow) ||
        sistemicos.contains(tipo.codigo.toLowerCase()))
      return false;

    // Se for de escopo PARTIDA, não precisa de jogador selecionado
    if (tipo.isEventoDePartida) return true;

    // Eventos de atleta ou equipe exigem jogador selecionado
    return jogadorSelecionado != null;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Mapeamento dos tipos principais
    final tipoGol = _buscarTipo("Gol");
    final tipoSub = _buscarTipo("Substituição");
    final tipoFalta = _buscarTipo("Falta");
    final tipoAmarelo = _buscarTipo("Cartao_Amarelo");
    final tipoVermelho = _buscarTipo("Cartao_Vermelho");

    // 2. Lista de nomes que ganharam botões fixos (para não repetir no grid)
    final nomesFixos = [
      "gol",
      "substituicao",
      "substituição",
      "falta",
      "cartao_amarelo",
      "cartão_amarelo",
      "cartao_vermelho",
      "cartão_vermelho",
    ];

    final nomesExcluidos = [
      'inicio_1_tempo',
      'inicio_2_tempo',
      'fim_partida',
      'fim_1_tempo',
      'fim_2_tempo',
      'pausa_tecnica',
      'fim_pausa_tecnica',
      'prorrogacao_dada',
      'partida_pausada',
      'acrescimo_dado',
      'intervalo',
      'acrescimo',
      'prorrogacao',
      'partida_retomada',
    ];

    final outrosEventos =
        tiposDeEventos.where((e) {
          final nomeLow = e.nome.toLowerCase();
          final codigoLow = e.codigo.toLowerCase();
          if (e.isEventoDePartida) return false; // Separa para outra lista
          return !nomesFixos.contains(nomeLow) &&
              !nomesFixos.contains(codigoLow) &&
              !nomesExcluidos.contains(nomeLow) &&
              !nomesExcluidos.contains(codigoLow);
        }).toList()..sort(
          (a, b) => (a.ordemExibicao ?? a.idx ?? 999).compareTo(
            b.ordemExibicao ?? b.idx ?? 999,
          ),
        );

    final eventosPartida =
        tiposDeEventos.where((e) {
          final nomeLow = e.nome.toLowerCase();
          final codigoLow = e.codigo.toLowerCase();
          if (!e.isEventoDePartida) return false;
          return !nomesExcluidos.contains(nomeLow) &&
              !nomesExcluidos.contains(codigoLow);
        }).toList()..sort(
          (a, b) => (a.ordemExibicao ?? a.idx ?? 999).compareTo(
            b.ordemExibicao ?? b.idx ?? 999,
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SEÇÃO 1: PRINCIPAIS (2 por linha) ---
          if (tipoGol != null || tipoSub != null)
            Row(
              children: [
                if (tipoGol != null)
                  Expanded(
                    child: _buildActionButton(
                      tipoGol.nomeFormatado,
                      const Color(0xFF00FFC2),
                      Colors.black,
                      onTap: _podeAcionar(tipoGol)
                          ? () => onRegistrarEvento(tipoGol)
                          : null,
                      enabled: _podeAcionar(tipoGol),
                    ),
                  ),
                if (tipoGol != null && tipoSub != null)
                  const SizedBox(width: 8),
                if (tipoSub != null)
                  Expanded(
                    child: _buildActionButton(
                      tipoSub.nomeFormatado,
                      Colors.white,
                      Colors.black,
                      onTap: _podeAcionar(tipoSub)
                          ? () => onRegistrarEvento(tipoSub)
                          : null,
                      enabled: _podeAcionar(tipoSub),
                    ),
                  ),
              ],
            ),

          // --- SEÇÃO 2: CARTÕES E FALTAS ---
          if (tipoFalta != null ||
              tipoAmarelo != null ||
              tipoVermelho != null) ...[
            const SizedBox(height: 16),
            const Text(
              "DISCIPLINA",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Falta em linha única para destaque ou dividida se preferir
            if (tipoFalta != null)
              _buildActionButton(
                tipoFalta.nomeFormatado,
                const Color(0xFFFF3D00),
                Colors.white,
                onTap: _podeAcionar(tipoFalta)
                    ? () => onRegistrarEvento(tipoFalta)
                    : null,
                enabled: _podeAcionar(tipoFalta),
              ),

            if (tipoAmarelo != null || tipoVermelho != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (tipoAmarelo != null)
                    Expanded(
                      child: _buildActionButton(
                        tipoAmarelo.nomeFormatado,
                        Colors.yellow,
                        Colors.black,
                        onTap: _podeAcionar(tipoAmarelo)
                            ? () => onRegistrarEvento(tipoAmarelo)
                            : null,
                        enabled: _podeAcionar(tipoAmarelo),
                      ),
                    ),
                  if (tipoAmarelo != null && tipoVermelho != null)
                    const SizedBox(width: 8),
                  if (tipoVermelho != null)
                    Expanded(
                      child: _buildActionButton(
                        tipoVermelho.nomeFormatado,
                        const Color(0xFFD32F2F),
                        Colors.white,
                        onTap: _podeAcionar(tipoVermelho)
                            ? () => onRegistrarEvento(tipoVermelho)
                            : null,
                        enabled: _podeAcionar(tipoVermelho),
                      ),
                    ),
                ],
              ),
            ],
          ],

          // --- SEÇÃO 3: OUTROS / SAÍDAS (DINÂMICO) ---
          if (outrosEventos.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              "OUTRAS AÇÕES",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final larguraBotao = (constraints.maxWidth - 8) / 2;

                return Wrap(
                  spacing: 8, // Espaço horizontal entre botões
                  runSpacing: 8, // Espaço vertical entre linhas
                  children: outrosEventos.map((tipo) {
                    return SizedBox(
                      width: larguraBotao,
                      child: _buildExitButton(
                        tipo.nomeFormatado,
                        onTap: _podeAcionar(tipo)
                            ? () => onRegistrarEvento(tipo)
                            : null,
                        enabled: _podeAcionar(tipo),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],

          // --- SEÇÃO 4: EVENTOS DE PARTIDA ---
          if (eventosPartida.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              "CONTROLE DE PARTIDA",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final larguraBotao = (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: eventosPartida.map((tipo) {
                    return SizedBox(
                      width: larguraBotao,
                      child: _buildExitButton(
                        tipo.nomeFormatado,
                        onTap: _podeAcionar(tipo)
                            ? () => onRegistrarEvento(tipo)
                            : null,
                        enabled: _podeAcionar(tipo),
                        textColor: const Color(0xFFE2B9FF), // Destaque visual
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // Widget para botões coloridos/principais
  Widget _buildActionButton(
    String label,
    Color fundo,
    Color texto, {
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: fundo,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: texto,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // Widget para botões brancos/secundários
  Widget _buildExitButton(
    String label, {
    required VoidCallback? onTap,
    bool enabled = true,
    Color textColor = Colors.black,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: textColor == Colors.black
                ? Colors.white
                : const Color(0xFF383838),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: textColor == Colors.black
                  ? Colors.grey[400]!
                  : textColor.withValues(alpha: 0.5),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor == Colors.black ? Colors.black : textColor,
            ),
          ),
        ),
      ),
    );
  }
}
