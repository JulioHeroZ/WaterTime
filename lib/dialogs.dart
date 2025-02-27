import 'package:flutter/material.dart';
import 'custom_amount.dart';

class WaterSelectionDialog extends StatelessWidget {
  final List<CustomAmount> customAmounts;
  final Future<void> Function(int) addWater;
  final void Function(List<CustomAmount>) updateCustomAmounts;

  const WaterSelectionDialog({
    super.key,
    required this.customAmounts,
    required this.addWater,
    required this.updateCustomAmounts,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecione a quantidade de água'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _waterButton(context, 250),
            const SizedBox(height: 10),
            _waterButton(context, 500),
            const SizedBox(height: 10),
            _waterButton(context, 600),
            const SizedBox(height: 10),
            _waterButton(context, 1000),
            const SizedBox(height: 20),
            ...customAmounts.map((customAmount) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _waterButton(context, customAmount.amount,
                      isCustom: true, customAmountId: customAmount.id),
                )),
            ElevatedButton(
              onPressed: () async {
                await _showAddCustomAmountDialog(context);
              },
              child: const Text('Adicionar quantidade personalizada'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _waterButton(BuildContext context, int amount,
      {bool isCustom = false, String? customAmountId}) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await addWater(amount);
              if (context.mounted) {
                navigator.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2893eb),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(
              '$amount ml',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        if (isCustom)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () =>
                _showEditCustomAmountDialog(context, customAmountId!, amount),
          ),
      ],
    );
  }

  Future<void> _showAddCustomAmountDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar quantidade personalizada'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantidade (ml)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                int? amount = int.tryParse(controller.text);
                if (amount != null && amount > 0) {
                  customAmounts.add(CustomAmount(
                      id: DateTime.now().toString(), amount: amount));
                  updateCustomAmounts(customAmounts);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditCustomAmountDialog(
      BuildContext context, String id, int currentAmount) async {
    TextEditingController controller =
        TextEditingController(text: currentAmount.toString());
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar quantidade personalizada'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantidade (ml)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                int? amount = int.tryParse(controller.text);
                if (amount != null && amount > 0) {
                  customAmounts
                      .firstWhere((element) => element.id == id)
                      .amount = amount;
                  updateCustomAmounts(customAmounts);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Salvar'),
            ),
            TextButton(
              onPressed: () {
                customAmounts.removeWhere((element) => element.id == id);
                updateCustomAmounts(customAmounts);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }
}
