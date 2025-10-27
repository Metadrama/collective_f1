import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _swipeDeleteEnabledKey = 'swipe_delete_enabled';
  static const _swipeFavoriteEnabledKey = 'swipe_favorite_enabled';
  static const _deleteConfirmationEnabledKey = 'delete_confirmation_enabled';
  static const _slidableCloseOnScrollKey = 'slidable_close_on_scroll';
  static const _slidableMotionKey = 'slidable_motion'; // 'scroll' | 'stretch'

  static Future<bool> isSwipeDeleteEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_swipeDeleteEnabledKey) ?? true;
  }

  static Future<void> setSwipeDeleteEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_swipeDeleteEnabledKey, value);
  }

  static Future<bool> isSwipeFavoriteEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_swipeFavoriteEnabledKey) ?? true;
  }

  static Future<void> setSwipeFavoriteEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_swipeFavoriteEnabledKey, value);
  }

  static Future<bool> isDeleteConfirmationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_deleteConfirmationEnabledKey) ?? true;
  }

  static Future<void> setDeleteConfirmationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_deleteConfirmationEnabledKey, value);
  }

  static Future<bool> isCloseOnScrollEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_slidableCloseOnScrollKey) ?? true;
  }

  static Future<void> setCloseOnScrollEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_slidableCloseOnScrollKey, value);
  }

  static Future<String> getSlidableMotion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_slidableMotionKey) ?? 'scroll';
  }

  static Future<void> setSlidableMotion(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_slidableMotionKey, value);
  }
}

