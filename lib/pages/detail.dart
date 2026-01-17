import 'package:flutter/material.dart';

class DetailPage extends StatefulWidget {
  final String item;
  final int index;
  final List<Map<String, dynamic>> subNotes;
  final bool allowAddTasks;
  final String taskType;
  const DetailPage({
    super.key,
    required this.item,
    required this.index,
    this.subNotes = const <Map<String, dynamic>>[],
    this.allowAddTasks = true,
    this.taskType = 'temporary',
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late TextEditingController _controller;
  late FocusNode _titleFocusNode;
  bool _isEditing = false;
  void _onControllerChanged() => setState(() {});
  late List<Map<String, dynamic>> _subNotes;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item);
    _titleFocusNode = FocusNode();
    _controller.addListener(_onControllerChanged);
    _subNotes = widget.subNotes
        .map((e) => {
              'text': e['text'] ?? '',
              'checked': e['checked'] ?? false,
              'taskType': e['taskType'] ?? 'temporary',
            })
        .toList();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _titleFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    setState(() {
      _isEditing = false;
    });
    _titleFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, {
            'index': widget.index,
            'title': _controller.text,
            'subNotes': _subNotes,
          });
        }
      },
      child: Scaffold(
      appBar: AppBar(
        titleSpacing: 0.0,
        centerTitle: false,
        title: widget.allowAddTasks
            ? (_isEditing
                ? SizedBox(
                    width: double.infinity,
                    child: TextField(
                      controller: _controller,
                      focusNode: _titleFocusNode,
                      style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 20.0),
                      decoration: const InputDecoration.collapsed(hintText: 'Title'),
                      textInputAction: TextInputAction.done,
                      maxLines: 1,
                      onSubmitted: (_) => _save(),
                    ),
                  )
                : Text(
                    _controller.text,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ))
            : const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Delete'),
                  content: const Text('Are you sure you want to delete this item?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        Navigator.pop(context, {'index': widget.index, 'deleted': true});
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Delete',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.allowAddTasks) ...[
              _isEditing
                  ? TextField(
                      controller: _controller,
                      focusNode: _titleFocusNode,
                      style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(border: InputBorder.none),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _save(),
                    )
                  : Text(
                      _controller.text,
                      style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
                    ),
              const SizedBox(height: 12),
            ] else ...[
              const SizedBox(),
              const SizedBox(height: 12),
              const Text('Tasks'),
              const SizedBox(height: 8),
              Expanded(
                  child: _subNotes.isEmpty
                      ? const Center(child: Text('No tasks yet'))
                      : Builder(
                          builder: (context) {
                            // Sort tasks: daily first, then by checked status
                            final sortedNotes = List<Map<String, dynamic>>.from(_subNotes)
                              ..sort((a, b) {
                                final aType = a['taskType'] as String? ?? 'temporary';
                                final bType = b['taskType'] as String? ?? 'temporary';
                                if (aType != bType) {
                                  return aType == 'daily' ? -1 : 1;
                                }
                                return (a['checked'] == true ? 1 : 0).compareTo(b['checked'] == true ? 1 : 0);
                              });
                            
                            return ListView.separated(
                                itemCount: sortedNotes.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final note = sortedNotes[index];
                                  final taskType = note['taskType'] as String? ?? 'temporary';
                                  return ListTile(
                                    title: Text(note['text'] as String),
                                    subtitle: Text(
                                      taskType == 'daily' ? 'Daily' : 'Temporary',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: taskType == 'daily' ? Colors.blue : Colors.orange,
                                      ),
                                    ),
                                    trailing: Checkbox(
                                      value: note['checked'] as bool,
                                      onChanged: (v) {
                                        setState(() {
                                          note['checked'] = v ?? false;
                                        });
                                      },
                                    ),
                                  );
                                },
                              );
                          },
                        )),
              if (widget.allowAddTasks) ...[
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await showDialog<Map<String, String>?>(
                        context: context,
                        builder: (dialogContext) {
                          final TextEditingController t = TextEditingController();
                          String selectedTaskType = widget.taskType;
                          return StatefulBuilder(
                            builder: (context, setDialogState) {
                              return AlertDialog(
                                title: const Text('Add task'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: t,
                                      decoration: const InputDecoration(hintText: 'Task name'),
                                      autofocus: true,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('Task type:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    RadioListTile<String>(
                                      title: const Text('Daily'),
                                      subtitle: const Text('Repeats every day'),
                                      value: 'daily',
                                      groupValue: selectedTaskType,
                                      onChanged: (value) {
                                        setDialogState(() {
                                          selectedTaskType = value!;
                                        });
                                      },
                                    ),
                                    RadioListTile<String>(
                                      title: const Text('Temporary'),
                                      subtitle: const Text('One-time task'),
                                      value: 'temporary',
                                      groupValue: selectedTaskType,
                                      onChanged: (value) {
                                        setDialogState(() {
                                          selectedTaskType = value!;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(
                                      dialogContext,
                                      {'text': t.text.trim(), 'taskType': selectedTaskType},
                                    ),
                                    child: const Text('Add'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                      if (result != null && result['text']!.isNotEmpty) {
                        setState(() {
                          _subNotes.add({
                            'text': result['text']!,
                            'checked': false,
                            'taskType': result['taskType']!,
                          });
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Task'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ],
        ),
      ),
      ),
    );
  }
}

