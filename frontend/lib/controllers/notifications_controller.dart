import 'package:flutter/material.dart';

import '../core/services/api_service.dart';
import '../models/notification_model.dart';

class NotificationsController extends ChangeNotifier {
  final ApiService _api;

  NotificationsController({ApiService? apiService}) : _api = apiService ?? ApiService();

  static const int _pageSize = 50;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _errorMessage;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.get('/notifications?limit=$_pageSize') as Map<String, dynamic>;
      _notifications = (data['notifications'] as List<dynamic>)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _unreadCount = data['unreadCount'] as int? ?? 0;
      _hasMore = data['hasMore'] as bool? ?? false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final data =
          await _api.get('/notifications?limit=$_pageSize&offset=${_notifications.length}')
              as Map<String, dynamic>;
      final nextPage = (data['notifications'] as List<dynamic>)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _notifications = [..._notifications, ...nextPage];
      _hasMore = data['hasMore'] as bool? ?? false;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].isRead) return;

    try {
      await _api.patch('/notifications/$id/read');
      _notifications[index] = NotificationModel(
        id: _notifications[index].id,
        type: _notifications[index].type,
        title: _notifications[index].title,
        body: _notifications[index].body,
        relatedId: _notifications[index].relatedId,
        isRead: true,
        createdAt: _notifications[index].createdAt,
      );
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      notifyListeners();
    } catch (_) {
      // Se reintentará en el próximo load()
    }
  }

  Future<void> markAllRead() async {
    if (_unreadCount == 0) return;
    try {
      await _api.patch('/notifications/read-all');
      _notifications = _notifications
          .map(
            (n) => NotificationModel(
              id: n.id,
              type: n.type,
              title: n.title,
              body: n.body,
              relatedId: n.relatedId,
              isRead: true,
              createdAt: n.createdAt,
            ),
          )
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {
      // Se reintentará en el próximo load()
    }
  }
}
