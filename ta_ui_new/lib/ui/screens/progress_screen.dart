import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final String userId = "default_user";

  bool loading = true;
  bool error = false;

  int positiva = 0;
  int negativa = 0;
  int neutra = 0;

  Map<String, int> ferCounts = {
    "happy": 0,
    "sad": 0,
    "angry": 0,
    "fear": 0,
    "surprise": 0,
    "neutral": 0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _loadConversations();
      await _loadFER();
      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = true;
        loading = false;
      });
    }
  }

  Future<void> _loadConversations() async {
    final ref = FirebaseFirestore.instance
        .collection("users/$userId/conversations");

    final snapshot = await ref.get();

    positiva = 0;
    negativa = 0;
    neutra = 0;

    for (var doc in snapshot.docs) {
      final emo = doc["emotion_type"] ?? "Neutra";

      switch (emo) {
        case "Positiva":
          positiva++;
          break;
        case "Negativa":
          negativa++;
          break;
        default:
          neutra++;
      }
    }
  }

  Future<void> _loadFER() async {
    final ref = FirebaseFirestore.instance
        .collection("users/$userId/emotions");

    final snapshot = await ref.get();

    ferCounts.updateAll((key, value) => 0);

    for (var doc in snapshot.docs) {
      final emo = doc["dominant_emotion"] ?? "neutral";
      if (ferCounts.containsKey(emo)) {
        ferCounts[emo] = ferCounts[emo]! + 1;
      }
    }
  }

  Widget _buildPieChart() {
    final total = positiva + negativa + neutra;

    if (total == 0) {
      return const Text("Aún no tienes conversaciones registradas");
    }

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 35,
          sections: [
            PieChartSectionData(
              value: positiva.toDouble(),
              title: "Pos",
              color: Colors.green,
            ),
            PieChartSectionData(
              value: neutra.toDouble(),
              title: "Neu",
              color: Colors.grey,
            ),
            PieChartSectionData(
              value: negativa.toDouble(),
              title: "Neg",
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final total = ferCounts.values.reduce((a, b) => a + b);

    if (total == 0) {
      return const Text("Aún no tienes sesiones de avatar registradas");
    }

    final emotions = ferCounts.keys.toList();

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= emotions.length) return Container();
                  return Text(emotions[i], style: const TextStyle(fontSize: 12));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
          ),
          barGroups: List.generate(
            emotions.length,
                (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: ferCounts[emotions[i]]!.toDouble(),
                  color: Colors.blueAccent,
                  width: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReport() {
    final convTotal = positiva + negativa + neutra;
    final ferTotal = ferCounts.values.reduce((a, b) => a + b);

    if (convTotal == 0 && ferTotal == 0) {
      return const Text(
        "No hay datos suficientes para generar un reporte emocional.",
        textAlign: TextAlign.center,
      );
    }

    String tendenciaConversacional = "equilibrada";
    if (positiva > negativa && positiva > neutra) {
      tendenciaConversacional = "positiva";
    } else if (negativa > positiva && negativa > neutra) {
      tendenciaConversacional = "negativa";
    } else if (neutra > positiva && neutra > negativa) {
      tendenciaConversacional = "neutra";
    }

    String ferDominante = ferCounts.entries.reduce((a, b) {
      return a.value > b.value ? a : b;
    }).key;

    return Text(
      "Reporte:\n\n"
          "En tus conversaciones recientes, tu tendencia emocional predominante fue $tendenciaConversacional. "
          "Durante las sesiones con el avatar, tus expresiones faciales mostraron principalmente la emoción $ferDominante. "
          "Este contraste o coincidencia entre cómo te expresas y cómo te sientes puede ayudar a comprender mejor tu estado emocional.",
      textAlign: TextAlign.justify,
      style: const TextStyle(fontSize: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: _loadData,
            child: const Text("Ocurrió un error. Reintentar"),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Progreso emocional"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "Tendencia emocional verbal",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _buildPieChart(),
            const SizedBox(height: 24),
            const Text(
              "Emociones durante sesiones con avatar",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _buildBarChart(),
            const SizedBox(height: 24),
            _buildReport(),
          ],
        ),
      ),
    );
  }
}
