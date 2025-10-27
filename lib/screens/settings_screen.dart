import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _swipeDeleteEnabled = true;
  bool _swipeFavoriteEnabled = true;
  bool _deleteConfirmationEnabled = true;
  bool _closeOnScroll = true;
  String _motion = 'scroll';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final deleteEnabled = await PreferencesService.isSwipeDeleteEnabled();
    final favEnabled = await PreferencesService.isSwipeFavoriteEnabled();
    final confirmDelete = await PreferencesService.isDeleteConfirmationEnabled();
    final closeOnScroll = await PreferencesService.isCloseOnScrollEnabled();
    final motion = await PreferencesService.getSlidableMotion();
    if (!mounted) return;
    setState(() {
      _swipeDeleteEnabled = deleteEnabled;
      _swipeFavoriteEnabled = favEnabled;
      _deleteConfirmationEnabled = confirmDelete;
      _closeOnScroll = closeOnScroll;
      _motion = motion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Swipe Actions', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Swipe left to reveal Delete'),
            value: _swipeDeleteEnabled,
            onChanged: (v) async {
              await PreferencesService.setSwipeDeleteEnabled(v);
              setState(() => _swipeDeleteEnabled = v);
            },
          ),
          SwitchListTile(
            title: const Text('Require confirmation when deleting'),
            value: _deleteConfirmationEnabled,
            onChanged: (v) async {
              await PreferencesService.setDeleteConfirmationEnabled(v);
              setState(() => _deleteConfirmationEnabled = v);
            },
          ),
          const Divider(height: 24),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('Swipe Right Action', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Swipe right to reveal Favorite'),
            value: _swipeFavoriteEnabled,
            onChanged: (v) async {
              await PreferencesService.setSwipeFavoriteEnabled(v);
              setState(() => _swipeFavoriteEnabled = v);
            },
          ),
          const Divider(height: 24),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('Behavior'),
          ),
          SwitchListTile(
            title: const Text('Auto-close while scrolling'),
            value: _closeOnScroll,
            onChanged: (v) async {
              await PreferencesService.setCloseOnScrollEnabled(v);
              setState(() => _closeOnScroll = v);
            },
          ),
          ListTile(
            title: const Text('Animation style'),
            subtitle: Text(_motion == 'scroll' ? 'Swift and sharp' : 'Stretchy'),
            onTap: () async {
              final choice = await showModalBottomSheet<String>(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        title: const Text('Swift and sharp'),
                        value: 'scroll',
                        groupValue: _motion,
                        onChanged: (v) => Navigator.pop(ctx, v),
                      ),
                      RadioListTile<String>(
                        title: const Text('Stretchy'),
                        value: 'stretch',
                        groupValue: _motion,
                        onChanged: (v) => Navigator.pop(ctx, v),
                      ),
                    ],
                  ),
                ),
              );
              if (choice != null) {
                await PreferencesService.setSlidableMotion(choice);
                if (!mounted) return;
                setState(() => _motion = choice);
              }
            },
            trailing: const Icon(Icons.chevron_right),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

