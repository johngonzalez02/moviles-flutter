import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taller 2 - Flutter Async',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HomePage(),
    );
  }
}

void tareaPesadaIsolate(SendPort sendPort) {
  int suma = 0;
  for (int i = 0; i < 1500000000; i++) {
    suma += i;
  }
  sendPort.send(suma);
}

enum FutureStatus { idle, loading, success, error }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ---------------------- SECCION 1: Future / async-await ----------------
  FutureStatus _futureStatus = FutureStatus.idle;
  String _futureResultado = '';
  bool _simularError = false;

  Future<String> _consultarServicioSimulado() async {
    print('[Future] DURANTE: consultando servicio simulado (2-3 s)...');
    await Future.delayed(const Duration(seconds: 3));
    if (_simularError) {
      throw Exception('Fallo simulado al consultar el servicio');
    }
    return 'Datos recibidos correctamente desde el servicio simulado';
  }

  Future<void> _cargarDatos() async {
    print('[Future] ANTES: inicia la consulta de datos');
    setState(() {
      _futureStatus = FutureStatus.loading;
    });

    try {
      final resultado = await _consultarServicioSimulado();
      setState(() {
        _futureStatus = FutureStatus.success;
        _futureResultado = resultado;
      });
      print('[Future] DESPUES: exito -> $resultado');
    } catch (e) {
      setState(() {
        _futureStatus = FutureStatus.error;
        _futureResultado = e.toString();
      });
      print('[Future] DESPUES: error -> $e');
    }
  }

  // ---------------------- SECCION 2: Timer (cronometro) ------------------
  Timer? _timer;
  int _milisegundos = 0;
  bool _timerCorriendo = false;

  void _iniciarTimer() {
    if (_timerCorriendo) return;
    print('[Timer] Iniciando cronometro');
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _milisegundos += 100;
      });
    });
    setState(() {
      _timerCorriendo = true;
    });
  }

  void _pausarTimer() {
    print('[Timer] Pausando cronometro');
    _timer?.cancel();
    setState(() {
      _timerCorriendo = false;
    });
  }

  void _reanudarTimer() {
    print('[Timer] Reanudando cronometro');
    _iniciarTimer();
  }

  void _reiniciarTimer() {
    print('[Timer] Reiniciando cronometro');
    _timer?.cancel();
    setState(() {
      _milisegundos = 0;
      _timerCorriendo = false;
    });
  }

  String get _tiempoFormateado {
    final totalMs = _milisegundos;
    final minutos = (totalMs ~/ 60000).toString().padLeft(2, '0');
    final segundos = ((totalMs % 60000) ~/ 1000).toString().padLeft(2, '0');
    final decimas = ((totalMs % 1000) ~/ 100).toString();
    return '$minutos:$segundos.$decimas';
  }

  // ---------------------- SECCION 3: Isolate (tarea pesada) --------------
  bool _isolateCargando = false;
  String _isolateResultado = '';
  int _isolateTiempoMs = 0;

  Future<void> _ejecutarTareaPesada() async {
    print('[Isolate] Iniciando tarea pesada en un Isolate...');
    setState(() {
      _isolateCargando = true;
      _isolateResultado = '';
    });

    final stopwatch = Stopwatch()..start();
    final receivePort = ReceivePort();

    await Isolate.spawn(tareaPesadaIsolate, receivePort.sendPort);
    final resultado = await receivePort.first;

    stopwatch.stop();
    print('[Isolate] Tarea finalizada. Resultado=$resultado '
        'Tiempo=${stopwatch.elapsedMilliseconds} ms');

    setState(() {
      _isolateCargando = false;
      _isolateResultado = resultado.toString();
      _isolateTiempoMs = stopwatch.elapsedMilliseconds;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taller 2 - Async / Timer / Isolate'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSeccionFuture(),
            const SizedBox(height: 24),
            _buildSeccionTimer(),
            const SizedBox(height: 24),
            _buildSeccionIsolate(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ---------------------- UI: Seccion Future ------------------------------
  Widget _buildSeccionFuture() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. Future / async / await',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'Simula una consulta a un servicio remoto usando '
                'Future.delayed (3 s) sin bloquear la interfaz.'),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Simular error:'),
                Switch(
                  value: _simularError,
                  onChanged: (value) {
                    setState(() {
                      _simularError = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _futureStatus == FutureStatus.loading
                  ? null
                  : _cargarDatos,
              icon: const Icon(Icons.cloud_download),
              label: const Text('Consultar datos'),
            ),
            const SizedBox(height: 16),
            _buildEstadoFuture(),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoFuture() {
    switch (_futureStatus) {
      case FutureStatus.idle:
        return const Text('Presiona el boton para consultar los datos.');
      case FutureStatus.loading:
        return const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Cargando...'),
          ],
        );
      case FutureStatus.success:
        return Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_futureResultado,
                  style: const TextStyle(color: Colors.green)),
            ),
          ],
        );
      case FutureStatus.error:
        return Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_futureResultado,
                  style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
    }
  }

  // ---------------------- UI: Seccion Timer -------------------------------
  Widget _buildSeccionTimer() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('2. Timer - Cronometro',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Cronometro controlado con Timer.periodic.'),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _tiempoFormateado,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _timerCorriendo ? null : _iniciarTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar'),
                ),
                ElevatedButton.icon(
                  onPressed: _timerCorriendo ? _pausarTimer : null,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pausar'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      (!_timerCorriendo && _milisegundos > 0)
                          ? _reanudarTimer
                          : null,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Reanudar'),
                ),
                TextButton.icon(
                  onPressed: _reiniciarTimer,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reiniciar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------- UI: Seccion Isolate -----------------------------
  Widget _buildSeccionIsolate() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('3. Isolate - Tarea pesada',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'Ejecuta una suma de 1.500 millones de numeros en un '
                'Isolate aparte. Observa que el cronometro de arriba '
                'sigue corriendo: la UI no se bloquea.'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isolateCargando ? null : _ejecutarTareaPesada,
              icon: const Icon(Icons.memory),
              label: const Text('Ejecutar tarea pesada'),
            ),
            const SizedBox(height: 16),
            if (_isolateCargando)
              const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Procesando en segundo plano...'),
                ],
              )
            else if (_isolateResultado.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resultado: $_isolateResultado'),
                  const SizedBox(height: 4),
                  Text('Tiempo de ejecucion: $_isolateTiempoMs ms'),
                ],
              )
            else
              const Text('Aun no se ha ejecutado la tarea.'),
          ],
        ),
      ),
    );
  }
}