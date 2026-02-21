import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/partida_model.dart';
import 'package:kyarem_eventos/models/tipo_evento_model.dart';
import 'package:kyarem_eventos/presentation/screens/game/resumo_partida_screen.dart';
import 'package:kyarem_eventos/services/partida_service.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../widgets/game/game_scoreboard.dart';
import '../../widgets/game/game_events_feed.dart';
import '../../widgets/game/game_timer_card.dart';
import '../../widgets/game/game_field.dart';
import '../../widgets/game/game_actions_panel.dart';

// Enum para controlar os períodos da partida
enum PeriodoPartida {
  naoIniciada,
  primeiroTempo,
  intervalo,
  segundoTempo,
  prorrogacao,
  finalizada,
}

// Modelo para representar um evento no feed
class EventoPartida {
  final String tipo;
  final String jogadorNome;
  final int jogadorNumero;
  final Color corTime;
  final String horario;
  final DateTime timestamp;

  EventoPartida({
    required this.tipo,
    required this.jogadorNome,
    required this.jogadorNumero,
    required this.corTime,
    required this.horario,
    required this.timestamp,
  });

  String get descricao {
    switch (tipo) {
      case 'INICIO_1_TEMPO':
        return '🟢 Início do 1º Tempo';
      case 'INICIO_2_TEMPO':
        return '🟢 Início do 2º Tempo';
      case 'PARTIDA_PAUSADA':
        return '⏸️ Partida Pausada';
      case 'PARTIDA_RETOMADA':
        return '▶️ Partida Retomada';
      case 'PAUSA_TECNICA':
        return '🔴 Pausa Técnica';
      case 'Substituição':
        return jogadorNome.contains('↔')
            ? jogadorNome
            : 'Substituição #$jogadorNumero';
      case 'Pausa Iniciada':
        return '⏸️ Partida Pausada';
      case 'Pausa Finalizada':
        return '▶️ Partida Retomada';
      case 'Início do 1º Tempo':
        return '🟢 Início do 1º Tempo';
      case 'Fim do 1º Tempo':
        return '🔶 Fim do 1º Tempo';
      case 'Início do 2º Tempo':
        return '🟢 Início do 2º Tempo';
      case 'Fim da Partida':
        return '🏁 Fim da Partida';
      case 'Prorrogação do 1º Tempo':
        return '⏰ Prorrogação do 1º Tempo';
      case 'Prorrogação do 2º Tempo':
        return '⏰ Prorrogação do 2º Tempo';
      // Eventos de pausa técnica
      default:
        if (tipo.startsWith('Pausa Técnica - ')) {
          return '🔴 $tipo';
        }
        if (tipo.startsWith('Fim Pausa Técnica - ')) {
          return '▶️ $tipo';
        }
        return '$tipo #$jogadorNumero';
    }
  }
}

// Modelo simples para gerenciar os jogadores na tela
class JogadorFutsal {
  final int numero;
  final String nome;
  final Color corTime;
  final Offset posicao; // Posição relativa no Stack (0.0 a 1.0)

  JogadorFutsal({
    required this.numero,
    required this.nome,
    required this.corTime,
    required this.posicao,
  });
}

class PartidaRunningScreen extends StatefulWidget {
  final Partida partida;

  const PartidaRunningScreen({super.key, required this.partida});

  @override
  State<PartidaRunningScreen> createState() => _PartidaRunningScreenState();
}

class _PartidaRunningScreenState extends State<PartidaRunningScreen> {
  // Constantes de tempo da partida (em segundos) - fácil configuração
  static const int duracaoPrimeiroTempo = 20 * 60; // 20 minutos
  static const int duracaoSegundoTempo = 20 * 60; // 20 minutos

  final PartidaService _partidaService = PartidaService();

  // 2. Lista para armazenar os tipos vindos do banco
  List<TipoEventoEsporte> _tiposDeEventosDisponiveis = [];

  late int _golsA;
  late int _golsB;

  @override
  void initState() {
    super.initState();

    _golsA = widget.partida.placarA;
    _golsB = widget.partida.placarB;

    // Chama a busca dos eventos assim que a tela inicia
    _buscarConfiguracoesDeEventos();
  }

