import 'package:flutter/material.dart';

class ProgressPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Function(List<Map<String, dynamic>>) onItemsChanged;
  final List<Map<String, dynamic>> shortTermItems;
  final Function(List<Map<String, dynamic>>) onShortTermItemsChanged;

  const ProgressPage({
    super.key,
    required this.items,
    required this.onItemsChanged,
    required this.shortTermItems,
    required this.onShortTermItemsChanged,
  });

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
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
      body: PageView(
        scrollDirection: Axis.vertical,
        pageSnapping: true,
        children: [
          // Long-term goals section
          GoalListSection(
            title: 'Long-term Goals',
            items: widget.items,
            onItemsChanged: widget.onItemsChanged,
          ),
          // Short-term goals section
          GoalListSection(
            title: 'Short-term Goals',
            items: widget.shortTermItems,
            onItemsChanged: widget.onShortTermItemsChanged,
          ),
        ],
      ),
    );
  }
}

// Separate widget for each goal list section
class GoalListSection extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final Function(List<Map<String, dynamic>>) onItemsChanged;

  const GoalListSection({
    super.key,
    required this.title,
    required this.items,
    required this.onItemsChanged,
  });

  @override
  State<GoalListSection> createState() => _GoalListSectionState();
}

class _GoalListSectionState extends State<GoalListSection> {
  late List<Map<String, dynamic>> _items;
  final Set<int> _editingCards = {};
  final Map<int, TextEditingController> _titleControllers = {};
  final Map<int, Set<int>> _selectedStepIndices = {};
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
  void didUpdateWidget(GoalListSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      setState(() {
        _items = widget.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _items.isEmpty
              ? Center(child: Text('No ${widget.title} yet'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        widget.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
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
                          final steps = List<Map<String, dynamic>>.from(rawSteps);
                          final int progress = item['progress'] as int? ?? 0;
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: SizedBox(
                              width: 300,
                              child: Card(
                                color: Colors.white,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildHeader(index, title),
                                      const SizedBox(height: 8),
                                      _buildProgressBar(progress),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: _buildStepsList(index, steps),
                                      ),
                                      if (_editingCards.contains(index)) ...[
                                        _buildAddStepButton(index),
                                        if (_selectedStepIndices[index]?.isNotEmpty ?? false)
                                          _buildDeleteSelectedButton(index),
                                      ],
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ElevatedButton.icon(
              onPressed: () => _showAddGoalDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Goal'),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHeader(int index, String title) {
    return Row(
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
          onPressed: () => _toggleEdit(index, title),
          tooltip: _editingCards.contains(index) ? 'Done' : 'Edit',
        ),
        if (_editingCards.contains(index))
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
            onPressed: () => _deleteGoal(index, title),
            tooltip: 'Delete Goal',
          ),
      ],
    );
  }

  Widget _buildProgressBar(int progress) {
    return Row(
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
    );
  }

  Widget _buildStepsList(int index, List<Map<String, dynamic>> steps) {
    if (steps.isEmpty) {
      return const Center(
        child: Text(
          'No steps yet',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: steps.length,
      itemBuilder: (context, stepIndex) {
        final step = steps[stepIndex];
        final done = step['checked'] == true;
        final selectedSet = _selectedStepIndices[index] ?? {};
        final isSelected = selectedSet.contains(stepIndex);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: GestureDetector(
            onLongPress: _editingCards.contains(index)
                ? () => _toggleStepSelection(index, stepIndex)
                : null,
            child: Container(
              color: isSelected
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.transparent,
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
                    onTap: () => _toggleStepChecked(index, stepIndex),
                    child: Icon(
                      done ? Icons.check : Icons.remove,
                      color: done ? Colors.green : Colors.grey,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddStepButton(int index) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => _showAddStepDialog(index),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Step'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteSelectedButton(int index) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => _deleteSelectedSteps(index),
          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
          label: Text('Delete (${_selectedStepIndices[index]?.length ?? 0})'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ),
    );
  }

  void _toggleEdit(int index, String title) {
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
            (_items[index]['steps'] as List?)?.cast<Map<String, dynamic>>() ?? [],
          ).map((s) => Map<String, dynamic>.from(s)).toList(),
        };
        _titleControllers[index] = TextEditingController(text: title)
          ..selection = TextSelection.fromPosition(
            TextPosition(offset: title.length),
          );
      }
    });
  }

  Future<void> _deleteGoal(int index, String title) async {
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
              style: TextButton.styleFrom(foregroundColor: Colors.red),
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
  }

  void _toggleStepSelection(int index, int stepIndex) {
    setState(() {
      _selectedStepIndices.putIfAbsent(index, () => {});
      if (_selectedStepIndices[index]!.contains(stepIndex)) {
        _selectedStepIndices[index]!.remove(stepIndex);
      } else {
        _selectedStepIndices[index]!.add(stepIndex);
      }
    });
  }

  void _toggleStepChecked(int index, int stepIndex) {
    setState(() {
      final currentSteps =
          (_items[index]['steps'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (stepIndex < currentSteps.length) {
        final prev = currentSteps[stepIndex]['checked'] == true;
        currentSteps[stepIndex]['checked'] = !prev;
        _items[index]['steps'] = currentSteps;
        widget.onItemsChanged(_items);
      }
    });
  }

  void _deleteSelectedSteps(int index) {
    setState(() {
      final currentSteps =
          (_items[index]['steps'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final selectedSet = _selectedStepIndices[index] ?? {};
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
  }

  Future<void> _showAddStepDialog(int index) async {
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
        final currentSteps =
            (_items[index]['steps'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        currentSteps.add({
          'text': result,
          'checked': false,
        });
        _items[index]['steps'] = currentSteps;
        widget.onItemsChanged(_items);
      });
    }
  }

  Future<void> _showAddGoalDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final progressController = TextEditingController(text: '0');

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Goal Title',
                  hintText: 'Enter goal title',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: progressController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Initial Progress (%)',
                  hintText: '0-100',
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

    if (result != null &&
        result['title'] != null &&
        result['title'].toString().isNotEmpty) {
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
  }
}
