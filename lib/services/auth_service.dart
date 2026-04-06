import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_model.dart';
import 'api_constants.dart';

class AuthService extends ChangeNotifier {
  static const String _authKey = 'auth_data';
  
  AuthModel? _currentAuth;
  AuthModel? get currentAuth => _currentAuth;
  bool get isAuthenticated => _currentAuth != null && _currentAuth!.sessionId.isNotEmpty;

  // Initialize and load stored auth data
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final authData = prefs.getString(_authKey);
    if (authData != null) {
      try {
        _currentAuth = AuthModel.decode(authData);
        notifyListeners();
      } catch (e) {
        debugPrint('Error decoding stored auth: $e');
        await clearAuth();
      }
    }
  }

  // Handle Login
  Future<bool> login({
    required String db,
    required String login,
    required String password,
  }) async {
    final String baseUrl = ApiConstants.baseUrl.replaceAll('/api', '');
    final Uri url = Uri.parse('$baseUrl${ApiConstants.authenticate}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "params": {
            "db": db,
            "login": login,
            "password": password,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Auth Response JSON: $data');
        
        if (data['result'] != null) {
          AuthModel auth = AuthModel.fromJson(data);
          
          // ALWAYS extract from cookie if available, because Odoo JSON body
          // often returns the pre-login session ID instead of the authenticated one.
          final setCookie = response.headers['set-cookie'];
          if (setCookie != null) {
            final match = RegExp(r'session_id=([^;]+)').firstMatch(setCookie);
            if (match != null) {
               final sid = match.group(1)!;
               debugPrint('Auth Extracted Session ID from Header: $sid');
               // Rebuild model with the session ID from cookie
               auth = AuthModel(
                 uid: auth.uid,
                 name: auth.name,
                 username: auth.username,
                 companyId: auth.companyId,
                 partnerId: auth.partnerId,
                 sessionId: sid,
                 db: auth.db,
                 lang: auth.lang,
                 tz: auth.tz,
               );
            }
          }
          
          _currentAuth = auth;
          debugPrint('Auth Active Session ID: ${_currentAuth?.sessionId}');
          
          await _saveAuth(_currentAuth!);
          notifyListeners();
          return true;
        } else if (data['error'] != null) {
          debugPrint('Login error: ${data['error']}');
        }
      }
      debugPrint('Failed to authenticate: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Auth exception: $e');
      return false;
    }
  }

  // Clear session (Logout)
  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
    _currentAuth = null;
    notifyListeners();
  }

  // Private helper to save to local storage
  Future<void> _saveAuth(AuthModel auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authKey, auth.encode());
  }
}