  Future<void> _buscarConfiguracoesDeEventos() async {
    try {
      final tipos = await _partidaService.buscarTiposDeEventoDaPartida(
        widget.partida.modalidadeId,
      );
      setState(() {
        _tiposDeEventosDisponiveis = tipos;
      });
      // ignore: empty_catches
    } catch (e) {}
  }

  // Método para registrar eventos sistêmicos usando as IDs reais carregadas
  Future<void> _registrarEventoSistemico(String nomeEventoNoBanco) async {
    // 1. Tentar encontrar o tipo de evento na lista carregada
    final tipoEvento = _tiposDeEventosDisponiveis.firstWhere(
      (e) => e.nome == nomeEventoNoBanco,
      orElse: () => TipoEventoEsporte(
        id: '',
        nome: nomeEventoNoBanco,
        esporteId: '',
        idx: 0,
      ),
    );

    // 2. Registrar visualmente no feed
    final eventoFeed = EventoPartida(
      tipo:
          nomeEventoNoBanco, // O switch do descricao no modelo vai precisar lidar com isso
      jogadorNome: '',
      jogadorNumero: 0,
      corTime: Colors.green,
      horario: _formatarTempo(_segundos),
      timestamp: DateTime.now(),
    );

    setState(() {
      _eventosPartida.insert(0, eventoFeed);
    });

    // 3. Salvar no Banco de Dados com a ID real
    if (tipoEvento.id.isNotEmpty) {
      debugPrint(
        'Salvando no banco: ${tipoEvento.nome} (ID: ${tipoEvento.id})',
      );
       await _partidaService.salvarEvento(
         partidaId: widget.partida.id,
         tipoEventoId: tipoEvento.id,
         tempoFormatado: _segundos,
       );
    }
  }

  Timer? _timer;
  int _segundos = 0;
  bool _rodando = false;

  // Variáveis para controle de pausa
  Timer? _timerPausa;
  int _segundosPausa = 0;
  bool _partidaJaIniciou = false;

  // Controle dos períodos da partida
  PeriodoPartida _periodoAtual = PeriodoPartida.naoIniciada;

  // Variáveis para controle de prorrogação
  int _tempoProrrogacao = 0; // Em segundos
  bool _temProrrogacao = false;
  bool _estaNaProrrogacao = false;

  // Variáveis para controle de pausa técnica
  Timer? _timerPausaTecnica;
  int _segundosPausaTecnica = 0;
  bool _emPausaTecnica = false;
  String _timeEmPausaTecnica = '';

  // Controle de uso das pausas técnicas por período
  int _pausasTecnicasTimeAPrimeiroTempo = 0;
  int _pausasTecnicasTimeBPrimeiroTempo = 0;
  int _pausasTecnicasTimeASegundoTempo = 0;
  int _pausasTecnicasTimeBSegundoTempo = 0;

  JogadorFutsal? _jogadorSelecionado;
  final List<EventoPartida> _eventosPartida = []; // Lista de eventos dinâmica

  // Lista de jogadores posicionados taticamente (Goleiro, Fixo, Alas, Pivô)
  final List<JogadorFutsal> _jogadoresA = [
    JogadorFutsal(
      numero: 1,
      nome: "Goleiro A",
      corTime: Colors.orange,
      posicao: const Offset(0.03, 0.45),
    ),
    JogadorFutsal(
      numero: 5,
      nome: "Fixo A",
      corTime: Colors.orange,
      posicao: const Offset(0.20, 0.45),
    ),
    JogadorFutsal(
      numero: 7,
      nome: "Ala Esq A",
      corTime: Colors.orange,
      posicao: const Offset(0.30, 0.15),
    ),
    JogadorFutsal(
      numero: 11,
      nome: "Ala Dir A",
      corTime: Colors.orange,
      posicao: const Offset(0.30, 0.75),
    ),
    JogadorFutsal(
      numero: 10,
      nome: "Pivô A",
      corTime: Colors.orange,
      posicao: const Offset(0.35, 0.45),
    ),
  ];

