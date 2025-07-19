import 'dart:convert';

import 'package:client/features/home/view/api_constants.dart';
import 'package:client/features/playlist/models/song.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, String>> _getAuthHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  final headers = <String, String>{
    'Content-Type': 'application/json',
  };

  if (token != null && token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
  }

  return headers;
}

class PlaylistService {
  static Future<Map<String, String>> getAuthHeaders() async {
    return await _getAuthHeaders();
  }
}
