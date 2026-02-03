import 'api_service.dart';
import 'auth_service.dart';

class JobService {
  // Get all jobs for company
  static Future<Map<String, dynamic>> getCompanyJobs({
    int page = 1,
    int perPage = 15,
  }) async {
    final token = await AuthService.getToken();

    return ApiService.get(
      'mobile/company/jobs',
      token: token,
      queryParams: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
  }

  // Create a new job posting
  static Future<Map<String, dynamic>> createJob({
    required String title,
    required String description,
    String? requirements,
    String? experienceLevel,
    String? location,
    String? salaryRange,
    String? hiringType,
    String? interviewType,
    String? jobType,
    List<int>? majorIds,
    bool isActive = true,
  }) async {
    final token = await AuthService.getToken();

    final body = <String, dynamic>{
      'title': title,
      'description': description,
      'is_active': isActive,
    };

    if (requirements != null && requirements.isNotEmpty) {
      body['requirements'] = requirements;
    }
    if (experienceLevel != null && experienceLevel.isNotEmpty) {
      body['experience_level'] = experienceLevel;
    }
    if (location != null && location.isNotEmpty) {
      body['location'] = location;
    }
    if (salaryRange != null && salaryRange.isNotEmpty) {
      body['salary_range'] = salaryRange;
    }
    if (hiringType != null && hiringType.isNotEmpty) {
      body['hiring_type'] = hiringType;
    }
    if (interviewType != null && interviewType.isNotEmpty) {
      body['interview_type'] = interviewType;
    }
    if (jobType != null && jobType.isNotEmpty) {
      body['job_type'] = jobType.toLowerCase();
    }
    if (majorIds != null && majorIds.isNotEmpty) {
      body['major_ids'] = majorIds;
    }

    return ApiService.post(
      'mobile/company/jobs',
      body,
      token: token,
    );
  }

  // Update an existing job posting
  static Future<Map<String, dynamic>> updateJob({
    required int jobId,
    String? title,
    String? description,
    String? requirements,
    String? experienceLevel,
    String? location,
    String? salaryRange,
    String? hiringType,
    String? interviewType,
    String? jobType,
    List<int>? majorIds,
    bool? isActive,
  }) async {
    final token = await AuthService.getToken();

    final body = <String, dynamic>{};

    if (title != null && title.isNotEmpty) {
      body['title'] = title;
    }
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    if (requirements != null) {
      body['requirements'] = requirements;
    }
    if (experienceLevel != null) {
      body['experience_level'] = experienceLevel;
    }
    if (location != null) {
      body['location'] = location;
    }
    if (salaryRange != null) {
      body['salary_range'] = salaryRange;
    }
    if (hiringType != null) {
      body['hiring_type'] = hiringType;
    }
    if (interviewType != null) {
      body['interview_type'] = interviewType;
    }
    if (jobType != null) {
      body['job_type'] = jobType.toLowerCase();
    }
    if (majorIds != null) {
      body['major_ids'] = majorIds;
    }
    if (isActive != null) {
      body['is_active'] = isActive;
    }

    return ApiService.put(
      'mobile/company/jobs/$jobId',
      body,
      token: token,
    );
  }

  // Delete a job posting
  static Future<Map<String, dynamic>> deleteJob(int jobId) async {
    final token = await AuthService.getToken();

    return ApiService.delete(
      'mobile/company/jobs/$jobId',
      token: token,
    );
  }

  // Get job applicants
  static Future<Map<String, dynamic>> getJobApplicants({
    required int jobId,
    int page = 1,
    int perPage = 20,
  }) async {
    final token = await AuthService.getToken();

    return ApiService.get(
      'mobile/company/jobs/$jobId/applicants',
      token: token,
      queryParams: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
  }
}
