import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import '../api_endpoints.dart';

class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  _AvatarScreenState createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> {
  bool _isLoading = true;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  // Emotion detection
  Timer? _detectionTimer;
  List<Map<String, dynamic>> _detectedFaces = [];
  double _fps = 0;
  double _latency = 0;
  bool _isProcessing = false;
  int _frameCount = 0;
  DateTime? _lastFrameTime;

  // Emotion colors
  final Map<String, Color> _emotionColors = {
    'angry': Colors.red,
    'disgust': Colors.green.shade700,
    'fear': Colors.purple,
    'happy': Colors.yellow,
    'sad': Colors.blue,
    'surprise': Colors.orange,
    'neutral': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startAvatarStream();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras!.isEmpty) {
        throw Exception('No se encontraron cámaras');
      }

      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium, // Usar medium para mejor rendimiento
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        // Iniciar detección de emociones
        _startEmotionDetection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al inicializar la cámara: $e")),
        );
      }
    }
  }

  Future<void> _startAvatarStream() async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.startAvatar));
      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Avatar y reconocimiento facial iniciados")),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error al iniciar el avatar: ${response.statusCode}"),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error de conexión con el backend: $e")),
        );
      }
    }
  }

  void _startEmotionDetection() {
    // Enviar frames cada 200ms (5 fps)
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_isProcessing && _cameraController != null && _cameraController!.value.isInitialized) {
        _captureAndDetect();
      }
    });
  }

  Future<void> _captureAndDetect() async {
    if (_isProcessing || _cameraController == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final startTime = DateTime.now();

      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/recognition/detect-emotion-yolo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Image,
          'include_annotated': false,
        }),
      ).timeout(const Duration(seconds: 2));

      final latency = DateTime.now().difference(startTime).inMilliseconds.toDouble();

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _detectedFaces = List<Map<String, dynamic>>.from(result['faces'] ?? []);
            _latency = latency;

            // Calcular FPS
            final now = DateTime.now();
            if (_lastFrameTime != null) {
              final frameDuration = now.difference(_lastFrameTime!).inMilliseconds;
              if (frameDuration > 0) {
                _fps = 1000 / frameDuration;
              }
            }
            _lastFrameTime = now;
            _frameCount++;
          });
        }
      }
    } catch (e) {
      // Ignorar errores silenciosamente como en el script Python
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  Widget _buildEmotionOverlay() {
    if (_detectedFaces.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: EmotionPainter(
        faces: _detectedFaces,
        emotionColors: _emotionColors,
        imageSize: _cameraController!.value.previewSize!,
      ),
      child: Container(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Avatar Interactivo")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isCameraInitialized
              ? Stack(
                  children: [
                    // Vista previa de la cámara
                    SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _cameraController!.value.previewSize!.height,
                          height: _cameraController!.value.previewSize!.width,
                          child: CameraPreview(_cameraController!),
                        ),
                      ),
                    ),
                    // Overlay de emociones
                    _buildEmotionOverlay(),
                    // Métricas en la parte superior
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FPS: ${_fps.toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Latencia: ${_latency.toStringAsFixed(0)}ms',
                              style: const TextStyle(
                                color: Colors.yellow,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Caras: ${_detectedFaces.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Text("Inicializando cámara..."),
                ),
    );
  }
}

// CustomPainter para dibujar las detecciones
class EmotionPainter extends CustomPainter {
  final List<Map<String, dynamic>> faces;
  final Map<String, Color> emotionColors;
  final Size imageSize;

  EmotionPainter({
    required this.faces,
    required this.emotionColors,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calcular escala
    final scaleX = size.width / imageSize.height;
    final scaleY = size.height / imageSize.width;

    for (final face in faces) {
      final box = face['box'];
      final emotion = face['emotion'] as String;
      final confidence = face['confidence'] as double;

      // Convertir coordenadas
      final x1 = box['x1'] * scaleX;
      final y1 = box['y1'] * scaleY;
      final x2 = box['x2'] * scaleX;
      final y2 = box['y2'] * scaleY;

      final color = emotionColors[emotion] ?? Colors.white;

      // Dibujar rectángulo
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawRect(
        Rect.fromLTRB(x1, y1, x2, y2),
        paint,
      );

      // Dibujar etiqueta
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$emotion: ${(confidence * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.black54,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(x1, y1 - 25));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}