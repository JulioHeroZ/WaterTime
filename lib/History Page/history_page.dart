import 'package:flutter/material.dart';
import '../data_manager.dart'; // Atualização da importação
import '../tray_manager.dart';
import '../widgets/close_button_widget.dart';

class HistoricoPage extends StatelessWidget {
  final TrayManager? trayManager;

  const HistoricoPage({
    super.key,
    this.trayManager,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              AppBar(
                title: const Text(
                  'Historico',
                  style: TextStyle(color: Colors.white),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  CustomCloseButton(trayManager: trayManager),
                ],
                iconTheme: const IconThemeData(color: Colors.white),
                backgroundColor: const Color.fromARGB(255, 95, 189, 212),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: DataManager.getHistory(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Erro: ${snapshot.error}'));
                    }

                    final history = snapshot.data ?? [];

                    if (history.isEmpty) {
                      return const Center(
                          child: Text('Nenhum registro encontrado'));
                    }

                    return ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        final date = DateTime.parse(item['date']);
                        final amount = item['amount'];

                        return ListTile(
                          title: Text(
                            '${date.day}/${date.month}/${date.year}',
                            style: const TextStyle(fontSize: 18),
                          ),
                          trailing: Text(
                            '$amount ml',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
