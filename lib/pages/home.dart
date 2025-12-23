import 'package:flutter/material.dart';
import 'detail.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> _items = List.generate(20, (i) => 'Item ${i + 1}');
  int _nextIndex = 21;

  void _addItem() {
    setState(() {
      _items.insert(0, 'Item ${_nextIndex++}');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added Item ${_nextIndex - 1}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Signal'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'settings') {
                // TODO: navigate to settings page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Open Settings (TODO)')),
                );
              } else if (value == 'help') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help selected')),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuItem(value: 'help', child: Text('Help')),
            ],
          ),
        ],
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
        tooltip: 'Add item',
        child: const Icon(Icons.add),
      ),
    );
  }
}