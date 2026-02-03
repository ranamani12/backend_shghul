import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../services/api_service.dart';
import '../../widgets/app_header.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _notifications = [];
  int _currentPage = 1;
  int _lastPage = 1;
  bool _hasMore = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await NotificationService.getNotifications(
        page: 1,
        perPage: 20,
      );

      if (mounted) {
        setState(() {
          _notifications =
              List<Map<String, dynamic>>.from(response['data'] ?? []);
          _currentPage = response['current_page'] as int? ?? 1;
          _lastPage = response['last_page'] as int? ?? 1;
          _hasMore = _currentPage < _lastPage;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load notifications. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await NotificationService.getNotifications(
        page: _currentPage + 1,
        perPage: 20,
      );

      if (mounted) {
        setState(() {
          final newNotifications =
              List<Map<String, dynamic>>.from(response['data'] ?? []);
          _notifications.addAll(newNotifications);
          _currentPage = response['current_page'] as int? ?? _currentPage;
          _lastPage = response['last_page'] as int? ?? _lastPage;
          _hasMore = _currentPage < _lastPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    final notificationId = notification['id'] as int?;
    if (notificationId == null) return;

    try {
      await NotificationService.markAsRead(notificationId);
      if (mounted) {
        setState(() {
          final index =
              _notifications.indexWhere((n) => n['id'] == notificationId);
          if (index != -1) {
            _notifications[index]['read_at'] = DateTime.now().toIso8601String();
          }
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead();
      if (mounted) {
        setState(() {
          for (var notification in _notifications) {
            notification['read_at'] = DateTime.now().toIso8601String();
          }
        });
        _showSnackBar('All notifications marked as read');
      }
    } catch (e) {
      _showSnackBar('Failed to mark all as read');
    }
  }

  Future<void> _deleteNotification(Map<String, dynamic> notification) async {
    final notificationId = notification['id'] as int?;
    if (notificationId == null) return;

    try {
      await NotificationService.deleteNotification(notificationId);
      if (mounted) {
        setState(() {
          _notifications.removeWhere((n) => n['id'] == notificationId);
        });
        _showSnackBar('Notification deleted');
      }
    } catch (e) {
      _showSnackBar('Failed to delete notification');
    }
  }

  Future<void> _deleteAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete All Notifications'),
        content: const Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await NotificationService.deleteAllNotifications();
      if (mounted) {
        setState(() {
          _notifications.clear();
        });
        _showSnackBar('All notifications deleted');
      }
    } catch (e) {
      _showSnackBar('Failed to delete all notifications');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'meeting_scheduled':
        return Icons.calendar_today;
      case 'meeting_rescheduled':
        return Icons.update;
      case 'meeting_cancelled':
        return Icons.event_busy;
      case 'meeting_reminder':
        return Icons.alarm;
      case 'job_applied':
        return Icons.work;
      case 'application_viewed':
        return Icons.visibility;
      case 'application_accepted':
        return Icons.check_circle;
      case 'application_rejected':
        return Icons.cancel;
      case 'candidate_unlocked':
        return Icons.lock_open;
      case 'new_job_posted':
        return Icons.fiber_new;
      case 'profile_viewed':
        return Icons.person;
      case 'system':
        return Icons.notifications;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'meeting_scheduled':
      case 'meeting_rescheduled':
        return Colors.blue;
      case 'meeting_cancelled':
        return Colors.red;
      case 'meeting_reminder':
        return Colors.orange;
      case 'job_applied':
        return AppTheme.primaryColor;
      case 'application_viewed':
        return Colors.purple;
      case 'application_accepted':
        return Colors.green;
      case 'application_rejected':
        return Colors.red;
      case 'candidate_unlocked':
        return Colors.amber;
      case 'new_job_posted':
        return AppTheme.primaryColor;
      case 'profile_viewed':
        return Colors.indigo;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),

            // Main Content Container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.bodySurfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(48),
                    topRight: Radius.circular(48),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gray indicator bar
                    Center(
                      child: Container(
                        height: 5,
                        width: 50,
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: AppTheme.textPrimary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'Notifications',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              if (_notifications.isNotEmpty)
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: AppTheme.textPrimary,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'mark_all_read') {
                                      _markAllAsRead();
                                    } else if (value == 'delete_all') {
                                      _deleteAllNotifications();
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'mark_all_read',
                                      child: Row(
                                        children: [
                                          Icon(Icons.done_all, size: 20),
                                          SizedBox(width: 12),
                                          Text('Mark all as read'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete_all',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_sweep,
                                              size: 20, color: Colors.red),
                                          SizedBox(width: 12),
                                          Text('Delete all',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notifications List
                    Expanded(
                      child: _buildContent(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadNotifications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: AppTheme.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll receive notifications about\njobs, applications, and meetings here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _notifications.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _notifications.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                  strokeWidth: 2,
                ),
              ),
            );
          }

          return _buildNotificationCard(_notifications[index]);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final type = notification['type'] as String? ?? 'system';
    final title = notification['title'] as String? ?? 'Notification';
    final message = notification['message'] as String? ?? '';
    final createdAt = notification['created_at'] as String?;
    final readAt = notification['read_at'] as String?;
    final isRead = readAt != null;

    final iconColor = _getNotificationColor(type);
    final icon = _getNotificationIcon(type);

    return Dismissible(
      key: Key('notification_${notification['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification);
      },
      child: GestureDetector(
        onTap: () {
          if (!isRead) {
            _markAsRead(notification);
          }
          // Handle notification tap - navigate to relevant screen
          _handleNotificationTap(notification);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isRead ? AppTheme.white : AppTheme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: isRead
                ? null
                : Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    isRead ? FontWeight.w500 : FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'] as String? ?? '';
    final data = notification['data'] as Map<String, dynamic>?;

    // Handle navigation based on notification type
    switch (type) {
      case 'meeting_scheduled':
      case 'meeting_rescheduled':
      case 'meeting_cancelled':
      case 'meeting_reminder':
        // Navigate to interview/meeting screen
        // You can add navigation logic here
        break;
      case 'job_applied':
        // Navigate to job applicants screen (for company)
        break;
      case 'application_accepted':
      case 'application_rejected':
      case 'application_viewed':
        // Navigate to applications screen (for candidate)
        break;
      case 'candidate_unlocked':
        // Navigate to profile screen (for candidate)
        break;
      default:
        // Do nothing or show details
        break;
    }
  }
}
