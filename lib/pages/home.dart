import 'dart:math' as math;
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Function(List<Map<String, dynamic>>) onItemsChanged;
  final List<Map<String, dynamic>> shortTermItems;
  final Function(List<Map<String, dynamic>>) onShortTermItemsChanged;
  final List<Map<String, dynamic>> sharedItems;
  final Function(List<Map<String, dynamic>>) onSharedItemsChanged;
  final void Function(double) onExperienceEarned;

  const HomePage({
    super.key,
    required this.items,
    required this.onItemsChanged,
    required this.shortTermItems,
    required this.onShortTermItemsChanged,
    required this.sharedItems,
    required this.onSharedItemsChanged,
    required this.onExperienceEarned,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late List<Map<String, dynamic>> _items;
  late List<Map<String, dynamic>> _shortTermItems;
  late List<Map<String, dynamic>> _sharedItems;
  final Set<int> _editingCards = {};
  final Set<int> _expandedTaskCards = {};
  final Map<int, Set<int>> _selectedStepIndices = {};
  final Map<String, int?> _editingStepIndex = {};
  final Map<String, TextEditingController> _stepControllers = {};
  final Map<int, List<Map<String, dynamic>>> _originalTasks = {};
  final Set<int> _completingHomeCards = {};
  final Map<int, bool> _glowPulseStates = {};

  @override
  void initState() {
    super.initState();
    _items = widget.items;
    _shortTermItems = widget.shortTermItems;
    _sharedItems = widget.sharedItems;
  }

  @override
  void dispose() {
    for (var controller in _stepControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _isCardComplete(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) return false;
    return tasks.every((task) => task['checked'] == true);
  }

  void _completeHomeCard(int index, int completedCount) {
    if (_completingHomeCards.contains(index)) return;
    widget.onExperienceEarned(completedCount * 0.05);
    setState(() {
      _completingHomeCards.add(index);
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        if (index >= 0 && index < _items.length) {
          _items.removeAt(index);
        }
        widget.onItemsChanged(_items);

        _completingHomeCards.remove(index);
        _glowPulseStates.remove(index);
        _editingCards.clear();
        _expandedTaskCards.clear();
        _selectedStepIndices.clear();
        _editingStepIndex.clear();
        for (final controller in _stepControllers.values) {
          controller.dispose();
        }
        _stepControllers.clear();
      });
    });
  }

  Widget _buildCompletionCircle(int index, bool isComplete, int completedCount, bool isEditing) {
    if (!isComplete) {
      return const CircleAvatar();
    }

    final pulse = _glowPulseStates[index] ?? false;
    return GestureDetector(
      onTap: isEditing ? null : () => _completeHomeCard(index, completedCount),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: pulse ? 0.6 : 1.0, end: pulse ? 1.0 : 0.6),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeInOut,
        onEnd: () {
          if (mounted) {
            setState(() {
              _glowPulseStates[index] = !pulse;
            });
          }
        },
        builder: (context, glow, child) {
          final baseColor = Color.lerp(
            Colors.green.shade700,
            Colors.green.shade300,
            glow,
          )!;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: baseColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: baseColor.withOpacity(0.65),
                  blurRadius: 14 * glow,
                  spreadRadius: 2 * glow,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          );
        },
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.linear,
            builder: (context, value, iconChild) {
              final clamped = value.clamp(0.0, 1.0);
              final rotation = Curves.easeOutBack.transform(clamped) * math.pi * 6;
              final scaleProgress = (clamped / 1.4).clamp(0.0, 1.0);
              final scale = 0.1 + (1.4 * Curves.easeOutCubic.transform(scaleProgress));
              return Transform.rotate(
                angle: rotation,
                child: Transform.scale(
                  scale: scale,
                  child: iconChild,
                ),
              );
            },
            child: const Icon(Icons.check, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }


  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items ||
        widget.shortTermItems != oldWidget.shortTermItems ||
        widget.sharedItems != oldWidget.sharedItems) {
      setState(() {
        _items = widget.items;
        _shortTermItems = widget.shortTermItems;
        _sharedItems = widget.sharedItems;
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

      body: Stack(
        children: [
          SafeArea(
            child: _items.isEmpty
                ? const Center(child: Text('No items yet'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                    itemCount: _items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                  final item = _items[index];
                  final String title = item['title'] as String? ?? '';
                  final List<Map<String, dynamic>> rawTasks =
                      (item['subNotes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                  final tasks = List<Map<String, dynamic>>.from(rawTasks);
                  final isComplete = _isCardComplete(tasks);
                  final isCompleting = _completingHomeCards.contains(index);
                  final completedCount = tasks.length;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                      alignment: Alignment.center,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 220),
                        opacity: isCompleting ? 0.0 : 1.0,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 280),
                          scale: isCompleting ? 0.0 : 1.0,
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
                                      _buildCompletionCircle(
                                        index,
                                        isComplete,
                                        completedCount,
                                        _editingCards.contains(index),
                                      ),
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
                                            children: (
                                              _expandedTaskCards.contains(index)
                                                  ? tasks
                                                  : tasks.take(3).toList()
                                            ).map((task) {
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
                                                        
                                                        // Sync back to source goal if applicable
                                                        final sourceType = _items[index]['_sourceType'] as String?;
                                                        if (sourceType != null && sourceType != 'none') {
                                                          final sourceIndex = _items[index]['_sourceIndex'] as int?;
                                                          if (sourceIndex != null) {
                                                            final sourceGoals = sourceType == 'longTerm' ? _sharedItems : _shortTermItems;
                                                            if (sourceIndex >= 0 && sourceIndex < sourceGoals.length) {
                                                              sourceGoals[sourceIndex]['subNotes'] = currentTasks;
                                                              if (sourceType == 'longTerm') {
                                                                widget.onSharedItemsChanged(sourceGoals);
                                                              } else {
                                                                widget.onShortTermItemsChanged(sourceGoals);
                                                              }
                                                            }
                                                          }
                                                        }
                                                        
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
                                        if (tasks.length > 3)
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  if (_expandedTaskCards.contains(index)) {
                                                    _expandedTaskCards.remove(index);
                                                  } else {
                                                    _expandedTaskCards.add(index);
                                                  }
                                                });
                                              },
                                              child: Text(
                                                _expandedTaskCards.contains(index) ? 'Show less' : 'Show all',
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => _showAddTaskDialog(),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTaskDialog() async {
    // First, show dialog to select goal category
    if (!mounted) return;
    String selectedCategory = 'longTerm';
    final goalCategory = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select goal type'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Add task to:'),
                  const SizedBox(height: 16),
                  RadioListTile<String>(
                    title: const Text('Long-term goal'),
                    value: 'longTerm',
                    groupValue: selectedCategory,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Short-term goal'),
                    value: 'shortTerm',
                    groupValue: selectedCategory,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('General tasks'),
                    value: 'none',
                    groupValue: selectedCategory,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value!;
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
                  onPressed: () => Navigator.pop(context, selectedCategory),
                  child: const Text('Next'),
                ),
              ],
            );
          },
        );
      },
    );

    if (goalCategory == null) return;

    // If "General tasks" is selected, skip to task details
    if (goalCategory == 'none') {
      await _showTaskDetailsDialog(null, null);
      return;
    }

    // Otherwise, show dialog to select which goal
    if (!mounted) return;
    final goals = goalCategory == 'longTerm' ? _sharedItems : _shortTermItems;
    if (goals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No goals available yet. Add a goal first.')),
      );
      return;
    }
    final selectedIndex = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select which goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                goals.length,
                (idx) => ListTile(
                  title: Text(goals[idx]['title'] as String? ?? 'Goal ${idx + 1}'),
                  onTap: () => Navigator.pop(context, idx),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (selectedIndex != null) {
      await _showTaskDetailsDialog(goalCategory, selectedIndex);
    }
  }

  Future<void> _showTaskDetailsDialog(String? category, int? goalIndex) async {
    // Show dialog to enter task details
    if (!mounted) return;
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
                    if (text.isNotEmpty) {
                      Navigator.pop(context, {
                        'text': text,
                        'taskType': selectedTaskType,
                      });
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (result != null) {
      setState(() {
        if (category == null) {
          // Add to general tasks (no goal)
          // Check if we already have a "general tasks" item
          var unattachedItem = _items.firstWhere(
            (item) => item['_type'] == 'none',
            orElse: () => {
              'title': "Today's General Tasks",
              '_type': 'none',
              'subNotes': <Map<String, dynamic>>[],
            },
          );

          if (!_items.contains(unattachedItem)) {
            _items.add(unattachedItem);
          }

          final taskIndex = _items.indexOf(unattachedItem);
          final currentTasks = (_items[taskIndex]['subNotes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          currentTasks.add({
            'text': result['text'],
            'taskType': result['taskType'] ?? 'temporary',
            'checked': false,
          });
          _items[taskIndex]['subNotes'] = currentTasks;
          widget.onItemsChanged(_items);
        } else {
          // Add to a long-term or short-term goal
          if (goalIndex == null) {
            return;
          }
          final sourceGoals = category == 'longTerm' ? _sharedItems : _shortTermItems;
          if (goalIndex < 0 || goalIndex >= sourceGoals.length) {
            return;
          }
          final currentTasks = (sourceGoals[goalIndex]['subNotes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          currentTasks.add({
            'text': result['text'],
            'taskType': result['taskType'] ?? 'temporary',
            'checked': false,
          });
          sourceGoals[goalIndex]['subNotes'] = currentTasks;

          // Update source
          if (category == 'longTerm') {
            widget.onSharedItemsChanged(sourceGoals);
          } else {
            widget.onShortTermItemsChanged(sourceGoals);
          }

          // Add to home page if not already there
          final goalItem = _items.firstWhere(
            (item) =>
                item['_sourceType'] == category &&
                item['_sourceIndex'] == goalIndex,
            orElse: () => {},
          );

          if (goalItem.isEmpty) {
            // Create a reference item in home page
            _items.add({
              'title': sourceGoals[goalIndex]['title'],
              '_sourceType': category,
              '_sourceIndex': goalIndex,
              'subNotes': sourceGoals[goalIndex]['subNotes'],
              'steps': sourceGoals[goalIndex]['steps'] ?? [],
              'progress': sourceGoals[goalIndex]['progress'] ?? 0,
            });
          } else {
            // Update the reference item
            final index = _items.indexOf(goalItem);
            _items[index]['subNotes'] = sourceGoals[goalIndex]['subNotes'];
          }

          widget.onItemsChanged(_items);
        }
      });
    }
  }
}