import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/progress_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ProgressService _progressService = ProgressService();

  String? _userId;
  bool _loading = true;
  bool _error = false;
  String? _errorMessage;

  int _positiva = 0;
  int _negativa = 0;
  int _neutra = 0;

  Map<String, int> _ferCounts = {
    "happy": 0,
    "sad": 0,
    "angry": 0,
    "fear": 0,
    "surprise": 0,
    "neutral": 0,
  };

  // Colores de la marca
  final Color _primaryColor = const Color(0xFF6A11CB);
  final Color _secondaryColor = const Color(0xFF2575FC);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _userId = authProvider.firebaseUser?.uid;

    if (_userId == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
          _errorMessage = 'No hay usuario autenticado';
        });
      }
      return;
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    if (_userId == null) return;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = false;
        _errorMessage = null;
      });
    }

    try {
      final statistics = await _progressService
          .getProgressStatistics(userId: _userId!)
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('La carga de datos tardó demasiado');
        },
      );

      final conversations = statistics['conversations'] as Map<String, dynamic>?;
      if (conversations != null) {
        _positiva = conversations['positiva'] as int? ?? 0;
        _negativa = conversations['negativa'] as int? ?? 0;
        _neutra = conversations['neutra'] as int? ?? 0;
      }

      final facialEmotions = statistics['facial_emotions'] as Map<String, dynamic>?;
      if (facialEmotions != null) {
        _ferCounts = {
          'happy': facialEmotions['happy'] as int? ?? 0,
          'sad': facialEmotions['sad'] as int? ?? 0,
          'angry': facialEmotions['angry'] as int? ?? 0,
          'fear': facialEmotions['fear'] as int? ?? 0,
          'surprise': facialEmotions['surprise'] as int? ?? 0,
          'neutral': facialEmotions['neutral'] as int? ?? 0,
        };
      }

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _loading = false;
          _errorMessage = e is TimeoutException 
              ? 'Tiempo de espera agotado.' 
              : 'Error al cargar datos.';
        });
      }
    }
  }

  // --- WIDGETS UI ---

  // Gráfico de Dona (Radial Porcentual)
  Widget _buildDonutChart() {
    final total = _positiva + _negativa + _neutra;
    if (total == 0) return const Center(child: Text("Sin datos"));

    // Calculamos porcentaje de positividad para mostrar en el centro
    final double positivePercentage = (_positiva / total) * 100;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 60, // Espacio central para hacerlo dona
              startDegreeOffset: -90,
              sections: [
                _buildPieSection(_positiva.toDouble(), Colors.greenAccent, "Pos"),
                _buildPieSection(_negativa.toDouble(), Colors.redAccent, "Neg"),
                _buildPieSection(_neutra.toDouble(), Colors.grey.shade300, "Neu"),
              ],
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${positivePercentage.toStringAsFixed(0)}%",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const Text(
              "Positividad",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        )
      ],
    );
  }

  PieChartSectionData _buildPieSection(double value, Color color, String title) {
    return PieChartSectionData(
      value: value,
      title: title,
      color: color,
      radius: 25, // Grosor del anillo
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  // Gráfico de Barras Estilizado
  Widget _buildBarChart() {
    final total = _ferCounts.values.reduce((a, b) => a + b);
    if (total == 0) return const Center(child: Text("Sin datos faciales"));

    final emotions = _ferCounts.keys.toList();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false), // Ocultar grilla para limpieza
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= emotions.length) return Container();
                  // Mapeo de nombres a emojis o cortos
                  final label = _getEmojiForEmotion(emotions[i]);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(label, style: const TextStyle(fontSize: 14)),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(
            emotions.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: _ferCounts[emotions[i]]!.toDouble(),
                  gradient: LinearGradient(
                    colors: [_primaryColor.withOpacity(0.7), _secondaryColor],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: _getMaxValue().toDouble(), // Fondo gris hasta el tope
                    color: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getMaxValue() {
    int max = 0;
    _ferCounts.forEach((k, v) {
      if (v > max) max = v;
    });
    return max == 0 ? 10 : max;
  }

  String _getEmojiForEmotion(String emotion) {
    switch (emotion) {
      case 'happy': return '😄';
      case 'sad': return '😢';
      case 'angry': return '😠';
      case 'fear': return '😨';
      case 'surprise': return '😲';
      case 'neutral': return '😐';
      default: return '?';
    }
  }

  Widget _buildBentoCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildAnalysisCard() {
    final convTotal = _positiva + _negativa + _neutra;
    if (convTotal == 0) return const SizedBox.shrink();

    String tendencia = "Neutro";
    if (_positiva > _negativa && _positiva > _neutra) tendencia = "Positivo";
    else if (_negativa > _positiva && _negativa > _neutra) tendencia = "Negativo";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_primaryColor, _secondaryColor]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _secondaryColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text("Análisis IA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Tu tendencia actual es mayormente $tendencia. Sigue interactuando para obtener reportes más detallados sobre tu bienestar emocional.",
            style: const TextStyle(color: Colors.white, height: 1.4),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(backgroundColor: _backgroundColor, body: Center(child: CircularProgressIndicator(color: _primaryColor)));

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text("Tu Progreso", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _error
          ? Center(child: Text(_errorMessage ?? "Error", style: const TextStyle(color: Colors.red)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildAnalysisCard(),
                  const SizedBox(height: 20),
                  _buildBentoCard(
                    title: "Balance Emocional",
                    child: _buildDonutChart(),
                  ),
                  _buildBentoCard(
                    title: "Detección Facial",
                    child: _buildBarChart(),
                  ),
                ],
              ),
            ),
    );
  }
}