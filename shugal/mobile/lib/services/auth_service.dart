import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

class AuthService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    if (userJson != null) {
      return jsonDecode(userJson) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> saveAuthData({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setString(AppConstants.userKey, jsonEncode(user));
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Login API call
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Debug: Print login attempt details
      print('Login attempt - Email: $email, Password length: ${password.length}');
      print('API URL: ${ApiService.baseUrl}/auth/login');

      final response = await ApiService.post(
        'auth/login',
        {
          'email': email,
          'password': password,
        },
      );

      print('Login response: $response');

      final token = response['token'] as String;
      final user = response['user'] as Map<String, dynamic>;

      await saveAuthData(token: token, user: user);

      return {
        'success': true,
        'token': token,
        'user': user,
      };
    } on ApiException catch (e) {
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Register API call
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
    String? companyName,
    String? dateOfBirth,
    String? mobileNumber,
    int? nationalityCountryId,
    int? residentCountryId,
    List<int>? majorIds,
    int? educationId,
    int? yearsOfExperienceId,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role': role,
      };

      if (companyName != null && companyName.isNotEmpty) {
        body['company_name'] = companyName;
      }

      if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
        body['date_of_birth'] = dateOfBirth;
      }

      if (mobileNumber != null && mobileNumber.isNotEmpty) {
        body['mobile_number'] = mobileNumber;
      }

      if (nationalityCountryId != null) {
        body['nationality_country_id'] = nationalityCountryId;
      }

      if (residentCountryId != null) {
        body['resident_country_id'] = residentCountryId;
      }

      if (majorIds != null && majorIds.isNotEmpty) {
        body['major_ids'] = majorIds;
      }

      if (educationId != null) {
        body['education_id'] = educationId;
      }

      if (yearsOfExperienceId != null) {
        body['years_of_experience_id'] = yearsOfExperienceId;
      }

      final response = await ApiService.post(
        'auth/register',
        body,
      );

      final token = response['token'] as String;
      final user = response['user'] as Map<String, dynamic>;

      // Fetch full profile data after registration (for candidates)
      if (user['role'] == 'candidate') {
        try {
          final profileResponse = await ApiService.get(
            'mobile/candidate/profile',
            token: token,
          );
          
          // Update user data with full profile
          if (profileResponse.containsKey('candidate_profile')) {
            user['candidate_profile'] = profileResponse['candidate_profile'];
          } else if (profileResponse.containsKey('user')) {
            // If response wraps user object
            final updatedUser = profileResponse['user'] as Map<String, dynamic>;
            if (updatedUser.containsKey('candidate_profile')) {
              user['candidate_profile'] = updatedUser['candidate_profile'];
            }
          }
        } catch (e) {
          // If profile fetch fails, continue with basic user data
          print('Failed to fetch profile after registration: $e');
        }
      }

      await saveAuthData(token: token, user: user);

      return {
        'success': true,
        'token': token,
        'user': user,
      };
    } on ApiException catch (e) {
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Logout API call
  static Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await ApiService.post(
          'auth/logout',
          {},
          token: token,
        );
      }
    } catch (e) {
      // Ignore logout errors
    } finally {
      await clearAuthData();
    }
  }

  // Get current user (me) API call
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await ApiService.get(
        'auth/me',
        token: token,
      );

      final user = response['user'] as Map<String, dynamic>;
      await saveAuthData(token: token, user: user);

      return user;
    } catch (e) {
      return null;
    }
  }
}
