import 'package:flutter/material.dart';

class GoalsPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Function(List<Map<String, dynamic>>) onItemsChanged;
  final List<Map<String, dynamic>> shortTermItems;
  final Function(List<Map<String, dynamic>>) onShortTermItemsChanged;
  final void Function(double) onExperienceEarned;

  const GoalsPage({
    super.key,
    required this.items,
    required this.onItemsChanged,
    required this.shortTermItems,
    required this.onShortTermItemsChanged,
    required this.onExperienceEarned,
  });

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Goals'),
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
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.flag), text: 'Long-term'),
              Tab(icon: Icon(Icons.flag_outlined), text: 'Short-term'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            GoalListSection(
              key: const ValueKey('longTermGoals'),
              title: 'Long-term Goals',
              items: widget.items,
              onItemsChanged: widget.onItemsChanged,
              onGoalCompleted: widget.onExperienceEarned,
            ),
            GoalListSection(
              key: const ValueKey('shortTermGoals'),
              title: 'Short-term Goals',
              items: widget.shortTermItems,
              onItemsChanged: widget.onShortTermItemsChanged,
              onGoalCompleted: widget.onExperienceEarned,
            ),
          ],
        ),
      ),
    );
  }
}

class GoalListSection extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final Function(List<Map<String, dynamic>>) onItemsChanged;
  final void Function(double) onGoalCompleted;

  const GoalListSection({
    super.key,
    required this.title,
    required this.items,
    required this.onItemsChanged,
    required this.onGoalCompleted,
  });

  @override
  State<GoalListSection> createState() => _GoalListSectionState();
}

class _GoalListSectionState extends State<GoalListSection> with TickerProviderStateMixin {
  final Set<int> _editingCards = {};
  final Map<int, TextEditingController> _titleControllers = {};
  final Map<int, Set<int>> _selectedStepIndices = {};
  final Map<String, TextEditingController> _stepControllers = {};
  final Map<int, Map<String, dynamic>> _originalState = {};
  bool _glowPulse = false;
  final Set<int> _completingCards = {};

