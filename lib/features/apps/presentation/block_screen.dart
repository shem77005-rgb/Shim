// // lib/ui/block_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// class BlockScreen extends StatelessWidget {
//   static const routeName = '/block_screen';
//   final String packageName;
//   const BlockScreen({Key? key, required this.packageName}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // منع العودة عبر زر العودة المادي
//     return WillPopScope(
//       onWillPop: () async => false,
//       child: Scaffold(
//         backgroundColor: Colors.black87,
//         body: SafeArea(
//           child: Directionality(
//             textDirection: TextDirection.rtl,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Image.asset('assets/images/lock_big.png', height: 120, width: 120, errorBuilder: (_,__,___)=> const Icon(Icons.block, size: 120, color: Colors.white70)),
//                 const SizedBox(height: 24),
//                 const Text('انتهت المدة المسموحة لهذا التطبيق', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 8),
//                 Text(packageName, style: const TextStyle(color: Colors.white70)),
//                 const SizedBox(height: 24),
//                 ElevatedButton(
//                   onPressed: () {
//                     // مثال: اطلب من الولي فتح إعدادات لإزالة الحظر لاحقًا
//                     Navigator.of(context).pop(); // أو توجه الى شاشة طلب بطلب والد
//                   },
//                   style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
//                   child: const Text('طلب إلغاء الحظر'),
//                 ),

//                 const SizedBox(height: 16),
//                 TextButton(
//                   onPressed: () {
//                     // لمنع إغلاق التطبيق كلياً: لا نفعل SystemNavigator.pop هنا.
//                     // بدلاً من ذلك نخفي شاشة الحظر فقط لو فُكّ الحظر بالخادم.
//                   },
//                   child: const Text('أعرف', style: TextStyle(color: Colors.white70)),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class BlockPage extends StatelessWidget {
  final String appName;

  const BlockPage({super.key, required this.appName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "تم تجاوز الوقت المحدد",
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              "لم يعد مسموح استخدام تطبيق:\n$appName",
              style: TextStyle(color: Colors.white70, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {},
              child: Text("الرجوع"),
            ),
          ],
        ),
      ),
    );
  }
}

