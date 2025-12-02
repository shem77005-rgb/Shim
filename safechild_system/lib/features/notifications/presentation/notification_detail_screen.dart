import 'package:flutter/material.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل الإشعار'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.6,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'عنوان الإشعار',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'هذا نص تجريبي لمحتوى الإشعار. عند ربط الإشعارات بالـ API سيتم عرض النص الحقيقي هنا.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 12),
                        Text('الوصول: الآن', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // زر إغلاق/عودة
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A2E66),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('عودة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
