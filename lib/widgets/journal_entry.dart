import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/entry.dart';
import '../utils/text_scale_controller.dart';
import 'custom_image_viewer.dart';

class JournalEntryWidget extends StatefulWidget {
  final Entry entry;
  final void Function(Entry) onToggleFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onInsight;
  final bool Function()? isSelectionMode;
  final VoidCallback? onToggleSelection;
  final String? searchTerm;

  const JournalEntryWidget({
    super.key,
    required this.entry,
    required this.onToggleFavorite,
    this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.onInsight,
    this.isSelectionMode,
    this.onToggleSelection,
    this.searchTerm,
  });

  @override
  State<JournalEntryWidget> createState() => _JournalEntryWidgetState();
}

class _JournalEntryWidgetState extends State<JournalEntryWidget> {
  double _baseScale = 1.0;
  late ScrollController _tagsScrollController;
  bool _showStartFade = false;
  Offset? _lastFocalPoint;
  RenderBox? _widgetRenderBox;

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = TextScaleController.instance.scale.value;
    _lastFocalPoint = details.focalPoint;
    // Capture the render box for position calculations
    _widgetRenderBox = context.findRenderObject() as RenderBox?;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final newScale = _baseScale * details.scale;
    final oldScale = TextScaleController.instance.scale.value;
    
