
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kyarem_eventos_publico/presentation/screens/game/partida_screen.dart';
import 'package:kyarem_eventos_publico/services/evento_service.dart';

// ── Mocks ──────────────────────────────────────────────────────────────
class MockEventoService extends Mock implements EventoService {}

/// A JogoDetalhesScreen usa streams real-time do Supabase no initState,
/// o que torna o mock complexo. Testamos apenas o construtor estático
/// passando `enableFirebaseMessaging: false` para evitar crash do Firebase.
///
/// Para testes que requerem Supabase streams, seria necessário um FakeSupabaseClient
/// ou um integration test com ambiente Supabase local.
void main() {
  group('Testes da Tela de Detalhes do Jogo (JogoDetalhesScreen)', () {
    // Nota: Esta tela depende diretamente de SupabaseClient streams no initState.
    // Sem um FakeSupabaseClient que possa emitir streams mockados, os widget tests
    // ficam restritos a verificar os parâmetros/construtor.
    //
    // Os testes de integração para esta tela devem ser feitos com um Supabase local
    // ou com Flutter Integration Test.

    test('Construtor aceita todos os parâmetros opcionais de DI', () {
      // Verifica que o construtor compila com DI params
      final widget = JogoDetalhesScreen(
        partidaId: '1',
        modalidadeId: 'm1',
        timeA: 'Time A',
        timeB: 'Time B',
        placarA: '0',
        placarB: '0',
        status: 'AO VIVO',
        enableFirebaseMessaging: false,
        eventoService: MockEventoService(),
      );

      expect(widget.partidaId, '1');
      expect(widget.timeA, 'Time A');
      expect(widget.timeB, 'Time B');
      expect(widget.enableFirebaseMessaging, false);
    });
  });
}
