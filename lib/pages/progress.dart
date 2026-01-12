import 'package:flutter/material.dart';
import 'detail.dart';

class ProgressPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Function(List<Map<String, dynamic>>) onItemsChanged;

  const ProgressPage({super.key, required this.items, required this.onItemsChanged});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.items;
  }

  @override
  void didUpdateWidget(ProgressPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      setState(() {
        _items = widget.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Progress'),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Icon(
              Icons.show_chart,
              size: 96,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Goals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          SizedBox(
            height: 180,
            child: _items.isEmpty
                ? const Center(child: Text('No goals yet'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                    scrollDirection: Axis.horizontal,
                    itemCount: _items.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final String title = item['title'] as String? ?? '';
                      final List<Map<String, dynamic>> rawTasks =
                          (item['subNotes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                      final tasks = List<Map<String, dynamic>>.from(rawTasks)
                        ..sort((a, b) {
                          // Sort by taskType first (daily before temporary)
                          final aType = a['taskType'] as String? ?? 'daily';
                          final bType = b['taskType'] as String? ?? 'daily';
                          if (aType != bType) {
                            return aType == 'daily' ? -1 : 1;
                          }
                          // Then sort by checked status
                          return (a['checked'] == true ? 1 : 0).compareTo(b['checked'] == true ? 1 : 0);
                        });
                      final previewTasks = tasks.take(2).toList();
                      return SizedBox(
                        width: 260,
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
                                  allowAddTasks: false,
                                  taskType: 'daily',
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
                                                'taskType': e['taskType'] ?? 'daily',
                                              })
                                          .toList(),
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
                                      final taskType = task['taskType'] as String? ?? 'daily';
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                                        child: Row(
                                          children: [
                                            Icon(
                                              done ? Icons.check_circle : Icons.radio_button_unchecked,
                                              color: done ? Colors.green : (taskType == 'daily' ? Colors.blue : Colors.orange),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      task['text'] as String? ?? '',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        decoration: done
                                                            ? TextDecoration.lineThrough
                                                            : TextDecoration.none,
                                                        color: done ? Colors.grey : Colors.black,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
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
                                          '+${tasks.length - previewTasks.length} more',
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ),
                                  ],
                                  const Spacer(),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Icon(Icons.chevron_right, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
