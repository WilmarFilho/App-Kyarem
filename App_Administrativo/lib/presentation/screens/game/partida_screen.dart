import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kyarem_eventos/presentation/screens/game/resumo_partida_screen.dart';

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
      case 'Gol':
        return 'Gol de #$jogadorNumero';
      case 'Cartão Amarelo':
        return 'Cartão Amarelo #$jogadorNumero';
      case 'Cartão Vermelho':
        return 'Cartão Vermelho #$jogadorNumero';
      case 'Falta':
        return 'Falta #$jogadorNumero';
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
  final String timeA;
  final String timeB;

  const PartidaRunningScreen({
    super.key,
    this.timeA = "COMPUTARIA",
    this.timeB = "FISIOTERAPIA",
  });

  @override
  State<PartidaRunningScreen> createState() => _PartidaRunningScreenState();
}

class _PartidaRunningScreenState extends State<PartidaRunningScreen> {
  // Constantes de tempo da partida (em segundos) - fácil configuração
  static const int DURACAO_PRIMEIRO_TEMPO = 20 * 60; // 20 minutos
  static const int DURACAO_SEGUNDO_TEMPO = 20 * 60;  // 20 minutos
  
  int _golsA = 0;
  int _golsB = 0;
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
      posicao: const Offset(0.89, 0.45),
    ),
    JogadorFutsal(
      numero: 4,
      nome: "Fixo B",
      corTime: Colors.blue,
      posicao: const Offset(0.75, 0.45),
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
        if (_segundos >= DURACAO_PRIMEIRO_TEMPO) {
          if (_temProrrogacao && !_estaNaProrrogacao) {
            // Iniciar prorrogação do primeiro tempo
            _iniciarProrrogacao("Prorrogação do 1º Tempo");
          } else {
            _finalizarPrimeiroTempo();
          }
        }
        break;
      case PeriodoPartida.segundoTempo:
        if (_segundos >= DURACAO_SEGUNDO_TEMPO) {
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
    final TextEditingController _controller = TextEditingController();
    
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
              controller: _controller,
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
              final String input = _controller.text.trim();
              final int? minutos = int.tryParse(input);
              
              if (minutos == null || minutos <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, digite um número válido de minutos!'),
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
                  content: Text('Prorrogação de $minutos minutos configurada com sucesso!'),
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
          content: Text("${isTimeA ? widget.timeA : widget.timeB} já usou sua pausa técnica neste período!"),
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
      _timeEmPausaTecnica = isTimeA ? widget.timeA : widget.timeB;
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
      setState(() {
        _segundosPausaTecnica++;
        // Finalizar automaticamente após 60 segundos
        if (_segundosPausaTecnica >= 60) {
          _finalizarPausaTecnica();
        }
      });
    });
    
    // Registrar evento de pausa técnica
    _registrarEventoOficial('Pausa Técnica - $_timeEmPausaTecnica');
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
        // Lógica para iniciar baseado no período atual
        switch (_periodoAtual) {
          case PeriodoPartida.naoIniciada:
            // Primeira vez - inicia primeiro tempo
            _periodoAtual = PeriodoPartida.primeiroTempo;
            _segundos = 0; // Reset do cronômetro
            _registrarEventoOficial('Início do 1º Tempo');
            break;
            
          case PeriodoPartida.intervalo:
            // Saindo do intervalo - inicia segundo tempo
            _periodoAtual = PeriodoPartida.segundoTempo;
            _segundos = 0; // Reset do cronômetro para o 2º tempo
            _registrarEventoOficial('Início do 2º Tempo');
            break;
            
          case PeriodoPartida.prorrogacao:
            // Continuando na prorrogação após pausa
            if (_partidaJaIniciou) {
              _registrarEventoPausa('Pausa Finalizada');
            }
            // Retomando de uma pausa durante o tempo
            if (_partidaJaIniciou) {
              _registrarEventoPausa('Pausa Finalizada');
            }
            break;
            
          case PeriodoPartida.finalizada:
            // Partida já finalizada, não pode reiniciar
            _rodando = false;
            return;
            
          default:
            break;
        }
        
        // Iniciar cronômetro da partida
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _segundos++;
            _verificarFimPeriodo(); // Verificar se deve finalizar automaticamente
          });
        });
        
        // Parar cronômetro de pausa
        _timerPausa?.cancel();
        _partidaJaIniciou = true;
        
      } else {
        // Pausar cronômetro da partida
        _timer?.cancel();
        
        // Só inicia cronometro de pausa se não estiver finalizada e não estiver em pausa técnica
        if (_periodoAtual != PeriodoPartida.finalizada && !_emPausaTecnica) {
          // Iniciar cronômetro de pausa
          _timerPausa = Timer.periodic(const Duration(seconds: 1), (timer) {
            setState(() => _segundosPausa++);
          });
          
          // Registrar evento de pausa iniciada (se já iniciou antes)
          if (_partidaJaIniciou) {
            _registrarEventoPausa('Pausa Iniciada');
          }
        }
      }
    });
  }

  void _registrarEvento(String tipo) {
    // Verificar se é permitido registrar eventos no estado atual da partida
    if (_periodoAtual == PeriodoPartida.naoIniciada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Não é possível registrar eventos antes de iniciar a partida!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_periodoAtual == PeriodoPartida.finalizada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Não é possível registrar eventos com a partida encerrada!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_periodoAtual == PeriodoPartida.intervalo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Não é possível registrar eventos durante o intervalo!"),
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
        if (isTimeA)
          _golsA++;
        else
          _golsB++;
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
    // TODO: Implementar salvamento no banco
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

  Widget _formatarTempoPausa() {
    int min = _segundosPausa ~/ 60;
    int seg = _segundosPausa % 60;
    return Text(
      '${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')} (Pausa em andamento)',
      style: TextStyle(
        color: _rodando ? Colors.white60 : Colors.orange,
        fontSize: 10,
        fontWeight: _rodando ? FontWeight.normal : FontWeight.bold,
      ),
    );
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
                content: Text("Não é possível sair com a partida em andamento!"),
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
      onPopInvoked: (didPop) {
        if (!didPop && _rodando) {
          _mostrarDialogoSaida();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(
          0xFFF0FFF4,
        ), // Fundo levemente esverdeado do design
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildPlacar(),
                const SizedBox(height: 12),
                _buildFeedEventos(),
                const SizedBox(height: 12),
                _buildCronometroCard(),
                const SizedBox(height: 16),
                _buildCampoFutsal(),
                const SizedBox(height: 16),
                _buildPainelAcoes(),
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
                              timeA: widget.timeA,
                              timeB: widget.timeB,
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
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      ),
    );
  }

  // 1. PLACAR
  Widget _buildPlacar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTimePlacar(widget.timeA, Icons.laptop, _golsA),
          Container(width: 2, height: 80, color: Colors.grey[200]),
          _buildTimePlacar(widget.timeB, Icons.add_moderator, _golsB),
        ],
      ),
    );
  }

  Widget _buildTimePlacar(String nome, IconData icon, int gols) {
    bool isTimeA = nome == widget.timeA;
    bool podeUsarPausaTecnica = _podeUsarPausaTecnica(isTimeA) && 
                               (_periodoAtual == PeriodoPartida.primeiroTempo || 
                                _periodoAtual == PeriodoPartida.segundoTempo ||
                                _periodoAtual == PeriodoPartida.prorrogacao);
                                
    return Column(
      children: [
        Text(
          nome,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Icon(icon, size: 30),
        const SizedBox(height: 8),
        Text(
          gols.toString().padLeft(2, '0'),
          style: const TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF5733),
          ),
        ),
        const SizedBox(height: 8),
        // Botão de pausa técnica
        if (podeUsarPausaTecnica && !_emPausaTecnica)
          GestureDetector(
            onTap: () => _iniciarPausaTecnica(isTimeA),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Pausa Técnica',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        // Se está em pausa técnica e é o time em pausa, mostra botão para finalizar
        else if (_emPausaTecnica && _timeEmPausaTecnica == nome)
          GestureDetector(
            onTap: _finalizarPausaTecnica,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Finalizar (${60 - _segundosPausaTecnica}s)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        // Se já usou pausa técnica, mostra indicador
        else if (!podeUsarPausaTecnica && (_periodoAtual == PeriodoPartida.primeiroTempo || 
                                          _periodoAtual == PeriodoPartida.segundoTempo ||
                                          _periodoAtual == PeriodoPartida.prorrogacao))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Pausa Usada',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          const SizedBox(height: 20), // Espaço para manter altura consistente
      ],
    );
  }

  // 2. FEED DE EVENTOS (SCROLL HORIZONTAL)
  Widget _buildFeedEventos() {
    return SizedBox(
      height: 40,
      child: _eventosPartida.isEmpty
          ? const Center(
              child: Text(
                "Aguardando lances...",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _eventosPartida.length,
              itemBuilder: (context, index) =>
                  _eventoItem(_eventosPartida[index]),
            ),
    );
  }

  Widget _eventoItem(EventoPartida ev) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: ev.corTime, radius: 4),
          const SizedBox(width: 8),
          Text(
            "${ev.descricao} - ${ev.horario}",
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // 3. CRONÔMETRO E BOTÕES DE TEMPO
  Widget _buildCronometroCard() {
    // Se a partida estiver finalizada, mostra apenas mensagem
    if (_periodoAtual == PeriodoPartida.finalizada) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(
                Icons.sports_soccer,
                color: Colors.green,
                size: 60,
              ),
              SizedBox(height: 16),
              Text(
                'PARTIDA ENCERRADA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Interface normal durante a partida
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Column(
            children: [
              IconButton(
                onPressed: _alternarCronometro,
                icon: Icon(
                  _rodando ? Icons.pause_circle : Icons.play_circle,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _formatarTempo(_segundos),
                  style: const TextStyle(
                    color: Color(0xFFD4FFD4),
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Mostra o período atual e prorrogação configurada (não durante intervalo)
                if (_periodoAtual == PeriodoPartida.prorrogacao)
                  Text(
                    'PRORROGAÇÃO (${_tempoProrrogacao ~/ 60}min)',
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (_temProrrogacao && _periodoAtual != PeriodoPartida.intervalo)
                  Text(
                    'Prorrogação: ${_tempoProrrogacao ~/ 60}min configurada',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                // Mostra tempo de pausa se estiver pausado durante jogo, pausa técnica, ou "INTERVALO" se estiver no intervalo
                if (!_rodando && _partidaJaIniciou)
                  _emPausaTecnica
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'PAUSA TÉCNICA\n$_timeEmPausaTecnica (${60 - _segundosPausaTecnica}s)',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : _periodoAtual == PeriodoPartida.intervalo
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'INTERVALO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : _formatarTempoPausa()
                else
                  const SizedBox(height: 14), // Espaço para manter altura
              ],
            ),
          ),
          Column(
            children: [
              // Botão "Fim 1º tempo" só aparece durante o primeiro tempo e não em pausa técnica
              if (_periodoAtual == PeriodoPartida.primeiroTempo && !_emPausaTecnica)
                _btnTempo("Fim 1º tempo", () => _finalizarPrimeiroTempo()),
              if (_periodoAtual == PeriodoPartida.primeiroTempo && !_emPausaTecnica)
                const SizedBox(height: 4),
              
              // Botão "Fim 2º tempo" só aparece durante o segundo tempo e não em pausa técnica
              if (_periodoAtual == PeriodoPartida.segundoTempo && !_emPausaTecnica)
                _btnTempo("Fim 2º tempo", () => _finalizarSegundoTempo()),
              if (_periodoAtual == PeriodoPartida.segundoTempo && !_emPausaTecnica)
                const SizedBox(height: 4),
              
              // Botão de prorrogação só aparece durante primeiro ou segundo tempo e não em pausa técnica
              if ((_periodoAtual == PeriodoPartida.primeiroTempo || _periodoAtual == PeriodoPartida.segundoTempo) && !_emPausaTecnica)
                _btnTempo(
                  _temProrrogacao 
                    ? "Prr: ${_tempoProrrogacao ~/ 60}min" 
                    : "Dar Prorrogação", 
                  () => _abrirModalProrrogacao()
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btnTempo(String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 2,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10, 
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  // 4. CAMPO DE JOGO
  Widget _buildCampoFutsal() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double campoWidth = constraints.maxWidth;
        final double campoHeight = 250;

        return Container(
          height: campoHeight,
          width: campoWidth,
          decoration: BoxDecoration(
            color: const Color(0xFF8DBA94),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
          ),
          child: Stack(
            children: [
              // Linhas do campo
              Center(child: Container(width: 2, color: Colors.white54)),
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white54, width: 2),
                  ),
                ),
              ),

              // Renderiza todos os jogadores
              ...[
                ..._jogadoresA,
                ..._jogadoresB,
              ].map((jog) => _buildWidgetJogador(jog, campoWidth, campoHeight)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWidgetJogador(JogadorFutsal jog, double w, double h) {
    bool sel = _jogadorSelecionado == jog;
    return Positioned(
      left: jog.posicao.dx * w,
      top: jog.posicao.dy * h,
      child: GestureDetector(
        onTap: () => setState(() => _jogadorSelecionado = jog),
        onDoubleTap: () => _abrirDetalhesJogador(jog),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(sel ? 4 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: sel ? Border.all(color: Colors.white, width: 2) : null,
              ),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: jog.corTime,
                child: Text(
                  "${jog.numero}",
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Text(
              jog.nome.split(' ')[0],
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // 5. PAINEL DE AÇÕES (BOTÕES COLORIDOS)
  Widget _buildPainelAcoes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _btnAcaoFull(
            "Gol",
            const Color(0xFF00FFC2),
            Colors.black,
            onTap: () => _registrarEvento("Gol"),
          ),
          const SizedBox(height: 8),
          _btnAcaoFull(
            "Substituição",
            Colors.white,
            Colors.black,
            onTap: () => _registrarEvento("Substituição"),
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Cartões",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          _btnAcaoFull(
            "Falta",
            const Color(0xFFFF3D00),
            Colors.white,
            onTap: () => _registrarEvento("Falta"),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _btnAcaoFull(
                  "Cartão Amarelo",
                  Colors.yellow,
                  Colors.black,
                  onTap: () => _registrarEvento("Cartão Amarelo"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _btnAcaoFull(
                  "Cartão Vermelho",
                  const Color(0xFFD32F2F),
                  Colors.white,
                  onTap: () => _registrarEvento("Cartão Vermelho"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Saídas",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          
          // --- INÍCIO DO GRID DE SAÍDAS AJUSTADO ---
          // Linha 1: Tiro de Saída e Tiro Livre Direto
          Row(
            children: [
              Expanded(child: _btnSaida("Tiro de saída", onTap: () => _registrarEvento("Tiro de Saída"))),
              const SizedBox(width: 8),
              Expanded(child: _btnSaida("Tiro livre direto", onTap: () => _registrarEvento("Tiro Livre Direto"))),
            ],
          ),
          const SizedBox(height: 8),
          
          // Linha 2: Tiro Livre Indireto e Tiro Lateral
          Row(
            children: [
              Expanded(child: _buildBtnSaidaAjustado("Tiro livre indireto", () => _registrarEvento("Tiro Livre Indireto"))),
              const SizedBox(width: 8),
              Expanded(child: _btnSaida("Tiro Lateral", onTap: () => _registrarEvento("Tiro Lateral"))),
            ],
          ),
          const SizedBox(height: 8),
          
          // Linha 3: Tiro de Canto e Arremesso de Meta
          Row(
            children: [
              Expanded(child: _btnSaida("Tiro de Canto", onTap: () => _registrarEvento("Tiro de Canto"))),
              const SizedBox(width: 8),
              Expanded(child: _btnSaida("Arremesso de Meta", onTap: () => _registrarEvento("Arremesso de Meta"))),
            ],
          ),
          // --- FIM DO GRID DE SAÍDAS ---
        ],
      ),
    );
  }

// Pequeno Helper para garantir que o texto não quebre o layout se for muito longo
Widget _buildBtnSaidaAjustado(String texto, VoidCallback acao) {
  return _btnSaida(
    texto,
    onTap: acao,
  );
}

  Widget _btnAcaoFull(
    String label,
    Color fundo,
    Color texto, {
    VoidCallback? onTap,
  }) {
    bool isEnabled = _jogadorSelecionado != null;
    Color backgroundColor = isEnabled ? fundo : Colors.grey[400]!;
    Color textColor = isEnabled ? texto : Colors.grey[600]!;

    return GestureDetector(
      onTap: isEnabled && onTap != null ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: isEnabled
              ? null
              : Border.all(color: Colors.grey[300]!, width: 1),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isEnabled) Icon(Icons.person_off, color: textColor, size: 16),
            if (!isEnabled) const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: isEnabled ? 14 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btnSaida(String label, {VoidCallback? onTap}) {
    bool isEnabled = _jogadorSelecionado != null;
    Color backgroundColor = isEnabled ? Colors.white : Colors.grey[300]!;
    Color textColor = isEnabled ? Colors.black : Colors.grey[600]!;

    return GestureDetector(
      onTap: isEnabled && onTap != null ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled ? Colors.grey[400]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: textColor,
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
                        "SUBSTITUIÇÃO",
                        style: TextStyle(
                          color: Color(0xFF00FFC2),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        isTimeA ? widget.timeA : widget.timeB,
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
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.logout, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Text(
                    "SAINDO:",
                    style: TextStyle(
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
