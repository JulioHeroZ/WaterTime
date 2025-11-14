import 'package:flutter/material.dart';
// A implementação original da página de Ranking foi comentada para
// desativar a funcionalidade de ranking, mantendo o código disponível
// para uma possível reimplementação futura.

/*
import '../services/ranking_service.dart';
import '../widgets/close_button_widget.dart';
import '../tray_manager.dart';

class RankingPage extends StatefulWidget {
  final TrayManager? trayManager;

  const RankingPage({super.key, this.trayManager});

  @override
  _RankingPageState createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Rankings'),
          actions: [
            CustomCloseButton(trayManager: widget.trayManager),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48.0),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Diário'),
                Tab(text: 'Mensal'),
                Tab(text: 'Anual'),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRankingList(RankingService.getDailyRankings()),
              _buildRankingList(RankingService.getMonthlyRankings()),
              _buildRankingList(RankingService.getYearlyRankings()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankingList(Stream<List<Map<String, dynamic>>> rankingStream) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: rankingStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erro: \\${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rankings = snapshot.data ?? [];

        if (rankings.isEmpty) {
          return const Center(
            child: Text('Nenhum ranking disponível'),
          );
        }

        return ListView.builder(
          itemCount: rankings.length,
          itemBuilder: (context, index) {
            final ranking = rankings[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getMedalColor(index),
                child: Text('\${index + 1}'),
              ),
              title: Text(ranking['display_name'] ?? 'Anônimo'),
              trailing: Text(
                '\${ranking[_getScoreField(index)]} ml',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getScoreField(int index) {
    switch (_tabController.index) {
      case 0:
        return 'daily_score';
      case 1:
        return 'monthly_score';
      case 2:
        return 'yearly_score';
      default:
        return 'daily_score';
    }
  }

  Color _getMedalColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber; // Ouro
      case 1:
        return Colors.grey[300]!; // Prata
      case 2:
        return Colors.brown[300]!; // Bronze
      default:
        return Colors.blue[200]!;
    }
  }
}
*/

// Placeholder simples quando o ranking está desativado.
class RankingPage extends StatelessWidget {
  // Mantemos o parâmetro trayManager para compatibilidade com
  // chamadas existentes (não é utilizado aqui).
  final dynamic trayManager;
  const RankingPage({super.key, this.trayManager});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rankings (desativado)'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'A funcionalidade de ranking foi removida temporariamente.\n\n',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
