import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../services/auth_service.dart';

class LookupService {
  // Helper method to fetch list data from API
  static Future<List<Map<String, dynamic>>> _fetchList(
    String endpoint,
    Map<String, String> queryParams, {
    String? token,
  }) async {
    try {
      var url = Uri.parse('${AppConstants.baseUrl}/$endpoint');
      if (queryParams.isNotEmpty) {
        url = url.replace(queryParameters: queryParams);
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((e) => e as Map<String, dynamic>).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get the name from a lookup item
  /// The API returns the name in the requested locale via the 'name' field
  static String getLocalizedName(Map<String, dynamic> item, String locale) {
    // The API returns 'name' field already in the correct locale
    // No need to check for name_ar - the API handles translation internally
    return item['name'] as String? ?? '';
  }

  /// Get list of names from lookup data
  static List<String> getLocalizedNames(List<Map<String, dynamic>> items, String locale) {
    return items
        .map((item) => item['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  /// Find lookup item by name and return its ID
  static int? getIdByLocalizedName(List<Map<String, dynamic>> items, String name, String locale) {
    for (final item in items) {
      if (item['name'] == name) {
        return item['id'] as int?;
      }
    }
    return null;
  }

  /// Find lookup item by ID and return its name
  static String? getLocalizedNameById(List<Map<String, dynamic>> items, int? id, String locale) {
    if (id == null) return null;
    for (final item in items) {
      if (item['id'] == id) {
        return item['name'] as String?;
      }
    }
    return null;
  }

  // Fetch majors from API with locale parameter
  static Future<List<Map<String, dynamic>>> getMajors({String locale = 'en'}) async {
    return _fetchList(
      'mobile/lookups',
      {'type': 'major', 'locale': locale},
    );
  }

  // Fetch education levels from API with locale parameter
  static Future<List<Map<String, dynamic>>> getEducationLevels({String locale = 'en'}) async {
    return _fetchList(
      'mobile/lookups',
      {'type': 'education_level', 'locale': locale},
    );
  }

  // Fetch experience years from API with locale parameter
  static Future<List<Map<String, dynamic>>> getExperienceYears({String locale = 'en'}) async {
    return _fetchList(
      'mobile/lookups',
      {'type': 'experience_year', 'locale': locale},
    );
  }

  // Fetch countries from API with locale parameter
  static Future<List<Map<String, dynamic>>> getCountries({String locale = 'en'}) async {
    return _fetchList(
      'mobile/countries',
      {'locale': locale},
    );
  }

  // Get lookup names as list of strings
  static Future<List<String>> getMajorNames({String locale = 'en'}) async {
    final majors = await getMajors(locale: locale);
    return getLocalizedNames(majors, locale);
  }

  static Future<List<String>> getEducationLevelNames({String locale = 'en'}) async {
    final levels = await getEducationLevels(locale: locale);
    return getLocalizedNames(levels, locale);
  }

  static Future<List<String>> getExperienceYearNames({String locale = 'en'}) async {
    final years = await getExperienceYears(locale: locale);
    return getLocalizedNames(years, locale);
  }

  static Future<List<String>> getCountryNames({String locale = 'en'}) async {
    final countries = await getCountries(locale: locale);
    return getLocalizedNames(countries, locale);
  }
}
