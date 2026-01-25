import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Function(List<Map<String, dynamic>>) onItemsChanged;

  const HomePage({super.key, required this.items, required this.onItemsChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Map<String, dynamic>> _items;
  final Set<int> _editingCards = {};
  final Map<int, Set<int>> _selectedStepIndices = {};
  final Map<String, int?> _editingStepIndex = {};
  final Map<String, TextEditingController> _stepControllers = {};
  final Map<int, List<Map<String, dynamic>>> _originalTasks = {};

  @override
  void initState() {
    super.initState();
    _items = widget.items;
  }

  @override
  void dispose() {
    for (var controller in _stepControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Card(
                      color: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(child: Text('$itemNumber')),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _editingCards.contains(index) ? Icons.check : Icons.edit,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (_editingCards.contains(index)) {
                                        // Save changes when exiting edit mode
                                        widget.onItemsChanged(_items);
                                        _editingCards.remove(index);
                                        _selectedStepIndices.remove(index);
                                        _originalTasks.remove(index);
                                        _editingStepIndex.removeWhere((key, value) => key.startsWith('${index}_'));
                                        _stepControllers.removeWhere((key, controller) {
                                          if (key.startsWith('${index}_')) {
                                            controller.dispose();
                                            return true;
                                          }
                                          return false;
                                        });
                                      } else {
                                        // Backup original tasks when entering edit mode
                                        final currentTasks = (_items[index]['subNotes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                        _originalTasks[index] = List<Map<String, dynamic>>.from(
                                          currentTasks.map((task) => Map<String, dynamic>.from(task))
                                        );
                                        _editingCards.add(index);
                                      }
                                    });
                                  },
                                  tooltip: _editingCards.contains(index) ? 'Done' : 'Edit Tasks',
                                ),
                              ],
                            ),
                            if (_editingCards.contains(index)) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 300,
                                child: tasks.isEmpty
                                    ? const Center(child: Text('No tasks yet', style: TextStyle(color: Colors.grey, fontSize: 16)))
                                    : ReorderableListView.builder(
                                        buildDefaultDragHandles: false,
                                        itemCount: tasks.length,
                                        onReorder: (oldIndex, newIndex) {
                                          setState(() {
                                            final currentTasks = (_items[index]['subNotes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                            if (oldIndex < newIndex) {
                                              newIndex -= 1;
                                            }
                                            final item = currentTasks.removeAt(oldIndex);
                                            currentTasks.insert(newIndex, item);
                                            _items[index]['subNotes'] = currentTasks;
                                            // Don't save immediately - wait for user to confirm changes
                                            _selectedStepIndices[index]?.clear();
                                          });
                                        },
                                        itemBuilder: (context, stepIndex) {
                                          final step = tasks[stepIndex];
                                          final done = step['checked'] == true;
                                          final taskType = step['taskType'] as String? ?? 'temporary';
                                          final selectedSet = _selectedStepIndices[index] ?? {};
                                          final isSelected = selectedSet.contains(stepIndex);
                                          final editKey = '${index}_$stepIndex';
                                          final isEditingThisStep = _editingStepIndex[editKey.toString()] == stepIndex;
                                          return Padding(
                                            key: ValueKey('${index}_${step['text']}_$stepIndex'),
                                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                                            child: GestureDetector(
                                              onLongPress: () {
                                                setState(() {
                                                  _selectedStepIndices.putIfAbsent(index, () => {});
                                                  if (_selectedStepIndices[index]!.contains(stepIndex)) {
                                                    _selectedStepIndices[index]!.remove(stepIndex);
                                                  } else {
                                                    _selectedStepIndices[index]!.add(stepIndex);
                                                  }
                                                });
                                              },
                                              onTap: () {
                                                if ((_selectedStepIndices[index]?.isNotEmpty ?? false)) {
                                                  setState(() {
                                                    _selectedStepIndices.putIfAbsent(index, () => {});
                                                    if (_selectedStepIndices[index]!.contains(stepIndex)) {
                                                      _selectedStepIndices[index]!.remove(stepIndex);
                                                    } else {
                                                      _selectedStepIndices[index]!.add(stepIndex);
                                                    }
                                                  });
                                                } else if (!isEditingThisStep) {
                                                  setState(() {
                                                    _editingStepIndex[editKey] = stepIndex;
                                                    _stepControllers[editKey] = TextEditingController(text: step['text'] as String? ?? '')
                                                      ..selection = TextSelection.fromPosition(
                                                        TextPosition(offset: (step['text'] as String? ?? '').length),
                                                      );
                                                  });
                                                }
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: isSelected ? const Color.fromARGB(51, 33, 150, 243) : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    ReorderableDragStartListener(
                                                      index: stepIndex,
                                                      child: const Icon(
                                                        Icons.drag_handle,
                                                        color: Colors.grey,
                                                        size: 16,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Icon(
                                                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                                                      color: done ? Colors.green : (taskType == 'daily' ? Colors.blue : Colors.orange),
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: isEditingThisStep
                                                          ? TextField(
                                                              controller: _stepControllers[editKey],
                                                              style: const TextStyle(fontSize: 16),
                                                              decoration: const InputDecoration(
                                                                border: OutlineInputBorder(),
                                                                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                                isDense: true,
                                                              ),
                                                              onSubmitted: (newText) {
                                                                if (newText.trim().isNotEmpty) {
                                                                  setState(() {
                                                                    final currentTasks = (_items[index]['subNotes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                                                    if (stepIndex < currentTasks.length) {
                                                                      currentTasks[stepIndex]['text'] = newText.trim();
                                                                      _items[index]['subNotes'] = currentTasks;
                                                                      // Don't save immediately - wait for user to confirm changes
                                                                    }
                                                                    _editingStepIndex.remove(editKey);
                                                                    _stepControllers[editKey]?.dispose();
                                                                    _stepControllers.remove(editKey);
                                                                  });
                                                                }
                                                              },
                                                            )
                                                          : Text(
                                                              step['text'] as String? ?? '',
                                                              style: TextStyle(
                                                                fontSize: 16,
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
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: taskType == 'daily' ? Colors.blue : Colors.orange,
                                                      ),
                                                    ),
                                                    if (isEditingThisStep)
                                                      IconButton(
                                                        icon: const Icon(Icons.check, size: 16),
                                                        onPressed: () {
                                                          final newText = _stepControllers[editKey]?.text.trim() ?? '';
                                                          if (newText.isNotEmpty) {
                                                            setState(() {
                                                              final currentTasks = (_items[index]['subNotes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                                              if (stepIndex < currentTasks.length) {
                                                                currentTasks[stepIndex]['text'] = newText;
                                                                _items[index]['subNotes'] = currentTasks;
                                                                // Don't save immediately - wait for user to confirm changes
                                                              }
                                                              _editingStepIndex.remove(editKey);
                                                              _stepControllers[editKey]?.dispose();
                                                              _stepControllers.remove(editKey);
                                                            });
                                                          }
                                                        },
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      final result = await showDialog<Map<String, dynamic>?>(
                                        context: context,
                                        builder: (context) {
                                          final TextEditingController taskController = TextEditingController();
                                          String selectedTaskType = 'temporary';
                                          return StatefulBuilder(
                                            builder: (context, setDialogState) {
                                              return AlertDialog(
                                                title: const Text('Add Task'),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    TextField(
                                                      controller: taskController,
                                                      autofocus: true,
                                                      decoration: const InputDecoration(
                                                        labelText: 'Task description',
                                                        hintText: 'What needs to be done?',
                                                      ),
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
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      final text = taskController.text.trim();
                                                      Navigator.pop(context, {
                                                        'text': text,
                                                        'taskType': selectedTaskType,
                                                      });
                                                    },
                                                    child: const Text('Add'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                      if (result != null && (result['text'] as String? ?? '').isNotEmpty) {
                                        setState(() {
                                          final currentTasks = (_items[index]['subNotes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                          currentTasks.add({
                                            'text': result['text'],
                                            'taskType': result['taskType'] ?? 'temporary',
                                            'checked': false,
                                          });
                                          _items[index]['subNotes'] = currentTasks;
                                          // Don't save immediately - wait for user to confirm changes
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Add Task'),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                ),
                              ),
                              if (_selectedStepIndices[index]?.isNotEmpty ?? false)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          final currentTasks = (_items[index]['subNotes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                          final selectedSet = _selectedStepIndices[index] ?? {};
                                          final sortedIndices = selectedSet.toList()..sort((a, b) => b.compareTo(a));
                                          for (final taskIdx in sortedIndices) {
                                            if (taskIdx < currentTasks.length) {
                                              currentTasks.removeAt(taskIdx);
                                            }
                                          }
                                          _items[index]['subNotes'] = currentTasks;
                                          // Don't save immediately - wait for user to confirm changes
                                          _selectedStepIndices[index]?.clear();
                                        });
                                      },
                                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                      label: Text('Delete (${_selectedStepIndices[index]?.length ?? 0})'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Center(
                                  child: TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        // Restore original tasks from backup
                                        if (_originalTasks.containsKey(index)) {
                                          _items[index]['subNotes'] = _originalTasks[index];
                                          _originalTasks.remove(index);
                                        }
                                        _editingCards.remove(index);
                                        _selectedStepIndices.remove(index);
                                        _editingStepIndex.removeWhere((key, value) => key.startsWith('${index}_'));
                                        _stepControllers.removeWhere((key, controller) {
                                          if (key.startsWith('${index}_')) {
                                            controller.dispose();
                                            return true;
                                          }
                                          return false;
                                        });
                                      });
                                    },
                                    icon: const Icon(Icons.cancel, size: 18),
                                    label: const Text('Cancel Changes'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                ),
                              ),
                            ] else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  if (tasks.isEmpty)
                                    const Text('No tasks yet', style: TextStyle(color: Colors.grey, fontSize: 14))
                                  else
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: tasks.map((task) {
                                        final done = task['checked'] == true;
                                        final taskType = task['taskType'] as String? ?? 'temporary';
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                final currentTasks = (_items[index]['subNotes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                                final taskIndex = currentTasks.indexWhere((t) => t['text'] == task['text']);
                                                if (taskIndex >= 0) {
                                                  currentTasks[taskIndex]['checked'] = !done;
                                                  _items[index]['subNotes'] = currentTasks;
                                                  widget.onItemsChanged(_items);
                                                }
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                                                    color: done ? Colors.green : (taskType == 'daily' ? Colors.blue : Colors.orange),
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      task['text'] as String? ?? '',
                                                      style: TextStyle(
                                                        fontSize: 14,
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
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  // No PageController used in vertical list; nothing to dispose.
}