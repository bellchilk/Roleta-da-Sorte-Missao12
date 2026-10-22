import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'services/ble_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RoletaApp());
}

class RoletaApp extends StatelessWidget {
  const RoletaApp({super.key});

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF087F8C);
    return MaterialApp(
      title: 'Roleta da Sorte',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: teal),
        scaffoldBackgroundColor: const Color(0xFFF5F8FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: teal,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: const RoletaHomePage(),
    );
  }
}

class ChallengeCategory {
  const ChallengeCategory({
    required this.name,
    required this.color,
    required this.textColor,
    required this.challenges,
  });

  final String name;
  final Color color;
  final Color textColor;
  final List<String> challenges;
}

const categories = <ChallengeCategory>[
  ChallengeCategory(
    name: 'Roxo escuro',
    color: Color(0xFF56318A),
    textColor: Colors.white,
    challenges: [
      'Invente um robô que ajude nas tarefas de casa.',
      'Faça uma pose de robô por 10 segundos.',
      'Desenhe no ar um robô com três poderes.',
      'Conte uma história curta sobre um robô perdido.',
      'Imite o jeito de andar de um robô.',
    ],
  ),
  ChallengeCategory(
    name: 'Roxo claro',
    color: Color(0xFFB59AD7),
    textColor: Color(0xFF241638),
    challenges: [
      'Diga três coisas que um robô pode fazer.',
      'Mostre como um robô andaria pela sala.',
      'Crie um nome divertido para um robô.',
      'Faça uma sequência de três movimentos robóticos.',
      'Explique como um robô poderia ajudar uma pessoa.',
    ],
  ),
  ChallengeCategory(
    name: 'Azul',
    color: Color(0xFF2386D1),
    textColor: Colors.white,
    challenges: [
      'Imagine um robô explorador do fundo do mar.',
      'Faça um gesto de decolagem de um robô.',
      'Mostre como se move um braço robótico.',
      'Encontre algo azul perto de você.',
      'Diga uma tarefa que um robô poderia fazer na água.',
    ],
  ),
  ChallengeCategory(
    name: 'Verde',
    color: Color(0xFF329B62),
    textColor: Colors.white,
    challenges: [
      'Imagine um robô que cuida de plantas.',
      'Dê cinco passos como um robô.',
      'Encontre algo verde no ambiente.',
      'Crie um gesto para recarregar a energia do robô.',
      'Conte como um robô poderia ajudar a natureza.',
    ],
  ),
  ChallengeCategory(
    name: 'Amarelo A',
    color: Color(0xFFF6C445),
    textColor: Color(0xFF342800),
    challenges: [
      'Imagine um robô que funciona com energia solar.',
      'Faça uma pose de robô superbrilhante.',
      'Diga duas fontes de energia.',
      'Crie um sinal para ligar um robô imaginário.',
      'Conte uma missão que um robô faria no espaço.',
    ],
  ),
  ChallengeCategory(
    name: 'Laranja',
    color: Color(0xFFF28C28),
    textColor: Color(0xFF3D2100),
    challenges: [
      'Imite um robô que está com muita pressa.',
      'Desenhe uma engrenagem no ar com o dedo.',
      'Invente um acessório para um robô.',
      'Faça quatro movimentos mecânicos diferentes.',
      'Dê um nome engraçado para um robô.',
    ],
  ),
  ChallengeCategory(
    name: 'Amarelo B',
    color: Color(0xFFFFE08A),
    textColor: Color(0xFF342800),
    challenges: [
      'Crie a ideia de um robô ajudante da escola.',
      'Mostre como um robô carregaria uma caixa.',
      'Pense em uma forma de organizar brinquedos usando um robô.',
      'Diga um comando que um robô poderia entender.',
      'Faça uma pequena dança robótica.',
    ],
  ),
  ChallengeCategory(
    name: 'Vermelho',
    color: Color(0xFFE34C4C),
    textColor: Colors.white,
    challenges: [
      'Imagine um robô que ajuda os bombeiros.',
      'Faça uma expressão de robô surpreso.',
      'Diga como um robô poderia ajudar em uma emergência.',
      'Crie um gesto de alerta para um robô.',
      'Invente um superpoder para um robô de resgate.',
    ],
  ),
];

class RoletaHomePage extends StatefulWidget {
  const RoletaHomePage({super.key});

  @override
  State<RoletaHomePage> createState() => _RoletaHomePageState();
}

class _RoletaHomePageState extends State<RoletaHomePage> {
  final _random = Random();
  final _ble = BleService();