  List<Map<String, dynamic>> _toMapList(Object? value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  int _calculateProgress(List<Map<String, dynamic>> steps) {
    if (steps.isEmpty) return 0;
    final completed = steps.where((step) => step['checked'] == true).length;
    return ((completed / steps.length) * 100).round();
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
  Widget build(BuildContext context) {
    final items = widget.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  widget.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: items.isEmpty
                    ? Center(child: Text('No ${widget.title} yet'))
                    : PageView.builder(
                        padEnds: true,
                        pageSnapping: true,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final String title = item['title'] as String? ?? '';
                          final steps = _toMapList(item['steps']);
                          final int progress = _calculateProgress(steps);
                          final bool isCompleting = _completingCards.contains(index);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: SizedBox(
                              width: 300,
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
                                            _buildCompleteButton(progress, index, item),
                                          ],
                                        ),
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
                        final updatedItems = List<Map<String, dynamic>>.from(widget.items);
                        if (index >= 0 && index < updatedItems.length) {
                          updatedItems[index]['title'] = newTitle.trim();
                          widget.onItemsChanged(updatedItems);
                        }
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
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: null, end: progress / 100),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final percent = (value * 100).round();
        return Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percent < 50 ? Colors.orange : Colors.green,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$percent%',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
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
                  ? const Color.fromARGB(77, 33, 150, 243)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _toggleStepChecked(index, stepIndex),
                    child: Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: done ? Colors.green : Colors.blue,
                      size: 16,
                    ),
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

  void _completeGoal(int index, Map<String, dynamic> item) {
    if (_completingCards.contains(index)) {
      return;
    }
    final stockBonus = (item['stockProgress'] as num?)?.toDouble() ?? 0.0;
    widget.onGoalCompleted(stockBonus);
    setState(() {
      _completingCards.add(index);
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        final updatedItems = List<Map<String, dynamic>>.from(widget.items);
        if (index >= 0 && index < updatedItems.length) {
          updatedItems.removeAt(index);
        } else {
          updatedItems.removeWhere((element) => element['title'] == item['title']);
        }
        widget.onItemsChanged(updatedItems);
        _completingCards.remove(index);
        _editingCards.remove(index);
        _titleControllers[index]?.dispose();
        _titleControllers.remove(index);
        _selectedStepIndices.remove(index);
      });
    });
  }

  Widget _buildCompleteButton(int progress, int index, Map<String, dynamic> item) {
    final show = progress >= 100;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: show
          ? Padding(
              key: const ValueKey('complete-visible'),
              padding: const EdgeInsets.only(top: 8.0),
              child: Align(
                alignment: Alignment.center,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: _glowPulse ? 0.6 : 1.0,
                    end: _glowPulse ? 1.0 : 0.6,
                  ),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeInOut,
                  onEnd: () {
                    if (mounted) {
                      setState(() {
                        _glowPulse = !_glowPulse;
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
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: baseColor.withAlpha(166),
                            blurRadius: 14 * glow,
                            spreadRadius: 2 * glow,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: TextButton.icon(
                    onPressed: () => _completeGoal(index, item),
                    icon: const Icon(Icons.check, color: Colors.white, size: 18),
                    label: const Text(
                      'Complete',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox(key: ValueKey('complete-hidden')),
    );
  }

  void _toggleEdit(int index, String title) {
    setState(() {
      if (_editingCards.contains(index)) {
        final newTitle = _titleControllers[index]?.text.trim() ?? '';
        if (newTitle.isNotEmpty) {
          final updatedItems = List<Map<String, dynamic>>.from(widget.items);
          if (index >= 0 && index < updatedItems.length) {
            updatedItems[index]['title'] = newTitle;
            widget.onItemsChanged(updatedItems);
          }
        }
        _editingCards.remove(index);
        _titleControllers[index]?.dispose();
        _titleControllers.remove(index);
      } else {
        _editingCards.add(index);
        if (index < 0 || index >= widget.items.length) {
          return;
        }
        _originalState[index] = {
          'title': title,
          'steps': List<Map<String, dynamic>>.from(
            _toMapList(widget.items[index]['steps']),
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
        final updatedItems = List<Map<String, dynamic>>.from(widget.items);
        if (index >= 0 && index < updatedItems.length) {
          updatedItems.removeAt(index);
          widget.onItemsChanged(updatedItems);
        }
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
      final updatedItems = List<Map<String, dynamic>>.from(widget.items);
      if (index >= 0 && index < updatedItems.length) {
        final currentSteps = _toMapList(updatedItems[index]['steps']);
        if (stepIndex < currentSteps.length) {
          final prev = currentSteps[stepIndex]['checked'] == true;
          currentSteps[stepIndex]['checked'] = !prev;
          updatedItems[index]['steps'] = currentSteps;
          updatedItems[index]['progress'] = _calculateProgress(currentSteps);
          widget.onItemsChanged(updatedItems);
        }
      }
    });
  }

  void _deleteSelectedSteps(int index) {
    setState(() {
      final updatedItems = List<Map<String, dynamic>>.from(widget.items);
      if (index >= 0 && index < updatedItems.length) {
        final currentSteps = _toMapList(updatedItems[index]['steps']);
        final selectedSet = _selectedStepIndices[index] ?? {};
        final sortedIndices = selectedSet.toList()..sort((a, b) => b.compareTo(a));

        for (final stepIdx in sortedIndices) {
          if (stepIdx < currentSteps.length) {
            currentSteps.removeAt(stepIdx);
          }
        }

        updatedItems[index]['steps'] = currentSteps;
        updatedItems[index]['progress'] = _calculateProgress(currentSteps);
        widget.onItemsChanged(updatedItems);
        _selectedStepIndices[index]?.clear();
      }
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
        final updatedItems = List<Map<String, dynamic>>.from(widget.items);
        if (index >= 0 && index < updatedItems.length) {
          final currentSteps = _toMapList(updatedItems[index]['steps']);
          currentSteps.add({
            'text': result,
            'checked': false,
          });
          updatedItems[index]['steps'] = currentSteps;
          updatedItems[index]['progress'] = _calculateProgress(currentSteps);
          widget.onItemsChanged(updatedItems);
        }
      });
    }
  }

  Future<void> _showAddGoalDialog(BuildContext context) async {
    final titleController = TextEditingController();

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
                Navigator.pop(context, {
                  'title': title,
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
        final updatedItems = List<Map<String, dynamic>>.from(widget.items);
        updatedItems.add({
          'title': result['title'],
          'subNotes': <Map<String, dynamic>>[],
          'steps': result['steps'] ?? <Map<String, dynamic>>[],
          'progress': 0,
          'stockProgress': 0.0,
        });
        widget.onItemsChanged(updatedItems);
      });
    }
  }
}
