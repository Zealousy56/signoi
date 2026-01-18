import 'package:flutter/material.dart';

class ProgressPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Function(List<Map<String, dynamic>>) onItemsChanged;

  const ProgressPage({super.key, required this.items, required this.onItemsChanged});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  late List<Map<String, dynamic>> _items;
  final Set<int> _editingCards = {};
  final Map<int, TextEditingController> _titleControllers = {};
  final Map<int, Set<int>> _selectedStepIndices = {};
  final Map<String, int?> _editingStepIndex = {};
  final Map<String, TextEditingController> _stepControllers = {};
  final Map<int, Map<String, dynamic>> _originalState = {};

  @override
  void initState() {
    super.initState();
    _items = widget.items;
  }

  @override
  void dispose() {
    for (var controller in _titleControllers.values) {
      controller.dispose();
    }
    for (var controller in _stepControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('No goals yet'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('Goals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: PageView.builder(
                    padEnds: true,
                    pageSnapping: true,
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final String title = item['title'] as String? ?? '';
                      final List<Map<String, dynamic>> rawSteps =
                          (item['steps'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                      // Preserve user-defined order; do not sort when checking items
                      final steps = List<Map<String, dynamic>>.from(rawSteps);
                      final int progress = item['progress'] as int? ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SizedBox(
                          width: 300,
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
                                      Expanded(
                                        child: _editingCards.contains(index)
                                            ? TextField(
                                                controller: _titleControllers.putIfAbsent(
                                                  index,
                                                  () => TextEditingController(text: title),
                                                ),
                                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                                                decoration: const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                ),
                                                onSubmitted: (newTitle) {
                                                  if (newTitle.trim().isNotEmpty) {
                                                    setState(() {
                                                      _items[index]['title'] = newTitle.trim();
                                                      widget.onItemsChanged(_items);
                                                      _editingCards.remove(index);
                                                    });
                                                  }
                                                },
                                              )
                                            : Text(
                                                title,
                                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
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
                                              final newTitle = _titleControllers[index]?.text.trim() ?? '';
                                              if (newTitle.isNotEmpty) {
                                                _items[index]['title'] = newTitle;
                                                widget.onItemsChanged(_items);
                                              }
                                              _editingCards.remove(index);
                                              _titleControllers[index]?.dispose();
                                              _titleControllers.remove(index);
                                            } else {
                                              _editingCards.add(index);
                                              _originalState[index] = {
                                                'title': title,
                                                'steps': List<Map<String, dynamic>>.from(
                                                  (item['steps'] as List?)?.cast<Map<String, dynamic>>() ?? []
                                                ).map((s) => Map<String, dynamic>.from(s)).toList(),
                                              };
                                              _titleControllers[index] = TextEditingController(text: title)
                                                ..selection = TextSelection.fromPosition(
                                                  TextPosition(offset: title.length),
                                                );
                                            }
                                          });
                                        },
                                        tooltip: _editingCards.contains(index) ? 'Done' : 'Edit',
                                      ),
                                      if (_editingCards.contains(index))
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                          onPressed: () async {
                                            final shouldDelete = await showDialog<bool>(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  title: const Text('Delete Goal'),
                                                  content: Text('Are you sure you want to delete "$title"?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      child: const Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, true),
                                                      style: TextButton.styleFrom(
                                                        foregroundColor: Colors.red,
                                                      ),
                                                      child: const Text('Delete'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                            if (shouldDelete == true) {
                                              setState(() {
                                                _items.removeAt(index);
                                                widget.onItemsChanged(_items);
                                                _editingCards.remove(index);
                                                _titleControllers[index]?.dispose();
                                                _titleControllers.remove(index);
                                                _selectedStepIndices.remove(index);
                                              });
                                            }
                                          },
                                          tooltip: 'Delete Goal',
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value: progress / 100,
                                          backgroundColor: Colors.grey.shade200,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            progress < 50 ? Colors.orange : Colors.green,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$progress%',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: steps.isEmpty
                                        ? const Center(child: Text('No steps yet', style: TextStyle(color: Colors.grey, fontSize: 16)))
                                        : _editingCards.contains(index)
                                            ? ReorderableListView.builder(
                                              buildDefaultDragHandles: false,
                                              itemCount: steps.length,
                                              onReorder: (oldIndex, newIndex) {
                                                  setState(() {
                                                    final currentSteps = (_items[index]['steps'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                                    if (oldIndex < newIndex) {
                                                      newIndex -= 1;
                                                    }
                                                    final item = currentSteps.removeAt(oldIndex);
                                                    currentSteps.insert(newIndex, item);
                                                    _items[index]['steps'] = currentSteps;
                                                    widget.onItemsChanged(_items);
                                                    // Clear any selections since indices changed
                                                    _selectedStepIndices[index]?.clear();
                                                  });
                                                },
                                                itemBuilder: (context, stepIndex) {
                                                  final step = steps[stepIndex];
                                                  final done = step['checked'] == true;
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
                                                          // Selection mode - toggle selection
                                                          setState(() {
                                                            _selectedStepIndices.putIfAbsent(index, () => {});
                                                            if (_selectedStepIndices[index]!.contains(stepIndex)) {
                                                              _selectedStepIndices[index]!.remove(stepIndex);
                                                            } else {
                                                              _selectedStepIndices[index]!.add(stepIndex);
                                                            }
                                                          });
                                                        } else if (!isEditingThisStep) {
                                                          // Edit mode - start editing this step
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
                                                              color: done ? Colors.green : Colors.blue,
                                                              size: 16,
                                                            ),
                                                            const SizedBox(width: 6),
                                                            Expanded(
                                                              child: isEditingThisStep
                                                                  ? TextField(
                                                                      controller: _stepControllers[editKey],
                                                                      style: const TextStyle(fontSize: 18),
                                                                      decoration: const InputDecoration(
                                                                        border: OutlineInputBorder(),
                                                                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                                        isDense: true,
                                                                      ),
                                                                      onSubmitted: (newText) {
                                                                        if (newText.trim().isNotEmpty) {
                                                                          setState(() {
                                                                            final currentSteps = (_items[index]['steps'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                                                            if (stepIndex < currentSteps.length) {
                                                                              currentSteps[stepIndex]['text'] = newText.trim();
                                                                              _items[index]['steps'] = currentSteps;
                                                                              widget.onItemsChanged(_items);
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
                                                                        fontSize: 18,
                                                                        decoration: done
                                                                            ? TextDecoration.lineThrough
                                                                            : TextDecoration.none,
                                                                        color: done ? Colors.grey : Colors.black,
                                                                      ),
                                                                      overflow: TextOverflow.ellipsis,
                                                                      maxLines: 1,
                                                                    ),
                                                            ),
                                                            if (isEditingThisStep)
                                                              IconButton(
                                                                icon: const Icon(Icons.check, size: 16),
                                                                onPressed: () {
                                                                  final newText = _stepControllers[editKey]?.text.trim() ?? '';
                                                                  if (newText.isNotEmpty) {
                                                                    setState(() {
                                                                      final currentSteps = (_items[index]['steps'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                                                      if (stepIndex < currentSteps.length) {
                                                                        currentSteps[stepIndex]['text'] = newText;
                                                                        _items[index]['steps'] = currentSteps;
                                                                        widget.onItemsChanged(_items);
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
                                              )
                                            : ListView.builder(
                                                itemCount: steps.length,
                                                itemBuilder: (context, stepIndex) {
                                                  final step = steps[stepIndex];
                                                  final done = step['checked'] == true;
                                                  return Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                                                      child: Row(
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          Icon(
                                                            done ? Icons.check_circle : Icons.radio_button_unchecked,
                                                            color: done ? Colors.green : Colors.blue,
                                                            size: 16,
                                                          ),
                                                          const SizedBox(width: 6),
                                                          Expanded(
                                                            child: Text(
                                                              step['text'] as String? ?? '',
                                                              style: TextStyle(
                                                                fontSize: 18,
                                                                decoration: done
                                                                    ? TextDecoration.lineThrough
                                                                    : TextDecoration.none,
                                                                color: done ? Colors.grey : Colors.black,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                          ),
                                                          GestureDetector(
                                                            onLongPress: () {
                                                              setState(() {
                                                                final currentSteps = (_items[index]['steps'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                                                if (stepIndex < currentSteps.length) {
                                                                  final prev = currentSteps[stepIndex]['checked'] == true;
                                                                  currentSteps[stepIndex]['checked'] = !prev;
                                                                  _items[index]['steps'] = currentSteps;
                                                                  widget.onItemsChanged(_items);
                                                                }
                                                              });
                                                            },
                                                            child: Icon(
                                                              done ? Icons.check : Icons.remove,
                                                              color: done ? Colors.green : Colors.grey,
                                                              size: 18,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                  ),
                                  if (_editingCards.contains(index))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () async {
                                        final result = await showDialog<String?>(
                                          context: context,
                                          builder: (context) {
                                            final TextEditingController stepController = TextEditingController();
                                            return AlertDialog(
                                              title: const Text('Add Step'),
                                              content: TextField(
                                                controller: stepController,
                                                autofocus: true,
                                                decoration: const InputDecoration(
                                                  labelText: 'Step description',
                                                  hintText: 'What needs to be done?',
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    final text = stepController.text.trim();
                                                    Navigator.pop(context, text);
                                                  },
                                                  child: const Text('Add'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                        if (result != null && result.isNotEmpty) {
                                          setState(() {
                                            final currentSteps = (_items[index]['steps'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                            currentSteps.add({
                                              'text': result,
                                              'checked': false,
                                            });
                                            _items[index]['steps'] = currentSteps;
                                            widget.onItemsChanged(_items);
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Add Step'),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                      ),
                                      ),
                                    ),
                                  if (_editingCards.contains(index) && (_selectedStepIndices[index]?.isNotEmpty ?? false))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                final currentSteps = (_items[index]['steps'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                                final selectedSet = _selectedStepIndices[index] ?? {};
                                                // Remove steps in reverse order to avoid index issues
                                                final sortedIndices = selectedSet.toList()..sort((a, b) => b.compareTo(a));
                                                for (final stepIdx in sortedIndices) {
                                                  if (stepIdx < currentSteps.length) {
                                                    currentSteps.removeAt(stepIdx);
                                                  }
                                                }
                                                _items[index]['steps'] = currentSteps;
                                                widget.onItemsChanged(_items);
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
                                  if (_editingCards.contains(index))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Center(
                                        child: TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              if (_originalState.containsKey(index)) {
                                                _items[index]['title'] = _originalState[index]!['title'];
                                                _items[index]['steps'] = _originalState[index]!['steps'];
                                                widget.onItemsChanged(_items);
                                              }
                                              _editingCards.remove(index);
                                              _titleControllers[index]?.dispose();
                                              _titleControllers.remove(index);
                                              _selectedStepIndices.remove(index);
                                              _originalState.remove(index);
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
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await showDialog<Map<String, dynamic>?>(
                  context: context,
                  builder: (context) {
                    final TextEditingController titleController = TextEditingController();
                    final TextEditingController progressController = TextEditingController();
                    return AlertDialog(
                      title: const Text('Add goal'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: titleController,
                            autofocus: true,
                            decoration: InputDecoration(
                              labelText: 'Goal title',
                              hintText: 'What\'s your goal?',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: progressController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Target Time',
                              hintText: 'How many days to achieve your goal?',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                            ),
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
                            final title = titleController.text.trim();
                            final progressText = progressController.text.trim();
                            int progress = int.tryParse(progressText) ?? 0;
                            if (progress < 0) progress = 0;
                            if (progress > 100) progress = 100;
                            Navigator.pop(context, {
                              'title': title,
                              'progress': progress,
                              'steps': <Map<String, dynamic>>[],
                            });
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    );
                  },
                );
                if (result != null && result['title'] != null && result['title'].toString().isNotEmpty) {
                  setState(() {
                    _items.add({
                      'title': result['title'],
                      'subNotes': <Map<String, dynamic>>[],
                      'steps': result['steps'] ?? <Map<String, dynamic>>[],
                      'progress': result['progress'] ?? 0,
                    });
                    widget.onItemsChanged(_items);
                  });
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Goal'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
