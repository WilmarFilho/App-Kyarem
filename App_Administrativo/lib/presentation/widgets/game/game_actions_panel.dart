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
        (e) => e.nome.trim().toLowerCase() == nome.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
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
      "substituição",
      "falta",
      "cartao_amarelo",
      "cartao_vermelho",
    ];

    // 3. LISTA DE EXCLUSÃO: Tipos que existem no banco mas NÃO devem virar botões
    // Adicione aqui nomes de eventos de sistema, logs ou pormenores técnicos
    final nomesExcluidos = [
      "inicio_1_tempo",
      "inicio_2_tempo",
      "fim_partida",
      "fim_1_tempo",
      "fim_2_tempo",
      "pausa_tecnica",
      "fim_pausa_tecnica",
      "prorrogacao_dada",
      "partida_pausada",
      "acrescimo_dado",
      "intervalo",
      'acrescimo',
      'prorrogacao',
      'partida_retomada',
    ];

    // Filtra o que sobrou (ex: Tiro Lateral, Escanteio, etc) e ignora os excluídos
    final outrosEventos = tiposDeEventos.where((e) {
      final nomeLow = e.nome.toLowerCase();
      return !nomesFixos.contains(nomeLow) && !nomesExcluidos.contains(nomeLow);
    }).toList();

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
                      onTap: () => onRegistrarEvento(tipoGol),
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
                      onTap: () => onRegistrarEvento(tipoSub),
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
                onTap: () => onRegistrarEvento(tipoFalta),
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
                        onTap: () => onRegistrarEvento(tipoAmarelo),
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
                        onTap: () => onRegistrarEvento(tipoVermelho),
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
                // Usamos as constraints do pai (o Container com padding 16)
                // para calcular a largura exata.
                // (Largura total disponível - espaçamento central de 8) / 2
                final larguraBotao = (constraints.maxWidth - 8) / 2;

                return Wrap(
                  spacing: 8, // Espaço horizontal entre botões
                  runSpacing: 8, // Espaço vertical entre linhas
                  children: outrosEventos.map((tipo) {
                    return SizedBox(
                      width: larguraBotao,
                      child: _buildExitButton(
                        tipo.nomeFormatado,
                        onTap: () => onRegistrarEvento(tipo),
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
    required VoidCallback onTap,
  }) {
    bool isEnabled =
        jogadorSelecionado != null &&
        periodoAtual != PeriodoPartida.naoIniciada;
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
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
  Widget _buildExitButton(String label, {required VoidCallback onTap}) {
    bool isEnabled =
        jogadorSelecionado != null &&
        periodoAtual != PeriodoPartida.naoIniciada;
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[400]!),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
