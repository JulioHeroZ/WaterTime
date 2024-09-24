import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data_manager.dart'; // Atualização da importação

class HistoricoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Consumo'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DataManager.getHistory(), // Atualizado para utilizar getHistory
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar o histórico'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Nenhum registro encontrado'));
          }

          // Ordenar o histórico por data, do mais recente para o mais antigo
          final sortedHistory = snapshot.data!
            ..sort((a, b) {
              DateTime dateA = DateTime.parse(a['date']);
              DateTime dateB = DateTime.parse(b['date']);
              return dateB.compareTo(dateA);
            });

          return ListView.builder(
            itemCount: sortedHistory.length,
            itemBuilder: (context, index) {
              final registro = sortedHistory[index];
              final DateTime date = DateTime.parse(registro['date']);
              final int quantidade = registro['amount'];

              return ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text(DateFormat('dd/MM/yyyy').format(date)),
                trailing: Text('$quantidade ml'),
              );
            },
          );
        },
      ),
    );
  }
}
