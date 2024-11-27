import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data_manager.dart';
import 'dart:math';
import '../achievements/achievement_manager.dart';

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  List<Map<String, dynamic>> _history = [];
  int _streak = 0;
  double _averageConsumption = 0;
  Map<int, int> _frequentHours = {};
  
  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final history = await DataManager.getHistory();
    final additions = await DataManager.getAdditions();
    
    setState(() {
      _history = history;
      _calculateStreak();
      _calculateAverage();
      _calculateFrequentHours(additions);
    });
  }

  void _calculateStreak() {
    int streak = 0;
    final dailyGoal = 2000;
    DateTime currentDate = DateTime.now();
    
    for (var entry in _history.reversed) {
      final date = DateTime.parse(entry['date']);
      final amount = entry['amount'] as int;
      
      if (amount >= dailyGoal && 
          date.difference(currentDate).inDays.abs() <= 1) {
        streak++;
        currentDate = currentDate.subtract(Duration(days: 1));
        
        if (streak == 3) {
          AchievementManager.checkAchievement('streak_3');
        }
      } else {
        break;
      }
    }
    _streak = streak;
  }

  void _calculateAverage() {
    if (_history.isEmpty) return;
    
    final total = _history.fold<int>(
      0, (sum, entry) => sum + (entry['amount'] as int));
    _averageConsumption = total / _history.length;
  }

  void _calculateFrequentHours(List<Map<String, dynamic>> additions) {
    Map<String, int> hourCount = {};
    
    // Primeiro, vamos mapear todas as adições com seus timestamps como chaves
    for (var addition in additions) {
      final timestamp = addition['timestamp'] as String;
      final hour = DateTime.parse(timestamp).hour;
      final amount = addition['amount'] as int;
      
      if (amount > 0) { // Considera apenas adições positivas
        hourCount[timestamp] = hour;
      } else { // Se for uma remoção (amount negativo)
        // Remove a contagem correspondente
        hourCount.remove(timestamp);
      }
    }
    
    // Agora contamos a frequência das horas que permaneceram
    _frequentHours = {};
    hourCount.values.forEach((hour) {
      _frequentHours[hour] = (_frequentHours[hour] ?? 0) + 1;
    });
    
    // Ordena o mapa por frequência
    _frequentHours = Map.fromEntries(
      _frequentHours.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estatísticas'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStreakCard(),
            SizedBox(height: 16),
            _buildWeeklyChart(),
            SizedBox(height: 16),
            _buildAverageCard(),
            SizedBox(height: 16),
            _buildFrequentHoursChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sequência Atual',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.local_fire_department, 
                     color: Colors.orange, size: 32),
                SizedBox(width: 8),
                Text(
                  '$_streak dias',
                  style: TextStyle(fontSize: 24),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consumo Semanal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxConsumption(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.round()} ml',
                          TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final weekDays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
                          return Text(weekDays[value.toInt()]);
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        interval: 500,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '${value.toInt()} ml',
                              style: TextStyle(
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  barGroups: _getWeeklyData(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequentHoursChart() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Horários Mais Frequentes de Consumo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Quantidade de vezes que você bebeu água em cada horário',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getHourlySpots(),
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((LineBarSpot spot) {
                          return LineTooltipItem(
                            '${spot.y.toInt()}x às ${spot.x.toInt()}:00h',
                            TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2, // Mostra a cada 2 horas
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}h');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '${value.toInt()}x',
                              style: TextStyle(
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Média Diária',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.water_drop, color: Colors.blue, size: 32),
                SizedBox(width: 8),
                Text(
                  '${_averageConsumption.round()} ml',
                  style: TextStyle(fontSize: 24),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Métodos auxiliares para os gráficos
  double _getMaxConsumption() {
    if (_history.isEmpty) return 2000;
    return _history.map((e) => e['amount'] as int).reduce(max).toDouble() * 1.2;
  }

  List<BarChartGroupData> _getWeeklyData() {
    final now = DateTime.now();
    final currentWeekDay = now.weekday; // 1 (Segunda) até 7 (Domingo)
    
    final weekData = List.generate(7, (index) {
      // Calcula quantos dias precisamos voltar para cada posição
      final daysToSubtract = currentWeekDay - (index + 1);
      final date = now.subtract(Duration(days: daysToSubtract));
      final dateStr = date.toIso8601String().split('T')[0];
      
      final consumption = _history
          .firstWhere((e) => e['date'] == dateStr, 
                      orElse: () => {'amount': 0})['amount'] as int;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: consumption.toDouble(),
            color: Theme.of(context).primaryColor,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
    
    return weekData;
  }

  List<FlSpot> _getHourlySpots() {
    List<FlSpot> spots = [];
    for (int hour = 0; hour < 24; hour++) {
      spots.add(FlSpot(
        hour.toDouble(),
        (_frequentHours[hour] ?? 0).toDouble(),
      ));
    }
    return spots;
  }
}