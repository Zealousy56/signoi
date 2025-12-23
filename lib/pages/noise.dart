import 'package:flutter/material.dart';
import 'detail.dart';

class NoisePage extends StatefulWidget {
  const NoisePage({super.key});

  @override
  State<NoisePage> createState() => _NoisePageState();
}

class _NoisePageState extends State<NoisePage> {
  final List<String> _items = List.generate(12, (i) => 'Noise ${i + 1}');
  Future<void> _addItem() async {
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        final TextEditingController t = TextEditingController();
        return AlertDialog(
          title: const Text('Add noise'),
          content: TextField(controller: t, autofocus: true, decoration: const InputDecoration(hintText: 'Title')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, t.text.trim()), child: const Text('Add')),
          ],
        );
      },
    );
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      setState(() {
        _items.insert(0, result);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added Noise: $result')),
      );
    }
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
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailPage(item: itemText, index: index, allowAddTasks: false),
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