  ChallengeCategory? _selectedCategory;
  String? _challenge;
  Timer? _timer;
  int _secondsLeft = 20;
  bool _isRunning = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  String _bleMessage = 'ESP32 desconectado';

  Future<void> _requestBluetoothPermissions() async {
    // O Android 12+ usa permissões específicas de Bluetooth.
    // A localização é solicitada para compatibilidade com Android antigo.
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.locationWhenInUse.request();
  }

  Future<void> _connectEsp32() async {
    if (_isConnecting) return;
    setState(() {
      _isConnecting = true;
      _bleMessage = 'Procurando o ESP32...';
    });

    try {
      await _requestBluetoothPermissions();
      await _ble.connect();
      if (!mounted) return;
      setState(() {
        _isConnected = true;
        _bleMessage = 'ESP32 conectado';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isConnected = false;
        _bleMessage = 'Não foi possível conectar. Verifique o ESP32 e tente novamente.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha na conexão BLE: $error')),
      );
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  void _drawChallenge(ChallengeCategory category) {
    _timer?.cancel();
    setState(() {
      _selectedCategory = category;
      final options = category.challenges;
      _challenge = options[_random.nextInt(options.length)];
      _secondsLeft = 20;
      _isRunning = false;
    });
  }

  Future<void> _startChallenge() async {
    if (_challenge == null || _isRunning) return;
    setState(() {
      _secondsLeft = 20;
      _isRunning = true;
    });

    try {
      await _ble.sendCommand('START');
    } catch (_) {
      if (mounted) {
        setState(() {
          _bleMessage = 'Desafio iniciado sem LED (ESP32 não conectado)';
        });
      }
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
          _isRunning = false;
        });
        _ble.sendCommand('STOP').catchError((_) {});
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _finishChallenge() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsLeft = 0;
    });
    try {
      await _ble.sendCommand('STOP');
    } catch (_) {
      // O cronômetro continua funcionando mesmo sem o ESP32 conectado.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ble.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final seconds = _secondsLeft.toString().padLeft(2, '0');
    return '00:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roleta da Sorte'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'MISSÃO 12',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gire, escolha e desafie-se!',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Gire a roleta física e toque na cor em que ela parou.',
                style: TextStyle(fontSize: 15, color: Color(0xFF5E6A71)),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _isConnected
                              ? const Color(0xFFDDF5E7)
                              : const Color(0xFFFFE9D6),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          _isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                          color: _isConnected
                              ? const Color(0xFF21864A)
                              : const Color(0xFFB75B18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _bleMessage,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'O LED acende durante o desafio.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF66737A)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isConnecting)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton.filledTonal(
                          tooltip: 'Conectar ao ESP32',
                          onPressed: _isConnected ? null : _connectEsp32,
                          icon: const Icon(Icons.bluetooth_searching),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '1. Escolha a cor da roleta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.15,
                ),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _selectedCategory?.name == category.name;
                  return Material(
                    color: category.color,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isRunning ? null : () => _drawChallenge(category),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF087F8C) : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 14, color: category.textColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                category.name,
                                style: TextStyle(
                                  color: category.textColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle, color: category.textColor, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                '2. Faça o desafio sorteado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_selectedCategory == null) ...[
                        const Icon(Icons.casino_outlined, size: 42, color: Color(0xFF087F8C)),
                        const SizedBox(height: 10),
                        const Text(
                          'Escolha uma das oito cores para sortear um desafio.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15),
                        ),
                      ] else ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _selectedCategory!.color.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _selectedCategory!.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _challenge ?? '',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF5F6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _formattedTime,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF087F8C),
                                ),
                              ),
                              Text(
                                _isRunning
                                    ? 'Valendo! Complete o desafio.'
                                    : _secondsLeft == 0
                                        ? 'Tempo encerrado!'
                                        : 'Você terá 20 segundos.',
                                style: const TextStyle(color: Color(0xFF50636A)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_isRunning)
                          ElevatedButton.icon(
                            onPressed: _finishChallenge,
                            icon: const Icon(Icons.stop_circle_outlined),
                            label: const Text('Concluir desafio'),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _startChallenge,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Iniciar desafio'),
                          ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _isRunning
                              ? null
                              : () => _drawChallenge(_selectedCategory!),
                          icon: const Icon(Icons.shuffle),
                          label: const Text('Sortear outro desafio'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'ClubRobot • Aprender brincando com tecnologia',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF6C7A80)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
