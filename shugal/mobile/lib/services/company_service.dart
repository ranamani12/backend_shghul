import 'api_service.dart';
import 'auth_service.dart';

class CompanyService {
  // Get dashboard data (jobs and candidates)
  static Future<Map<String, dynamic>> getDashboard() async {
    final token = await AuthService.getToken();

    return ApiService.get(
      'mobile/company/dashboard',
      token: token,
    );
  }

  // Get company profile
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await AuthService.getToken();

    return ApiService.get(
      'mobile/company/profile',
      token: token,
    );
  }

  // Update company profile
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? companyName,
    String? industry,
    String? contactEmail,
    String? contactPhone,
    String? location,
    String? website,
    String? description,
  }) async {
    final token = await AuthService.getToken();

    final body = <String, dynamic>{};

    if (name != null && name.isNotEmpty) {
      body['name'] = name;
    }
    if (companyName != null && companyName.isNotEmpty) {
      body['company_name'] = companyName;
    }
    if (industry != null) {
      body['industry'] = industry;
    }
    if (contactEmail != null) {
      body['contact_email'] = contactEmail;
    }
    if (contactPhone != null) {
      body['contact_phone'] = contactPhone;
    }
    if (location != null) {
      body['location'] = location;
    }
    if (website != null) {
      body['website'] = website;
    }
    if (description != null) {
      body['description'] = description;
    }

    return ApiService.put(
      'mobile/company/profile',
      body,
      token: token,
    );
  }

  // Get all candidates
  static Future<Map<String, dynamic>> getCandidates({
    int page = 1,
    int perPage = 20,
    int? majorId,
  }) async {
    final token = await AuthService.getToken();

    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (majorId != null) {
      queryParams['major_id'] = majorId.toString();
    }

    return ApiService.get(
      'mobile/company/candidates',
      token: token,
      queryParams: queryParams,
    );
  }

  // Unlock a candidate
  static Future<Map<String, dynamic>> unlockCandidate(int candidateId) async {
    final token = await AuthService.getToken();

    return ApiService.post(
      'mobile/company/candidates/$candidateId/unlock',
      {},
      token: token,
    );
  }
}
