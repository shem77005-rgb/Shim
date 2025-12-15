import 'package:flutter/material.dart';
import 'notification_detail_screen.dart'; // تأكد أن هذا الملف في نفس المجلد أو عدّل المسار

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // قائمة بسيطة مؤقتة للاختبار (بإمكانك ربطها لاحقًا بخدمة أو API)
  final List<Map<String, String>> _items = [];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإشعارات'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.6,
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'مسح الكل',
              onPressed: _items.isEmpty ? null : _clearAll,
              icon: const Icon(Icons.delete_outline, color: Colors.black54),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: _buildBody(),
          ),
        ),
        // زر تجريبي لإضافة إشعار أثناء التطوير (احذفه لاحقًا أو غيّره ليتصل بالـ API)
        floatingActionButton: FloatingActionButton(
          onPressed: _addDemoNotification,
          backgroundColor: const Color(0xFF0A2E66),
          tooltip: 'إضافة إشعار تجريبي',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.notifications_none_outlined, size: 52, color: Colors.black26),
            SizedBox(height: 12),
            Text('لا توجد إشعارات جديدة', style: TextStyle(color: Colors.black54, fontSize: 16)),
            SizedBox(height: 6),
            Text('عند وصول إشعارات الطوارئ ستظهر هنا', style: TextStyle(color: Colors.black45)),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final it = _items[index];
        final title = it['title'] ?? 'إشعار';
        final body = it['body'] ?? '';
        final time = it['time'] ?? '';

        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationDetailScreen()),
            );
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.blue.shade50,
            child: const Icon(Icons.notifications, color: Colors.blue),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: Text(time, style: const TextStyle(fontSize: 11, color: Colors.black45)),
        );
      },
    );
  }

  void _addDemoNotification() {
    final now = DateTime.now();
    setState(() {
      _items.insert(0, {
        'title': 'تنبيه طارئ من الطفل',
        'body': 'الطفل طلب مساعدة — تم استلام الموقع.',
        'time': '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      });
    });
  }

  void _clearAll() {
    setState(() {
      _items.clear();
    });
  }
}
