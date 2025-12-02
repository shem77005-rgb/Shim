// lib/ui/block_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BlockScreen extends StatelessWidget {
  static const routeName = '/block_screen';
  final String packageName;
  const BlockScreen({Key? key, required this.packageName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // منع العودة عبر زر العودة المادي
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/lock_big.png', height: 120, width: 120, errorBuilder: (_,__,___)=> const Icon(Icons.block, size: 120, color: Colors.white70)),
                const SizedBox(height: 24),
                const Text('انتهت المدة المسموحة لهذا التطبيق', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(packageName, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // مثال: اطلب من الولي فتح إعدادات لإزالة الحظر لاحقًا
                    Navigator.of(context).pop(); // أو توجه الى شاشة طلب بطلب والد
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  child: const Text('طلب إلغاء الحظر'),
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // لمنع إغلاق التطبيق كلياً: لا نفعل SystemNavigator.pop هنا.
                    // بدلاً من ذلك نخفي شاشة الحظر فقط لو فُكّ الحظر بالخادم.
                  },
                  child: const Text('أعرف', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
