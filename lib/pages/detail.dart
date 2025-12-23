import 'package:flutter/material.dart';

class DetailPage extends StatefulWidget {
  final String item;
  final int index;
  const DetailPage({super.key, required this.item, required this.index});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late TextEditingController _controller;
  late FocusNode _titleFocusNode;
  bool _isEditing = false;
  void _onControllerChanged() => setState(() {});
  final List<Map<String, dynamic>> _subNotes = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item);
    _titleFocusNode = FocusNode();
    _controller.addListener(_onControllerChanged);
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
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, {
          'index': widget.index,
          'title': _controller.text,
          'subNotes': _subNotes,
        });
        return false;
      },
      child: Scaffold(
      appBar: AppBar(
        titleSpacing: 0.0,
        centerTitle: false,
        title: _isEditing
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
              ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (!_isEditing) {
                setState(() {
                  _isEditing = true;
                });
                _titleFocusNode.requestFocus();
              } else {
                _save();
              }
            },
            tooltip: _isEditing ? 'Save' : 'Edit',
          ),
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
            const SizedBox(),
            const SizedBox(height: 12),
            const Text('Tasks'),
            const SizedBox(height: 8),
            Expanded(
                child: _subNotes.isEmpty
                  ? const Center(child: Text('No tasks yet'))
                  : ListView.separated(
                      itemCount: _subNotes.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final note = _subNotes[index];
                        return ListTile(
                          title: Text(note['text'] as String),
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
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isEditing
          ? FloatingActionButton(
              onPressed: () async {
                final result = await showDialog<String?>(
                  context: context,
                  builder: (context) {
                    final TextEditingController t = TextEditingController();
                    return AlertDialog(
                      title: const Text('Add task'),
                      content: TextField(controller: t),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, t.text.trim()), child: const Text('Add')),
                      ],
                    );
                  },
                );
                if (result != null && result.isNotEmpty) {
                  setState(() {
                    _subNotes.add({'text': result, 'checked': false});
                  });
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      ),
    );
  }
}

