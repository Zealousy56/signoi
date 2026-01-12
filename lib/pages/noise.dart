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
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help selected')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Open Settings (TODO)')),
              );
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
        itemCount: _items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final itemNumber = index + 1;
          final itemText = _items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
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
              child: Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(child: Text('$itemNumber')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemText,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
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
