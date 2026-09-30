import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/values/app_constants.dart';
import '../models/user_model.dart';

/// Persistent local storage service using SharedPreferences.
/// Works seamlessly across Web (localStorage) and Mobile (NSUserDefaults / SharedPreferences).
class StorageService extends GetxService {
  late SharedPreferences _prefs;

  /// Asynchronous initialization called before runApp
  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  // -------------------------------------------------------------
  // AUTH TOKEN & REFRESH TOKEN
  // -------------------------------------------------------------
  Future<bool> saveToken(String token) async {
    return await _prefs.setString(AppConstants.keyAuthToken, token);
  }

  String? getToken() {
    return _prefs.getString(AppConstants.keyAuthToken);
  }

  bool get hasToken => getToken() != null && getToken()!.isNotEmpty;

  Future<bool> saveRefreshToken(String refreshToken) async {
    return await _prefs.setString(AppConstants.keyRefreshToken, refreshToken);
  }

  String? getRefreshToken() {
    return _prefs.getString(AppConstants.keyRefreshToken);
  }

  bool get hasRefreshToken => getRefreshToken() != null && getRefreshToken()!.isNotEmpty;

  Future<bool> removeRefreshToken() async {
    return await _prefs.remove(AppConstants.keyRefreshToken);
  }

  Future<bool> removeToken() async {
    await removeRefreshToken();
    return await _prefs.remove(AppConstants.keyAuthToken);
  }

  // -------------------------------------------------------------
  // USER PROFILE
  // -------------------------------------------------------------
  Future<bool> saveUser(UserModel user) async {
    final String userJson = jsonEncode(user.toJson());
    return await _prefs.setString(AppConstants.keyUserData, userJson);
  }

  UserModel? getUser() {
    final String? userJson = _prefs.getString(AppConstants.keyUserData);
    if (userJson == null || userJson.isEmpty) return null;
    try {
      final Map<String, dynamic> map = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<bool> removeUser() async {
    return await _prefs.remove(AppConstants.keyUserData);
  }

  // -------------------------------------------------------------
  // REMEMBER ME & SAVED CREDENTIALS
  // -------------------------------------------------------------
  Future<bool> setRememberMe(bool value) async {
    return await _prefs.setBool(AppConstants.keyRememberMe, value);
  }

  bool get isRememberMe => _prefs.getBool(AppConstants.keyRememberMe) ?? false;

  Future<bool> saveEmail(String email) async {
    return await _prefs.setString(AppConstants.keySavedEmail, email);
  }

  String? getSavedEmail() {
    return _prefs.getString(AppConstants.keySavedEmail);
  }

  Future<bool> saveUserId(String userId) async {
    return await _prefs.setString(AppConstants.keySavedEmail, userId);
  }

  String? getSavedUserId() {
    return _prefs.getString(AppConstants.keySavedEmail);
  }

  // -------------------------------------------------------------
  // ACTIVE SELECTED GAUSHALA
  // -------------------------------------------------------------
  Future<bool> saveSelectedGaushalaId(String gaushalaId) async {
    return await _prefs.setString(AppConstants.keySelectedGaushalaId, gaushalaId.trim());
  }

  String? getSelectedGaushalaId() {
    return _prefs.getString(AppConstants.keySelectedGaushalaId);
  }

  Future<bool> removeSelectedGaushalaId() async {
    return await _prefs.remove(AppConstants.keySelectedGaushalaId);
  }

  // -------------------------------------------------------------
  // THEME PREFERENCE
  // -------------------------------------------------------------
  Future<bool> setDarkMode(bool isDark) async {
    return await _prefs.setBool(AppConstants.keyIsDarkMode, isDark);
  }

  bool get isDarkMode => _prefs.getBool(AppConstants.keyIsDarkMode) ?? false;

  // -------------------------------------------------------------
  // CLEAR ALL DATA
  // -------------------------------------------------------------
  Future<bool> clearAll() async {
    final isDark = isDarkMode;
    final success = await _prefs.clear();
    // Preserve theme preference across logouts
    await setDarkMode(isDark);
    return success;
  }
}
