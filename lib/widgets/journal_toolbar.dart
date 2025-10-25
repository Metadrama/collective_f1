import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:collective/constant/size.dart';
import 'package:collective/constant/colors.dart';
import '../services/auth_manager.dart';
import '../screens/auth_screen.dart';
import '../controller/journal_controller.dart';

class JournalToolbar extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onToggleSearch;  final VoidCallback onToggleFavorites;
  final VoidCallback onOpenDatePicker;
  final VoidCallback onOpenAnalytics;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final SyncStatus syncStatus;  const JournalToolbar({
    super.key,
    required this.isSearching,
    required this.onToggleSearch,
    required this.onToggleFavorites,
    required this.onOpenDatePicker,
    required this.onOpenAnalytics,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.syncStatus,
  });

  Widget _buildSyncStatusIcon(BuildContext context) {
    late IconData iconData;
    late Color iconColor;
    bool shouldAnimate = false;
    late String statusText;

    switch (syncStatus) {
      case SyncStatus.synced:
        iconData = Icons.cloud_done_outlined;
        iconColor = Colors.green;
        statusText = 'Synced';
        break;
      case SyncStatus.syncing:
        iconData = Icons.sync_outlined;
        iconColor = Colors.orange;
        shouldAnimate = true;
        statusText = 'Syncing...';
        break;
      case SyncStatus.offline:
        iconData = Icons.cloud_off_outlined;
        iconColor = Colors.grey;
        statusText = 'Offline';
        break;
      case SyncStatus.error:
        iconData = Icons.error_outline;
        iconColor = Colors.red;
        statusText = 'Sync Error';
        break;
    }

    Widget iconWidget = Icon(
      iconData,
      color: iconColor,
      size: SizeConstants.iconSmall,
    );
    if (shouldAnimate) {
      iconWidget = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(seconds: 1),
        builder: (context, value, child) {
          return Transform.rotate(
            angle: value * 6.28319, // 2*pi
            child: child,
          );
        },
        child: iconWidget,
      );
    }

    return Tooltip(
      message: statusText,
      waitDuration: const Duration(milliseconds: 200),
      showDuration: const Duration(seconds: 2),
      triggerMode: TooltipTriggerMode.tap,
      child: iconWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isSearching) ...[            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/logo/collective_logo.svg',
                  height: 20,
                  width: 20,
                  colorFilter: ColorFilter.mode(
                    isDarkTheme ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 5),
                Text('collective', style: theme.textTheme.titleMedium?.copyWith(fontSize: 20)),
                const SizedBox(width: 5.0),
                _buildSyncStatusIcon(context),
              ],
            ),
          ],
          if (isSearching)            Expanded(
              child: SizedBox(
                height: 32,
                child: TextField(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  onChanged: onSearchChanged,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontSize: SizeConstants.textMedium,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search entries...',
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      color: (isDarkTheme ? Colors.white : Colors.black)
                          .withOpacity(0.5),
                      fontSize: SizeConstants.textMedium,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        SizeConstants.borderRadiusSmall,
                      ),
                      borderSide: BorderSide(
                        color: (isDarkTheme ? Colors.white : Colors.black)
                            .withOpacity(0.3),
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        SizeConstants.borderRadiusSmall,
                      ),
                      borderSide: BorderSide(
                        color: (isDarkTheme ? Colors.white : Colors.black)
                            .withOpacity(0.3),
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        SizeConstants.borderRadiusSmall,
                      ),
                      borderSide: BorderSide(
                        color:
                            theme
                                .colorScheme
                                .primary, // Use primary color for focus
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                    ),
                    suffixIcon:
                      searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: SizeConstants.iconSmall,
                              color: (isDarkTheme ? Colors.white : Colors.black).withOpacity(0.6),
                            ),
                            onPressed: () {
                              searchController.clear();
                              onSearchChanged('');
                            },
                          )
                        : null,
                  ),
                  cursorColor: theme.colorScheme.primary,
                ),
              ),
            ),          Row(
            children: [
              if (!isSearching)
                IconButton(
                  icon: const Icon(
                    Icons.calendar_today,
                    size: SizeConstants.iconMedium,
                  ),
                  onPressed: onOpenDatePicker,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              if (!isSearching)
                IconButton(
                  icon: const Icon(
                    Icons.analytics_outlined,
                    size: SizeConstants.iconMedium,
                  ),
                  onPressed: onOpenAnalytics,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              if (isSearching)
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: SizeConstants.iconMedium,
                  ),
                  onPressed: onToggleSearch,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              if (!isSearching)
                PopupMenuButton(
                  icon: const Icon(
                    Icons.more_vert,
                    size: SizeConstants.iconMedium,
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'search',
                      child: Row(
                        children: [
                          Icon(Icons.search, size: 20),
                          SizedBox(width: 12),
                          Text('Search'),
                        ],
                      ),
                    ),                    const PopupMenuItem(
                      value: 'favorites',
                      child: Row(
                        children: [
                          Icon(Icons.bookmark_border, size: 20),
                          SizedBox(width: 12),
                          Text('Favorites'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20),
                          SizedBox(width: 12),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],                  onSelected: (value) async {
                    switch (value) {
                      case 'search':
                        onToggleSearch();
                        break;
                      case 'favorites':
                        onToggleFavorites();
                        break;
                      case 'logout':
                        await authManager.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          );
                        }
                        break;
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
