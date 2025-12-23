import 'package:flutter/material.dart';
import 'detail.dart';

class NoisePage extends StatefulWidget {
  const NoisePage({super.key});

  @override
  State<NoisePage> createState() => _NoisePageState();
}

class _NoisePageState extends State<NoisePage> {
  final List<String> _items = List.generate(12, (i) => 'Noise ${i + 1}');
  int _nextIndex = 13;

  void _addItem() {
    setState(() {
      _items.insert(0, 'Noise ${_nextIndex++}');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added Noise ${_nextIndex - 1}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Noise'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: _items.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final itemNumber = index + 1;
          final itemText = _items[index];
          return ListTile(
            leading: CircleAvatar(child: Text('$itemNumber')),
            title: Text(itemText),
            subtitle: const Text('Tap to view details'),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailPage(item: itemText, index: index),
                ),
              );

              if (result == null) return;
              if (result is Map) {
                if (result['deleted'] == true && result['index'] is int) {
                  final delIndex = result['index'] as int;
                  if (delIndex >= 0 && delIndex < _items.length) {
                    setState(() {
                      _items.removeAt(delIndex);
                    });
                  }
                } else if (result['title'] is String && result['index'] is int) {
                  final idx = result['index'] as int;
                  final title = result['title'] as String;
                  if (idx >= 0 && idx < _items.length) {
                    setState(() {
                      _items[idx] = title;
                    });
                  }
                }
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        tooltip: 'Add noise',
        child: const Icon(Icons.add),
      ),
    );
  }
}