    // Calculate the focal point relative to the widget
    if (_widgetRenderBox != null && _lastFocalPoint != null) {
      final localFocalPoint = _widgetRenderBox!.globalToLocal(_lastFocalPoint!);
      
      // Set the new scale
      TextScaleController.instance.setScale(newScale);
        // Calculate scroll offset adjustment to keep focal point stable
      final scaleDelta = newScale - oldScale;
      if (scaleDelta.abs() > 0.001) { // Only adjust for meaningful scale changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Adjust scroll position based on focal point to keep it stable
          final scrollController = Scrollable.of(context).widget.controller;
          if (scrollController != null && scrollController.hasClients) {
            final currentOffset = scrollController.offset;
            final focalRatio = localFocalPoint.dy / (_widgetRenderBox!.size.height);
            final offsetAdjustment = focalRatio * 50 * scaleDelta; // Adjust multiplier as needed
            
            final newOffset = currentOffset + offsetAdjustment;
            scrollController.animateTo(
              newOffset,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } else {
      // Fallback to simple scaling
      TextScaleController.instance.setScale(newScale);
    }
  }

  void _onTagsScroll() {
    if (_tagsScrollController.hasClients) {
      setState(() {
        _showStartFade = _tagsScrollController.offset > 0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tagsScrollController = ScrollController();
    _tagsScrollController.addListener(_onTagsScroll);
    TextScaleController.instance.scale.addListener(_onScaleChanged);
  }

  @override
  void dispose() {
    _tagsScrollController.removeListener(_onTagsScroll);
    _tagsScrollController.dispose();
    TextScaleController.instance.scale.removeListener(_onScaleChanged);
    super.dispose();
  }

  void _onScaleChanged() {
    setState(() {}); // Rebuild on global scale change
  }  Widget _buildTagsBar(BuildContext context, TextStyle? style) {
    final theme = Theme.of(context);
    // When selected, blend the highlight color with the scaffold background
    // to match the actual visual appearance
    final backgroundColor = widget.entry.isSelected 
        ? Color.alphaBlend(theme.highlightColor, theme.scaffoldBackgroundColor)
        : theme.scaffoldBackgroundColor;
    
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: SingleChildScrollView(
            controller: _tagsScrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < widget.entry.tags.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Text(
                    widget.entry.tags[i],
                    style: style,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
        // Start fade (only when scrolled)
        if (_showStartFade)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 16,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      backgroundColor,
                      backgroundColor.withOpacity(0.9),
                      backgroundColor.withOpacity(0.6),
                      backgroundColor.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),
        // End fade (always visible)
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 16,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    backgroundColor.withOpacity(0.0),
                    backgroundColor.withOpacity(0.6),
                    backgroundColor.withOpacity(0.9),
                    backgroundColor,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageViewer(BuildContext context) {
    ImageProvider? imageProvider;
    String? heroTag;
    
    if (widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty) {
      // Use network image for Firebase stored images
      imageProvider = CachedNetworkImageProvider(widget.entry.imageUrl!);
      heroTag = 'entry_image_${widget.entry.localId}_${widget.entry.imageUrl!}';
    } else if (widget.entry.localImagePath != null && widget.entry.localImagePath!.isNotEmpty) {
      // Use file image for local images
      imageProvider = FileImage(File(widget.entry.localImagePath!));
      heroTag = 'entry_image_${widget.entry.localId}_${widget.entry.localImagePath!}';
    }
    
    if (imageProvider != null) {
      showCustomImageViewer(
        context, 
        imageProvider,
        heroTag: heroTag,
      );
    }
  }  void _showContextMenu(BuildContext context, [Offset? globalPosition]) {
    // If in selection mode, toggle selection instead of showing context menu
    if (widget.isSelectionMode?.call() == true) {
      widget.onToggleSelection?.call();
      return;
    }

    final theme = Theme.of(context);
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox box = context.findRenderObject() as RenderBox;
    
    // Use provided position or default to center of the widget
    final Offset position = globalPosition ?? box.localToGlobal(box.size.center(Offset.zero));
    
    final RelativeRect relativePosition = RelativeRect.fromRect(
      Rect.fromPoints(position, position),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: relativePosition,
      elevation: 6,
      color: theme.brightness == Brightness.dark 
          ? const Color(0xFF2A2A2A) 
          : Colors.white,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: theme.brightness == Brightness.dark 
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      constraints: const BoxConstraints(
        minWidth: 140,
        maxWidth: 160,
      ),items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'insight',
          height: 36,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: theme.iconTheme.color?.withOpacity(0.8),
              ),
              const SizedBox(width: 10),
              Text(
                'AI Insight',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'edit',
          height: 36,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_outlined,
                size: 16,
                color: theme.iconTheme.color?.withOpacity(0.8),
              ),
              const SizedBox(width: 10),
              Text(
                'Edit',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'delete',
          height: 36,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.delete_outline,
                size: 16,
                color: Colors.red,
              ),
              const SizedBox(width: 10),
              Text(
                'Delete',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'insight':
            widget.onInsight?.call();
            break;
          case 'edit':
            widget.onEdit?.call();
            break;
          case 'delete':
            widget.onDelete?.call();
            break;
        }
      }
    });
  }

  Widget _buildHighlightedText(
    BuildContext context,
    String text,
    String? searchTerm,
    TextStyle? baseStyle,
  ) {
    if (searchTerm == null || searchTerm.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final theme = Theme.of(context);
    final highlightColor = theme.brightness == Brightness.dark
        ? Colors.yellow.withOpacity(0.3)
        : Colors.yellow.withOpacity(0.5);

    final matches = searchTerm.toLowerCase();
    final textLower = text.toLowerCase();
    final spans = <TextSpan>[];
    int lastMatchEnd = 0;

    for (int i = 0; i <= textLower.length - matches.length; i++) {
      if (textLower.substring(i, i + matches.length) == matches) {
        // Add non-matched text before this match
        if (i > lastMatchEnd) {
          spans.add(TextSpan(
            text: text.substring(lastMatchEnd, i),
            style: baseStyle,
          ));
        }

        // Add matched text with highlight
        spans.add(TextSpan(
          text: text.substring(i, i + matches.length),
          style: baseStyle?.copyWith(
            backgroundColor: highlightColor,
            fontWeight: FontWeight.bold,
          ),
        ));

        lastMatchEnd = i + matches.length;
        i += matches.length - 1;
      }
    }

    // Add remaining non-matched text
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: baseStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: widget.entry.animController,
        curve: Curves.easeOut,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(widget.entry.animController),        child: GestureDetector(
          onTap: () {
            // If in selection mode, toggle selection on tap
            if (widget.isSelectionMode?.call() == true) {
              widget.onToggleSelection?.call();
            } else {
              // Show context menu on regular tap when not in selection mode
              _showContextMenu(context);
            }
          },
          onLongPress: widget.onLongPress,
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          behavior: HitTestBehavior.opaque, // Improve hit detection
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutQuart,
            padding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
            decoration: BoxDecoration(
              color: widget.entry.isSelected
                  ? theme.highlightColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(
                widget.entry.isSelected ? 6.0 : 0.0,
              ),
            ),
            transform: Matrix4.identity()..scale(
              widget.entry.isSelected ? 0.97 : 1.0,
            ),
            transformAlignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [                Builder(
                  builder: (context) {
                    final scale = TextScaleController.instance.scale.value;
                    final regularStyle = theme.textTheme.bodySmall?.copyWith(
                      fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12.0) * scale,
                    );
                    final timestampStyle = regularStyle?.copyWith(
                      fontSize: ((regularStyle.fontSize ?? 12.0) + 1.0),
                    );
                      // Build left side metadata (tags and mood)
                    Widget tagsWidget = const SizedBox.shrink();
                    Widget moodWidget = const SizedBox.shrink();
                    
                    if (widget.entry.tags.isNotEmpty) {
                      tagsWidget = Flexible(
                        child: _buildTagsBar(context, regularStyle),
                      );
                    }
                    
                    if (widget.entry.mood?.isNotEmpty == true) {
                      moodWidget = Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(' • ', style: regularStyle),
                            Text(
                              widget.entry.mood!,
                              style: regularStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        // Left side: tags and mood
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              if (widget.entry.tags.isNotEmpty) tagsWidget,
                              if (widget.entry.mood?.isNotEmpty == true) moodWidget,
                            ],
                          ),
                        ),
                        // Right side: timestamp
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(widget.entry.timestamp, style: timestampStyle),
                        ),
                      ],
                    );
                  },
                ),if ((widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty) ||
                    (widget.entry.localImagePath != null && widget.entry.localImagePath!.isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0, bottom: 2.5),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 200 * TextScaleController.instance.scale.value,
                        minWidth: double.infinity,
                      ),                      child: GestureDetector(
                        onTap: () => _showImageViewer(context),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: Hero(
                            tag: widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty
                                ? 'entry_image_${widget.entry.localId}_${widget.entry.imageUrl!}'
                                : 'entry_image_${widget.entry.localId}_${widget.entry.localImagePath!}',
                            child: widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: widget.entry.imageUrl!,
                                    key: ValueKey(widget.entry.imageUrl!),
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) {
                                      final theme = Theme.of(context);
                                      final isDark = theme.brightness == Brightness.dark;
                                      final baseColor = isDark ? Colors.grey[900]! : Colors.grey[200]!;
                                      final highlightColor = isDark ? Colors.grey[850]! : Colors.grey[100]!;

                                      return Shimmer.fromColors(
                                        baseColor: baseColor,
                                        highlightColor: highlightColor,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: baseColor,
                                            borderRadius: BorderRadius.circular(4.0),
                                          ),
                                        ),
                                      );
                                    },
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error),
                                  )
                                : Image.file(
                                    File(widget.entry.localImagePath!),
                                    key: ValueKey(widget.entry.localImagePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (
                                      BuildContext context,
                                      Object error,
                                      StackTrace? stackTrace,
                                    ) {
                                      return Container(
                                        height: 100,
                                        color: Colors.grey[300],
                                        child: Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Colors.grey[600],
                                            size: 40,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                    ),                  ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _buildHighlightedText(
                          context,
                          widget.entry.text,
                          widget.searchTerm,
                          theme.textTheme.bodyMedium?.copyWith(
                            fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14.0) * TextScaleController.instance.scale.value,
                          ),
                        ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => widget.onToggleFavorite(widget.entry),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          widget.entry.isFavorite
                              ? Icons.bookmark
                              : Icons.bookmark_outline,
                          size: 18,
                          color: widget.entry.isFavorite
                              ? Colors.amber
                              : theme.iconTheme.color,
                        ),
                      ),
                    ),                  ],
                ),                // Add a thin separator between entries
                Container(
                  height: 0.5,
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8.0),
                  color: theme.dividerColor.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