  final List<JogadorFutsal> _jogadoresB = [
    JogadorFutsal(
      numero: 12,
      nome: "Goleiro B",
      corTime: Colors.blue,
      posicao: const Offset(0.87, 0.45),
    ),
    JogadorFutsal(
      numero: 4,
      nome: "Fixo B",
      corTime: Colors.blue,
      posicao: const Offset(0.73, 0.45),
    ),
    JogadorFutsal(
      numero: 8,
      nome: "Ala Esq B",
      corTime: Colors.blue,
      posicao: const Offset(0.65, 0.15),
    ),
    JogadorFutsal(
      numero: 9,
      nome: "Ala Dir B",
      corTime: Colors.blue,
      posicao: const Offset(0.65, 0.75),
    ),
    JogadorFutsal(
      numero: 7,
      nome: "Pivô B",
      corTime: Colors.blue,
      posicao: const Offset(0.57, 0.45),
    ),
  ];

  // Listas de jogadores reservas (banco)
  final List<JogadorFutsal> _reservasA = [
    JogadorFutsal(
      numero: 2,
      nome: "Reserva A1",
      corTime: Colors.orange,
      posicao: const Offset(0, 0),
    ),
    JogadorFutsal(
      numero: 3,
      nome: "Reserva A2",
      corTime: Colors.orange,
      posicao: const Offset(0, 0),
    ),
    JogadorFutsal(
      numero: 6,
      nome: "Reserva A3",
      corTime: Colors.orange,
      posicao: const Offset(0, 0),
    ),
    JogadorFutsal(
      numero: 8,
      nome: "Reserva A4",
      corTime: Colors.orange,
      posicao: const Offset(0, 0),
    ),
  ];

  final List<JogadorFutsal> _reservasB = [
    JogadorFutsal(
      numero: 1,
      nome: "Reserva B1",
      corTime: Colors.blue,
      posicao: const Offset(0, 0),
    ),
    JogadorFutsal(
      numero: 2,
      nome: "Reserva B2",
      corTime: Colors.blue,
      posicao: const Offset(0, 0),
    ),
    JogadorFutsal(
      numero: 5,
      nome: "Reserva B3",
      corTime: Colors.blue,
      posicao: const Offset(0, 0),
    ),
    JogadorFutsal(
      numero: 6,
      nome: "Reserva B4",
      corTime: Colors.blue,
      posicao: const Offset(0, 0),
    ),
  ];

  @override
  void dispose() {
    _timer?.cancel(); // Limpar timer ao sair da tela
    _timerPausa?.cancel(); // Limpar timer de pausa
    _timerPausaTecnica?.cancel(); // Limpar timer de pausa técnica
    super.dispose();
  }

  // Verifica se deve finalizar período automaticamente
  void _verificarFimPeriodo() {
    switch (_periodoAtual) {
      case PeriodoPartida.primeiroTempo:
        if (_segundos >= duracaoPrimeiroTempo) {
          if (_temProrrogacao && !_estaNaProrrogacao) {
            // Iniciar prorrogação do primeiro tempo
            _iniciarProrrogacao("Prorrogação do 1º Tempo");
          } else {
            _finalizarPrimeiroTempo();
          }
        }
        break;
      case PeriodoPartida.segundoTempo:
        if (_segundos >= duracaoSegundoTempo) {
          if (_temProrrogacao && !_estaNaProrrogacao) {
            // Iniciar prorrogação do segundo tempo
            _iniciarProrrogacao("Prorrogação do 2º Tempo");
          } else {
            _finalizarPartida();
          }
        }
        break;
      case PeriodoPartida.prorrogacao:
        if (_segundos >= _tempoProrrogacao) {
          _finalizarPartida();
        }
        break;
      default:
        break;
    }
  }

  // Inicia período de prorrogação
  void _iniciarProrrogacao(String descricao) {
    _timer?.cancel();
    setState(() {
      _rodando = false;
      _estaNaProrrogacao = true;
      _periodoAtual = PeriodoPartida.prorrogacao;
      _segundos = 0; // Reset do cronômetro para a prorrogação
    });

    _registrarEventoOficial(descricao);
  }

  // Finaliza o primeiro tempo automaticamente ou manualmente
  void _finalizarPrimeiroTempo() {
    _timer?.cancel();
    _timerPausa?.cancel();

    setState(() {
      _rodando = false;
      _periodoAtual = PeriodoPartida.intervalo;
      // Zerar configuração de prorrogação ao entrar no intervalo
      _temProrrogacao = false;
      _tempoProrrogacao = 0;
      _estaNaProrrogacao = false;
    });

    _registrarEventoOficial('Fim do 1º Tempo');
  }

