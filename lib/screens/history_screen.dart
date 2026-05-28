import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = List.generate(
      6,
      (i) => {
        'label': 'Plastic Bottle',
        'date': 'May ${20 + i}',
        'confidence': '${88 + i}%',
      },
    );
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemBuilder: (_, i) {
          final it = items[i];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.recycling, color: Colors.green),
              ),
              title: Text(it['label']!),
              subtitle: Text(it['date']!),
              trailing: Text(it['confidence']!),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: items.length,
      ),
    );
  }
}
