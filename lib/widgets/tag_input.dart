import 'package:flutter/material.dart';
import '../controller/journal_controller.dart';
import '../services/deepseek_service.dart';

class TagInputWidget extends StatefulWidget {
  final JournalController journalController;
  final Function(List<String>) onTagsChanged;

  const TagInputWidget({
    super.key,
    required this.journalController,
    required this.onTagsChanged,
  });

  @override
  State<TagInputWidget> createState() => _TagInputWidgetState();
}

class _TagInputWidgetState extends State<TagInputWidget> {
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();
  List<String> _currentTags = [];
  List<String> _suggestedTags = [];  bool _showSuggestions = false;
  bool _showInputField = false; // Add explicit state for input field visibility
  double _inputFieldWidth = 60.0; // Dynamic width for input field - start smaller
  final DeepseekService _deepseekService = DeepseekService();  @override
  void initState() {
    super.initState();
    _currentTags = List.from(widget.journalController.manualTags);
    _tagController.addListener(_onTagInputChanged);
    _tagFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _tagController.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }  void _onTagInputChanged() {
    final input = _tagController.text.trim();
    _updateInputFieldWidth(input);
    
    if (input.isNotEmpty && input.length >= 2) {
      _generateTagSuggestions(input);
      // Also trigger AI suggestions if journal has content
      if (widget.journalController.controller.text.trim().isNotEmpty) {
        _getAISuggestions();
      }
    } else {
      setState(() {
        _showSuggestions = false;
        _suggestedTags.clear();
      });
    }
  }
  void _updateInputFieldWidth(String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text.isEmpty ? '#tag' : text, // Use hint text for min width
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    // Calculate width with padding and some extra space
    // Start smaller for hint text: 60px min, 200px max, padding: 20px
    final baseWidth = text.isEmpty ? 40.0 : textPainter.width; // Smaller for hint
    final calculatedWidth = (baseWidth + 20).clamp(60.0, 200.0);
    
    if (calculatedWidth != _inputFieldWidth) {
      setState(() {
        _inputFieldWidth = calculatedWidth;
      });
    }
  }void _onFocusChanged() {
    setState(() {
      if (!_tagFocusNode.hasFocus) {
        _showSuggestions = false;
        _showInputField = false; // Hide input field when focus is lost
        _inputFieldWidth = 60.0; // Reset width when hiding input field
      }
    });
  }
  void _generateTagSuggestions(String input) {
    // Get suggestions from existing tags in all entries
    final existingTags = <String>{};
    for (final entry in widget.journalController.entries) {
      existingTags.addAll(entry.tags);
    }

    // Filter suggestions based on input
    final suggestions = existingTags
        .where((tag) => 
            tag.toLowerCase().contains(input.toLowerCase()) &&
            !_currentTags.contains(tag))
        .take(5)
        .toList();

    // Add some common tag suggestions if input is short
    if (input.length <= 3) {
      final commonTags = ['#work', '#personal', '#travel', '#family', '#goals', '#health', '#thoughts', '#memories'];
      suggestions.addAll(
        commonTags
            .where((tag) => 
                tag.toLowerCase().contains(input.toLowerCase()) &&
                !_currentTags.contains(tag) &&
                !suggestions.contains(tag))
            .take(3)
      );
    }

    setState(() {
      _suggestedTags = suggestions;
      _showSuggestions = suggestions.isNotEmpty;
    });
  }