  // Finaliza o segundo tempo e a partida
  void _finalizarPartida() {
    _timer?.cancel();
    _timerPausa?.cancel();

    setState(() {
      _rodando = false;
      _periodoAtual = PeriodoPartida.finalizada;
    });

    _registrarEventoOficial('Fim da Partida');
  }

  // Finaliza o segundo tempo manualmente
  void _finalizarSegundoTempo() {
    _finalizarPartida();
  }

  // Abre modal para selecionar tempo de prorrogação
  void _abrirModalProrrogacao() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Definir Prorrogação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite o tempo de prorrogação em minutos:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutos',
                border: OutlineInputBorder(),
                hintText: 'Ex: 5, 10, 15...',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final String input = controller.text.trim();
              final int? minutos = int.tryParse(input);

              if (minutos == null || minutos <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Por favor, digite um número válido de minutos!',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setState(() {
                _tempoProrrogacao = minutos * 60; // Converter para segundos
                _temProrrogacao = true;
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Prorrogação de $minutos minutos configurada com sucesso!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // Verifica se o time ainda pode usar pausa técnica no período atual
  bool _podeUsarPausaTecnica(bool isTimeA) {
    switch (_periodoAtual) {
      case PeriodoPartida.primeiroTempo:
      case PeriodoPartida.prorrogacao:
        return isTimeA
            ? _pausasTecnicasTimeAPrimeiroTempo < 1
            : _pausasTecnicasTimeBPrimeiroTempo < 1;
      case PeriodoPartida.segundoTempo:
        return isTimeA
            ? _pausasTecnicasTimeASegundoTempo < 1
            : _pausasTecnicasTimeBSegundoTempo < 1;
      default:
        return false;
    }
  }

  // Inicia pausa técnica para um time
  void _iniciarPausaTecnica(bool isTimeA) {
    // 1. Pegar nomes corretos das equipes de dentro do objeto partida
    final nomeTimeA = widget.partida.equipeA?.nome ?? "Time A";
    final nomeTimeB = widget.partida.equipeB?.nome ?? "Time B";

    // Verificações de segurança
    if (_emPausaTecnica) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Já há uma pausa técnica em andamento!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_podeUsarPausaTecnica(isTimeA)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${isTimeA ? nomeTimeA : nomeTimeB} já usou sua pausa técnica neste período!",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Pausar cronometro principal se estiver rodando
    if (_rodando) {
      _timer?.cancel();
      setState(() {
        _rodando = false;
      });
    }

    // Iniciar pausa técnica
    setState(() {
      _emPausaTecnica = true;
      _timeEmPausaTecnica = isTimeA ? nomeTimeA : nomeTimeB;
      _segundosPausaTecnica = 0;
    });

    // Incrementar contador do time no período atual
    switch (_periodoAtual) {
      case PeriodoPartida.primeiroTempo:
      case PeriodoPartida.prorrogacao:
        if (isTimeA) {
          _pausasTecnicasTimeAPrimeiroTempo++;
        } else {
          _pausasTecnicasTimeBPrimeiroTempo++;
        }
        break;
      case PeriodoPartida.segundoTempo:
        if (isTimeA) {
          _pausasTecnicasTimeASegundoTempo++;
        } else {
          _pausasTecnicasTimeBSegundoTempo++;
        }
        break;
      default:
        break;
    }

    // Timer de 1 minuto (60 segundos) para pausa técnica
    _timerPausaTecnica = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        // Verificação para evitar erros se a tela for fechada
        setState(() {
          _segundosPausaTecnica++;
          if (_segundosPausaTecnica >= 60) {
            _finalizarPausaTecnica();
          }
        });
      }
    });

    // 2. Registrar evento usando a ID oficial do arquivo events.txt
    // O nome deve ser 'PAUSA_TECNICA' para bater com o id '33a611e7-1038-44b1-b811-0063d3ffdbc9'
    _registrarEventoOficial('PAUSA_TECNICA');
  }

  // Finaliza pausa técnica manualmente ou automaticamente
  void _finalizarPausaTecnica() {
    _timerPausaTecnica?.cancel();

    setState(() {
      _emPausaTecnica = false;
    });

    // Registrar evento de fim de pausa técnica
    _registrarEventoOficial('Fim Pausa Técnica - $_timeEmPausaTecnica');

    _timeEmPausaTecnica = '';
    _segundosPausaTecnica = 0;
  }

  void _alternarCronometro() {
    setState(() {
      _rodando = !_rodando;

      if (_rodando) {
        switch (_periodoAtual) {
          case PeriodoPartida.naoIniciada:
            _periodoAtual = PeriodoPartida.primeiroTempo;
            _segundos = 0;
            // ID: e736283c-6874-4b53-8386-8f3b14569501 (idx: 5)
            _registrarEventoSistemico('INICIO_1_TEMPO');
            break;

          case PeriodoPartida.intervalo:
            _periodoAtual = PeriodoPartida.segundoTempo;
            _segundos = 0;
            // ID: b8eb310e-bfe3-4618-8af1-33d86ee51bb5 (idx: 12)
            _registrarEventoSistemico('INICIO_2_TEMPO');
            break;

          default:
            // Se for apenas um "Resume" após um pause comum
            _registrarEventoSistemico('PARTIDA_RETOMADA');
            break;
        }

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _segundos++;
            _verificarFimPeriodo();
          });
        });
        _timerPausa?.cancel();
        _partidaJaIniciou = true;
      } else {
        _timer?.cancel();
        if (_periodoAtual != PeriodoPartida.finalizada && !_emPausaTecnica) {
          _timerPausa = Timer.periodic(const Duration(seconds: 1), (timer) {
            setState(() => _segundosPausa++);
          });

          // ID: 165522c0-25cf-4941-a1e1-451c63da7b23 (idx: 11)
          _registrarEventoSistemico('PARTIDA_PAUSADA');
        }
      }
    });
  }

  void _registrarEvento(String tipo) {
    // Verificar se é permitido registrar eventos no estado atual da partida
    if (_periodoAtual == PeriodoPartida.naoIniciada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Não é possível registrar eventos antes de iniciar a partida!",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_periodoAtual == PeriodoPartida.finalizada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Não é possível registrar eventos com a partida encerrada!",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_periodoAtual == PeriodoPartida.intervalo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Não é possível registrar eventos durante o intervalo!",
          ),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    if (_jogadorSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecione um jogador no campo primeiro!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Tratamento especial para substituições
    if (tipo == "Substituição") {
      _abrirModalSubstituicaoNovo();
      return;
    }

    // Guardar informações do jogador antes de limpar seleção
    final jogador = _jogadorSelecionado!;
    final isTimeA = _jogadoresA.contains(jogador);

    // Criar evento para o feed
    final evento = EventoPartida(
      tipo: tipo,
      jogadorNome: jogador.nome,
      jogadorNumero: jogador.numero,
      corTime: jogador.corTime,
      horario: _formatarTempo(_segundos),
      timestamp: DateTime.now(),
    );

    // Lógica de exemplo para aumentar placar
    if (tipo == "Gol") {
      setState(() {
        if (isTimeA) {
          _golsA++;
        } else {
          _golsB++;
        }
      });
    }

    // Adicionar evento ao feed e limpar seleção do jogador após registrar evento
    setState(() {
      _eventosPartida.insert(0, evento); // Adiciona no início da lista
      _jogadorSelecionado = null;
    });

    // Mostrar confirmação do evento registrado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "$tipo registrado para ${jogador.nome} (#${jogador.numero})",
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    // Aqui você pode integrar com seu repositório/banco de dados
    _salvarEventoNoBanco(tipo, jogador);
  }

  // Método específico para eventos oficiais (não relacionados a jogadores)
  void _registrarEventoOficial(String tipo) {
    final evento = EventoPartida(
      tipo: tipo,
      jogadorNome: '', // Eventos oficiais não precisam de jogador
      jogadorNumero: 0,
      corTime: Colors.blue, // Cor azul para eventos oficiais
      horario: _formatarTempo(_segundos),
      timestamp: DateTime.now(),
    );

    setState(() {
      _eventosPartida.insert(0, evento);
    });
  }

  // Método específico para registrar eventos de pausa
  void _registrarEventoPausa(String tipo) {
    final evento = EventoPartida(
      tipo: tipo,
      jogadorNome: '', // Eventos de pausa não precisam de jogador
      jogadorNumero: 0,
      corTime: Colors.grey, // Cor neutra para eventos de pausa
      horario: _formatarTempo(_segundos),
      timestamp: DateTime.now(),
    );

    setState(() {
      _eventosPartida.insert(0, evento);
    });
  }

  Future<void> _salvarEventoNoBanco(String tipo, JogadorFutsal jogador) async {
    // Exemplo:
    // await _partidaRepository.registrarEvento(
    //   sumulaId: widget.partidaId,
    //   atletaNome: jogador.nome,
    //   tipo: tipo.toUpperCase(),
    //   time: _jogadoresA.contains(jogador) ? 'A' : 'B',
    // );

    debugPrint('Evento $tipo salvo para jogador ${jogador.nome}');
  }

  String _formatarTempo(int totalSegundos) {
    int min = totalSegundos ~/ 60;
    int seg = totalSegundos % 60;
    return '${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}';
  }

  void _abrirDetalhesJogador(JogadorFutsal jogador) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: jogador.corTime,
              child: Text(
                "#${jogador.numero}",
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              jogador.nome,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Status: Em campo",
              style: TextStyle(color: Colors.green),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _infoStat("Gols", "1"),
                _infoStat("Faltas", "2"),
                _infoStat("Cartões", "0"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoStat(String label, String valor) {
    return Column(
      children: [
        Text(
          valor,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }

  // MOSTRA DIÁLOGO DE CONFIRMAÇÃO PARA SAIR DURANTE PARTIDA
  void _mostrarDialogoSaida() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 10),
              Text(
                'Partida em Andamento',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: const Text(
            'A partida está em andamento! Para sair, você deve pausar o cronômetro primeiro.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBotaoVoltar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Permite voltar da tela se a partida estiver finalizada ou não estiver rolando
          if (_periodoAtual == PeriodoPartida.finalizada || !_rodando) {
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Não é possível sair com a partida em andamento!",
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D2D2D),
          padding: const EdgeInsets.all(16),
        ),
        child: Text(
          _periodoAtual == PeriodoPartida.finalizada
              ? "Voltar"
              : _rodando
              ? "Pause para sair"
              : "Voltar",
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_rodando, // Só permite voltar se a partida não estiver rolando
      // ignore: deprecated_member_use
      onPopInvoked: (didPop) {
        if (!didPop && _rodando) {
          _mostrarDialogoSaida();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Fundo com Gradiente
            const GradientBackground(),
            // Conteúdo Principal
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    GameScoreboard(
                      timeA: widget.partida.equipeA?.nome ?? "Time A",
                      timeB: widget.partida.equipeB?.nome ?? "Time B",
                      golsA: _golsA,
                      golsB: _golsB,
                      periodoAtual: _periodoAtual,
                      emPausaTecnica: _emPausaTecnica,
                      timeEmPausaTecnica: _timeEmPausaTecnica,
                      segundosPausaTecnica: _segundosPausaTecnica,
                      podeUsarPausaTecnica: _podeUsarPausaTecnica,
                      onPausaTecnicaIniciada: _iniciarPausaTecnica,
                      onPausaTecnicaFinalizada: _finalizarPausaTecnica,
                    ),
                    const SizedBox(height: 12),
                    GameEventsFeed(eventos: _eventosPartida),
                    const SizedBox(height: 12),
                    GameTimerCard(
                      segundos: _segundos,
                      rodando: _rodando,
                      partidaJaIniciou: _partidaJaIniciou,
                      periodoAtual: _periodoAtual,
                      emPausaTecnica: _emPausaTecnica,
                      timeEmPausaTecnica: _timeEmPausaTecnica,
                      segundosPausaTecnica: _segundosPausaTecnica,
                      segundosPausa: _segundosPausa,
                      tempoProrrogacao: _tempoProrrogacao,
                      temProrrogacao: _temProrrogacao,
                      onToggleCronometro: _alternarCronometro,
                      onFinalizarPrimeiroTempo: _finalizarPrimeiroTempo,
                      onFinalizarSegundoTempo: _finalizarSegundoTempo,
                      onAbrirModalProrrogacao: _abrirModalProrrogacao,
                    ),
                    const SizedBox(height: 16),
                    GameField(
                      jogadoresA: _jogadoresA,
                      jogadoresB: _jogadoresB,
                      jogadorSelecionado: _jogadorSelecionado,
                      onJogadorSelecionado: (jogador) {
                        setState(() => _jogadorSelecionado = jogador);
                      },
                      onJogadorDoubleTap: _abrirDetalhesJogador,
                    ),
                    const SizedBox(height: 16),
                    GameActionsPanel(
                      jogadorSelecionado: _jogadorSelecionado,
                      periodoAtual: _periodoAtual,
                      onRegistrarEvento: _registrarEvento,
                    ),
                    const SizedBox(height: 20),
                    // Botão Gerar Súmula (só aparece quando partida finalizada)
                    if (_periodoAtual == PeriodoPartida.finalizada) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // pushReplacement impede que o usuário volte para a tela de jogo
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MatchSummaryScreen(
                                  timeA:
                                      widget.partida.equipeA?.nome ?? "Time A",
                                  timeB:
                                      widget.partida.equipeB?.nome ?? "Time B",
                                  golsA: _golsA,
                                  golsB: _golsB,
                                  eventos: _eventosPartida,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.analytics),
                              SizedBox(width: 8),
                              Text(
                                'VER RESUMO DA PARTIDA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildBotaoVoltar(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- NOVO MODAL DE SUBSTITUIÇÃO REFINADO ---
  void _abrirModalSubstituicaoNovo() {
    final jogadorSaindo = _jogadorSelecionado!;
    final isTimeA = _jogadoresA.contains(jogadorSaindo);
    final reservas = isTimeA ? _reservasA : _reservasB;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Color(0xFF2D2D2D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Barra de arraste
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header do Modal
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SUBSTITUIÇÃO", // Nome do evento conforme events.txt
                        style: TextStyle(
                          color: Color(0xFF00FFC2),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        // Acessando o nome da equipe corretamente através do modelo da partida
                        isTimeA
                            ? (widget.partida.equipeA?.nome ?? "Time A")
                            : (widget.partida.equipeB?.nome ?? "Time B"),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
            ),

            // Jogador que está saindo (UI em destaque)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(15),
                // ignore: deprecated_member_use
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.logout, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Text(
                    "SAINDO:",
                    style: TextStyle(
                      // ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${jogadorSaindo.nome} (#${jogadorSaindo.numero})",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(top: 24, bottom: 12),
              child: Text(
                "SELECIONE QUEM ENTRA",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Lista de Reservas Animada
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: reservas.length,
                itemBuilder: (context, index) {
                  final reserva = reservas[index];
                  return TweenAnimationBuilder(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: _buildReservaCard(reserva, jogadorSaindo),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservaCard(JogadorFutsal reserva, JogadorFutsal saindo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _confirmarSubstituicao(saindo, reserva);
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              // ignore: deprecated_member_use
              colors: [reserva.corTime.withOpacity(0.2), Colors.white10],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: reserva.corTime,
                radius: 18,
                child: Text(
                  "${reserva.numero}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Text(
                reserva.nome,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.login, color: Color(0xFF00FFC2), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarSubstituicao(JogadorFutsal saindo, JogadorFutsal entrando) {
    setState(() {
      final isA = _jogadoresA.contains(saindo);
      final listTitulares = isA ? _jogadoresA : _jogadoresB;
      final listReservas = isA ? _reservasA : _reservasB;

      int idx = listTitulares.indexOf(saindo);
      listTitulares[idx] = JogadorFutsal(
        numero: entrando.numero,
        nome: entrando.nome,
        corTime: entrando.corTime,
        posicao: saindo.posicao,
      );

      listReservas.remove(entrando);
      listReservas.add(
        JogadorFutsal(
          numero: saindo.numero,
          nome: saindo.nome,
          corTime: saindo.corTime,
          posicao: Offset.zero,
        ),
      );

      _eventosPartida.insert(
        0,
        EventoPartida(
          tipo: 'Substituição',
          jogadorNome: '${saindo.nome} ↔ ${entrando.nome}',
          jogadorNumero: saindo.numero,
          corTime: saindo.corTime,
          horario: _formatarTempo(_segundos),
          timestamp: DateTime.now(),
        ),
      );

      // Mostrar confirmação do evento registrado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Substituição registrada: ${saindo.nome} (#${saindo.numero}) ↔ ${entrando.nome} (#${entrando.numero})",
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      _jogadorSelecionado = null;
    });
  }
}
