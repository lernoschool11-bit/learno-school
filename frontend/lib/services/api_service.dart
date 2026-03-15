import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== AUTH ====================
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers(null),
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await saveToken(data['token']);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    String? nationalId,
    required String dob,
    required String username,
    required String email,
    required String password,
    required String role,
    required String school,
    String? grade,
    String? section,
    List<String>? subjects,
    List<Map<String, String>>? classes,
  }) async {
    try {
      final body = {
        'fullName': fullName,
        'dob': dob,
        'username': username,
        'email': email,
        'password': password,
        'role': role,
        'school': school,
        if (nationalId != null && nationalId.isNotEmpty) 'nationalId': nationalId,
        if (grade != null) 'grade': grade,
        if (section != null) 'section': section,
        if (subjects != null) 'subjects': subjects,
        if (classes != null) 'classes': classes,
      };
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers(null),
        body: jsonEncode(body),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Register error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception("Failed to load profile");
    } catch (e) {
      debugPrint('Profile error: $e');
      throw Exception('Network error');
    }
  }

  // ==================== UPDATE PROFILE ====================
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? username,
    String? email,
    String? avatarUrl,
  }) async {
    try {
      final token = await getToken();
      final body = {
        if (fullName != null) 'fullName': fullName,
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      };
      final response = await http.put(
        Uri.parse('$baseUrl/auth/update-profile'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'فشل تحديث البيانات');
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: _headers(token),
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Change password error: $e');
      return false;
    }
  }

  // ==================== UPLOAD AVATAR ====================
  Future<String?> uploadAvatar(Uint8List bytes, String fileName) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('$baseUrl/upload');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: MediaType.parse('image/jpeg'),
      ));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);
      if (response.statusCode == 200) return data['url'];
      return null;
    } catch (e) {
      debugPrint('Upload avatar error: $e');
      return null;
    }
  }

  // ==================== POSTS ====================
  Future<List<PostModel>> getPosts() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/posts/feed'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PostModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load posts');
    } catch (e) {
      debugPrint('Get posts error: $e');
      throw Exception('Network error');
    }
  }

  Future<List<PostModel>> searchPosts(String query) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/posts/feed'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final posts = data.map((json) => PostModel.fromJson(json)).toList();
        return posts.where((p) =>
          p.content.toLowerCase().contains(query.toLowerCase()) ||
          p.title.toLowerCase().contains(query.toLowerCase()) ||
          p.authorName.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Search error: $e');
      return [];
    }
  }

  Future<bool> createPost(String content) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: _headers(token),
        body: jsonEncode({'content': content, 'type': 'TEXT', 'title': 'New Post'}),
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Create post error: $e');
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: _headers(token),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Delete post error: $e');
      return false;
    }
  }

  // ==================== LIKES ====================
  Future<Map<String, dynamic>> toggleLike(String postId) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/like'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'isLiked': false, 'likesCount': 0};
    } catch (e) {
      debugPrint('Toggle like error: $e');
      return {'isLiked': false, 'likesCount': 0};
    }
  }

  // ==================== COMMENTS ====================
  Future<List<CommentModel>> getComments(String postId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId/comments'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((c) => CommentModel.fromJson(c)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get comments error: $e');
      return [];
    }
  }

  Future<CommentModel?> addComment(String postId, String content) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/comments'),
        headers: _headers(token),
        body: jsonEncode({'content': content}),
      );
      if (response.statusCode == 201) {
        return CommentModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Add comment error: $e');
      return null;
    }
  }

  Future<bool> deleteComment(String postId, String commentId) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$postId/comments/$commentId'),
        headers: _headers(token),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Delete comment error: $e');
      return false;
    }
  }

  // ==================== USERS ====================
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to load user profile');
    } catch (e) {
      debugPrint('Get user by id error: $e');
      throw Exception('Network error');
    }
  }

  Future<Map<String, dynamic>> toggleFollow(String userId) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/follow'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'isFollowing': false, 'followersCount': 0};
    } catch (e) {
      debugPrint('Toggle follow error: $e');
      return {'isFollowing': false, 'followersCount': 0};
    }
  }

  // ==================== SEARCH ====================
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/search?q=${Uri.encodeComponent(query)}'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((u) => Map<String, dynamic>.from(u)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Search users error: $e');
      return [];
    }
  }

  // ==================== COMMUNITY ====================
  Future<Map<String, dynamic>> getCommunity() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/community'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception("Failed to load community");
    } catch (e) {
      debugPrint('Community error: $e');
      throw Exception('Network error');
    }
  }

  // ==================== NOTIFICATIONS ====================
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((n) => Map<String, dynamic>.from(n)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get notifications error: $e');
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Get unread count error: $e');
      return 0;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final token = await getToken();
      await http.put(
        Uri.parse('$baseUrl/notifications/mark-all-read'),
        headers: _headers(token),
      );
    } catch (e) {
      debugPrint('Mark all as read error: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final token = await getToken();
      await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: _headers(token),
      );
    } catch (e) {
      debugPrint('Mark as read error: $e');
    }
  }
}