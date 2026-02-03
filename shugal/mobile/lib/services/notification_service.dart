import 'api_service.dart';
import 'auth_service.dart';

class NotificationService {
  // Get all notifications
  static Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int perPage = 20,
    bool unreadOnly = false,
    String? type,
  }) async {
    final token = await AuthService.getToken();

    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (unreadOnly) {
      queryParams['unread_only'] = 'true';
    }

    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }

    return ApiService.get(
      'mobile/notifications',
      token: token,
      queryParams: queryParams,
    );
  }

  // Get unread notification count
  static Future<int> getUnreadCount() async {
    final token = await AuthService.getToken();

    final response = await ApiService.get(
      'mobile/notifications/unread-count',
      token: token,
    );

    return response['unread_count'] as int? ?? 0;
  }

  // Mark a notification as read
  static Future<Map<String, dynamic>> markAsRead(int notificationId) async {
    final token = await AuthService.getToken();

    return ApiService.post(
      'mobile/notifications/$notificationId/read',
      {},
      token: token,
    );
  }

  // Mark all notifications as read
  static Future<Map<String, dynamic>> markAllAsRead() async {
    final token = await AuthService.getToken();

    return ApiService.post(
      'mobile/notifications/mark-all-read',
      {},
      token: token,
    );
  }

  // Delete a notification
  static Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    final token = await AuthService.getToken();

    return ApiService.delete(
      'mobile/notifications/$notificationId',
      token: token,
    );
  }

  // Delete all notifications
  static Future<Map<String, dynamic>> deleteAllNotifications() async {
    final token = await AuthService.getToken();

    return ApiService.delete(
      'mobile/notifications/delete-all',
      token: token,
    );
  }
}
