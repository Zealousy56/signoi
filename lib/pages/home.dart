import 'package:flutter/material.dart';
import 'detail.dart';

class HomePage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Function(List<Map<String, dynamic>>) onItemsChanged;

  const HomePage({super.key, required this.items, required this.onItemsChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.items;
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      setState(() {
        _items = widget.items;
      });
    }
  }
  

  void _addItem() {
    // show dialog to enter custom title
    showDialog<String?>(
      context: context,
      builder: (context) {
        final TextEditingController t = TextEditingController();
        return AlertDialog(
          title: const Text('Add item'),
          content: TextField(controller: t, autofocus: true, decoration: const InputDecoration(hintText: 'Title')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, t.text.trim()), child: const Text('Add')),
          ],
        );
      },
    ).then((result) {
      if (!mounted) return;
      if (result != null && result.isNotEmpty) {
        setState(() {
          _items.insert(0, {'title': result, 'subNotes': <Map<String, dynamic>>[], 'steps': <Map<String, dynamic>>[], 'progress': 0});
          widget.onItemsChanged(_items);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added Item: $result')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Signal'),
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
              // TODO: navigate to settings page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Open Settings (TODO)')),
              );
            },
          ),
        ],
      ),

      body: SafeArea(
        child: _items.isEmpty
            ? const Center(child: Text('No items yet'))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                itemCount: _items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final itemNumber = index + 1;
                  final item = _items[index];
                  final String title = item['title'] as String? ?? '';
                  final List<Map<String, dynamic>> rawTasks =
                      (item['subNotes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                  final tasks = List<Map<String, dynamic>>.from(rawTasks)
                    ..sort((a, b) {
                      // Sort by taskType first (daily before temporary)
                      final aType = a['taskType'] as String? ?? 'temporary';
                      final bType = b['taskType'] as String? ?? 'temporary';
                      if (aType != bType) {
                        return aType == 'daily' ? -1 : 1;
                      }
                      // Then sort by checked status
                      return (a['checked'] == true ? 1 : 0).compareTo(b['checked'] == true ? 1 : 0);
                    });
                  final previewTasks = tasks.take(3).toList();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(
                              item: title,
                              index: index,
                              subNotes: rawTasks,
                              allowAddTasks: true,
                              taskType: 'temporary',
                            ),
                          ),
                        );

                        if (result == null) return;
                        if (result is Map) {
                          if (result['deleted'] == true && result['index'] is int) {
                            final delIndex = result['index'] as int;
                            if (delIndex >= 0 && delIndex < _items.length) {
                              setState(() {
                                _items.removeAt(delIndex);
                                widget.onItemsChanged(_items);
                              });
                            }
                          } else if (result['title'] is String && result['index'] is int) {
                            final idx = result['index'] as int;
                            final titleResult = result['title'] as String;
                            final List<Map<String, dynamic>> returnedSubNotes =
                                (result['subNotes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                            if (idx >= 0 && idx < _items.length) {
                              setState(() {
                                _items[idx] = {
                                  'title': titleResult,
                                  'subNotes': returnedSubNotes
                                      .map((e) => {
                                            'text': e['text'] ?? '',
                                            'checked': e['checked'] ?? false,
                                            'taskType': e['taskType'] ?? 'temporary',
                                          })
                                      .toList(),
                                  'steps': _items[idx]['steps'] ?? <Map<String, dynamic>>[],
                                  'progress': _items[idx]['progress'] ?? 0,
                                };
                                widget.onItemsChanged(_items);
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(child: Text('$itemNumber')),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 8),
                                    if (tasks.isEmpty)
                                      const Text('No tasks yet', style: TextStyle(color: Colors.grey))
                                    else ...[
                                      ...previewTasks.map((task) {
                                        final done = task['checked'] == true;
                                        final taskType = task['taskType'] as String? ?? 'temporary';
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                                          child: Row(
                                            children: [
                                              Icon(
                                                done ? Icons.check_circle : Icons.radio_button_unchecked,
                                                color: done ? Colors.green : (taskType == 'daily' ? Colors.blue : Colors.orange),
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        task['text'] as String? ?? '',
                                                        style: TextStyle(
                                                          decoration: done
                                                              ? TextDecoration.lineThrough
                                                              : TextDecoration.none,
                                                          color: done ? Colors.grey : Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      taskType == 'daily' ? 'D' : 'T',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: taskType == 'daily' ? Colors.blue : Colors.orange,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                      if (tasks.length > previewTasks.length)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            '+${tasks.length - previewTasks.length} more task(s)',
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                        ),
                                    ],
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
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        tooltip: 'Add item',
        child: const Icon(Icons.add),
      ),
    );
  }

  // No PageController used in vertical list; nothing to dispose.
}