  Future<void> _getAISuggestions() async {
    final text = widget.journalController.controller.text.trim();
    if (text.isEmpty) return;

    try {
      final existingTags = <String>{};
      for (final entry in widget.journalController.entries) {
        existingTags.addAll(entry.tags);
      }

      final aiSuggestions = await _deepseekService.suggestTags(text, existingTags.toList());
      
      // Filter out tags that are already added
      final filteredSuggestions = aiSuggestions
          .where((tag) => !_currentTags.contains(tag))
          .toList();

      setState(() {
        _suggestedTags = filteredSuggestions;
        _showSuggestions = filteredSuggestions.isNotEmpty;
      });
    } catch (e) {
      // Fallback to manual suggestions if AI fails
      _generateTagSuggestions('');
    }
  }
  void _addTag(String tag) {
    print('Debug: _addTag called with: "$tag"');
    if (tag.isEmpty) {
      print('Debug: Tag is empty, returning');
      return;
    }
    
    // Clean and format the tag
    String cleanTag = tag.trim();
    if (!cleanTag.startsWith('#')) {
      cleanTag = '#$cleanTag';
    }
    
    // Remove any extra # symbols
    cleanTag = cleanTag.replaceAll(RegExp(r'#+'), '#');
    print('Debug: Clean tag: "$cleanTag"');
      if (!_currentTags.contains(cleanTag) && cleanTag.length > 1) {
      print('Debug: Adding tag to list: $_currentTags');      setState(() {
        _currentTags.add(cleanTag);
        _tagController.clear();
        _showSuggestions = false;
        _suggestedTags.clear();
        _showInputField = false; // Hide input field after adding tag
        _inputFieldWidth = 60.0; // Reset to default width
      });
      print('Debug: Updated tags: $_currentTags');
      widget.onTagsChanged(_currentTags);
    } else {
      print('Debug: Tag not added - already exists or too short');
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _currentTags.remove(tag);
    });
    widget.onTagsChanged(_currentTags);
  }  void _onAddButtonPressed() {
    print('Debug: Add button pressed');
    final input = _tagController.text.trim();
    print('Debug: Input text: "$input"');
    
    if (input.isNotEmpty) {
      print('Debug: Adding tag: $input');
      _addTag(input);    } else {
      print('Debug: Input empty, showing input field and requesting focus');
      setState(() {
        _showInputField = true;
        _inputFieldWidth = 60.0; // Initialize with smaller default width
      });
      // Request focus after the widget is rebuilt
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tagFocusNode.requestFocus();
        // Update width for hint text
        _updateInputFieldWidth('');
      });
    }
  }  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    print('Debug: TagInputWidget build called. Current tags: $_currentTags');
    
    // Sync with controller's manual tags (e.g., after entry is saved and tags are cleared)
    if (widget.journalController.manualTags.isEmpty && _currentTags.isNotEmpty) {
      // Clear immediately without post-frame callback to fix UI not clearing after submission
      _currentTags.clear();
      _showInputField = false;
      _showSuggestions = false;
      _suggestedTags.clear();
      _tagController.clear();
      _inputFieldWidth = 60.0;
      print('Debug: Cleared tags in sync with controller');
    }      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Minimize vertical space
          children: [
        // Single scrollable row for tags, input, and suggestions
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
              children: [
                // Display current tags
                ..._currentTags.map((tag) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _buildTagChip(tag, theme),
                )),
                // Add tag button/input
                _buildAddTagButton(theme),
                // Inline suggestions with animation
                if (_showSuggestions && _suggestedTags.isNotEmpty) ...[
                  const SizedBox(width: 8),                  ..._suggestedTags.map((tag) => Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: _buildSuggestionChip(tag, theme),                  )),
                ],
              ],
            ),          ),
        ],
      ),
      );
  }

  Widget _buildTagChip(String tag, ThemeData theme) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _removeTag(tag),
            child: Icon(
              Icons.close,
              size: 14,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }  Widget _buildAddTagButton(ThemeData theme) {
    print('Debug: _buildAddTagButton called. showInputField: $_showInputField, hasFocus: ${_tagFocusNode.hasFocus}');
    return SizedBox(
      height: 28,
      child: _showInputField 
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: _inputFieldWidth,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _tagController,
                  focusNode: _tagFocusNode,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                  ),
                  decoration: InputDecoration(
                    hintText: '#tag',
                    hintStyle: TextStyle(
                      color: theme.hintColor,
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    isDense: true,
                  ),
                  onSubmitted: (value) {
                    print('Debug: TextField onSubmitted: $value');
                    _addTag(value);
                  },
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  print('Debug: Check button tapped');
                  _onAddButtonPressed();
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          )        : InkWell(
            onTap: () {
              print('Debug: Add tag button tapped (InkWell)');
              print('Debug: About to show input field and request focus');
              setState(() {
                _showInputField = true;
              });
              // Request focus after the widget is rebuilt
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _tagFocusNode.requestFocus();
                print('Debug: Focus requested in post frame callback');
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add,
                    size: 16,
                    color: theme.colorScheme.primary.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Add tag',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),          ),
    );
  }

  Widget _buildSuggestionChip(String tag, ThemeData theme) {
    return GestureDetector(
      onTap: () => _addTag(tag),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.secondary.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 12,
              color: theme.colorScheme.secondary.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              tag,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
