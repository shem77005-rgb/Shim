// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import '../../../models/child_model.dart';
// import '../../../services/child_service.dart';
// import '../../../services/restricted_words_service.dart';
// import '../../../features/auth/data/services/auth_service.dart';

// class ChildWordRestrictionsScreen extends StatefulWidget {
//   final Child child;

//   const ChildWordRestrictionsScreen({super.key, required this.child});

//   @override
//   State<ChildWordRestrictionsScreen> createState() =>
//       _ChildWordRestrictionsScreenState();
// }

// class _ChildWordRestrictionsScreenState
//     extends State<ChildWordRestrictionsScreen> {
//   bool _isLoading = true;
//   List<String> _restrictedWords = [];
//   List<String> _apiRestrictedWords = [];
//   final TextEditingController _wordController = TextEditingController();
//   final AuthService _authService = AuthService();
//   late ChildService _childService;
//   late RestrictedWordsService _restrictedWordsService;

//   static const Color bg = Color(0xFFF3F5F6);
//   static const Color navy = Color(0xFF0A2E66);

//   @override
//   void initState() {
//     super.initState();
//     _childService = ChildService(apiClient: _authService.apiClient);
//     _restrictedWordsService = RestrictedWordsService(
//       apiClient: _authService.apiClient,
//     );
//     _initialize();
//   }

//   Future<void> _initialize() async {
//     await _loadRestrictedWords();
//   }

//   @override
//   void dispose() {
//     _wordController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadRestrictedWords() async {
//     setState(() => _isLoading = true);
//     try {
//       // First, try to load from API
//       final apiResponse = await _restrictedWordsService.getChildRestrictedWords(
//         childId: widget.child.id,
//       );

//       if (apiResponse.isSuccess && apiResponse.data != null) {
//         setState(() {
//           _restrictedWords = apiResponse.data!;
//           _apiRestrictedWords = List.from(apiResponse.data!);
//         });
//       } else {
//         // If API fails, fallback to local storage
//         print(
//           'API failed, falling back to local storage: ${apiResponse.error}',
//         );
//         final prefs = await SharedPreferences.getInstance();
//         final key = 'restricted_words_${widget.child.id}';
//         final wordsString = prefs.getString(key) ?? '[]';

//         // Parse the JSON string to a list
//         final List<dynamic> wordsList =
//             wordsString.isEmpty
//                 ? []
//                 : (wordsString.startsWith('[')
//                     ? (jsonDecode(wordsString) as List<dynamic>)
//                     : wordsString.split(','));

//         setState(() {
//           _restrictedWords = wordsList.cast<String>().toList();
//         });
//       }
//     } catch (e) {
//       print('Error loading restricted words: $e');
//       // Show error message to user
//     }
//     setState(() => _isLoading = false);
//   }

//   Future<void> _saveRestrictedWords() async {
//     try {
//       // First, save to API
//       final apiResponse = await _restrictedWordsService
//           .updateChildRestrictedWords(
//             childId: widget.child.id,
//             words: _restrictedWords,
//           );

//       if (apiResponse.isSuccess) {
//         // Also save to local storage as backup
//         final prefs = await SharedPreferences.getInstance();
//         final key = 'restricted_words_${widget.child.id}';
//         final wordsString = jsonEncode(_restrictedWords);
//         await prefs.setString(key, wordsString);

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('تم حفظ الكلمات المحظورة بنجاح'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       } else {
//         // If API fails, only save to local storage and show warning
//         final prefs = await SharedPreferences.getInstance();
//         final key = 'restricted_words_${widget.child.id}';
//         final wordsString = jsonEncode(_restrictedWords);
//         await prefs.setString(key, wordsString);

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text(
//                 'تم الحفظ محليًا فقط. قد تحتاج إلى الاتصال بالإنترنت لمزامنة التغييرات',
//               ),
//               backgroundColor: Colors.orange,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       print('Error saving restricted words: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('حدث خطأ أثناء حفظ الكلمات المحظورة'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   void _addWord() async {
//     final word = _wordController.text.trim();
//     if (word.isEmpty) return;

//     if (!_restrictedWords.contains(word)) {
//       // Try to add via API first
//       final apiResponse = await _restrictedWordsService.addChildRestrictedWord(
//         childId: widget.child.id,
//         word: word,
//       );

//       if (apiResponse.isSuccess) {
//         setState(() {
//           _restrictedWords.add(word);
//         });
//         _wordController.clear();

//         // Also save to local storage
//         final prefs = await SharedPreferences.getInstance();
//         final key = 'restricted_words_${widget.child.id}';
//         final wordsString = jsonEncode(_restrictedWords);
//         await prefs.setString(key, wordsString);
//       } else {
//         // Show error if API fails
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('فشل في إضافة الكلمة: ${apiResponse.error}'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     }
//   }

//   void _removeWord(String word) async {
//     // Try to remove via API first
//     final apiResponse = await _restrictedWordsService.removeChildRestrictedWord(
//       childId: widget.child.id,
//       word: word,
//     );

//     if (apiResponse.isSuccess) {
//       setState(() {
//         _restrictedWords.remove(word);
//       });

//       // Also update local storage
//       final prefs = await SharedPreferences.getInstance();
//       final key = 'restricted_words_${widget.child.id}';
//       final wordsString = jsonEncode(_restrictedWords);
//       await prefs.setString(key, wordsString);
//     } else {
//       // Show error if API fails
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('فشل في حذف الكلمة: ${apiResponse.error}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         backgroundColor: bg,
//         appBar: AppBar(
//           backgroundColor: Colors.white,
//           title: Text('كلمات محظورة - ${widget.child.name}'),
//           centerTitle: true,
//         ),
//         body: SafeArea(
//           child: Column(
//             children: [
//               _buildHeader(),
//               const SizedBox(height: 14),
//               if (_isLoading)
//                 const Center(child: CircularProgressIndicator())
//               else
//                 Expanded(child: _buildMainContent()),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       child: Row(
//         children: [
//           const Text(
//             'إدارة الكلمات المحظورة',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.w900,
//               color: Color(0xFF28323B),
//             ),
//           ),
//           const Spacer(),
//           IconButton(
//             icon: const Icon(Icons.close),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMainContent() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.symmetric(horizontal: 14),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // Child Info Card
//           _buildChildInfoCard(),
//           const SizedBox(height: 12),

//           // Add Word Section
//           _buildAddWordSection(),
//           const SizedBox(height: 12),

//           // Restricted Words List
//           _buildRestrictedWordsList(),
//           const SizedBox(height: 20),

//           // Save Button
//           SizedBox(
//             width: double.infinity,
//             child: FilledButton(
//               onPressed: _saveRestrictedWords,
//               style: FilledButton.styleFrom(
//                 backgroundColor: navy,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//               ),
//               child: const Text(
//                 'حفظ الكلمات المحظورة',
//                 style: TextStyle(fontSize: 16, color: Colors.white),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildChildInfoCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 24,
//               backgroundColor: Colors.blue.shade50,
//               child: const Icon(Icons.child_care, size: 24, color: Colors.blue),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.child.name,
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'البريد: ${widget.child.email}',
//                     style: TextStyle(color: Colors.grey.shade600),
//                   ),
//                   Text(
//                     'العمر: ${widget.child.age} سنوات',
//                     style: TextStyle(color: Colors.grey.shade600),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAddWordSection() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'إضافة كلمة محظورة',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _wordController,
//                     decoration: InputDecoration(
//                       hintText: 'أدخل كلمة محظورة',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 12,
//                       ),
//                     ),
//                     onSubmitted: (_) => _addWord(),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 IconButton(
//                   onPressed: _addWord,
//                   icon: const Icon(Icons.add, color: Colors.blue),
//                   style: IconButton.styleFrom(
//                     backgroundColor: Colors.blue.shade50,
//                     padding: const EdgeInsets.all(16),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'ستتم منع الطفل من كتابة هذه الكلمات في جميع التطبيقات',
//               style: TextStyle(color: Colors.grey, fontSize: 12),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRestrictedWordsList() {
//     if (_restrictedWords.isEmpty) {
//       return Card(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         child: const Padding(
//           padding: EdgeInsets.all(16),
//           child: Text(
//             'لا توجد كلمات محظورة مضافة حتى الآن',
//             textAlign: TextAlign.center,
//             style: TextStyle(color: Colors.grey),
//           ),
//         ),
//       );
//     }

//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'الكلمات المحظورة',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children:
//                   _restrictedWords.map((word) {
//                     return Chip(
//                       label: Text(word),
//                       backgroundColor: Colors.red.shade50,
//                       deleteIcon: const Icon(Icons.close, size: 18),
//                       onDeleted: () => _removeWord(word),
//                     );
//                   }).toList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/child_model.dart';
import '../../../services/restricted_words_service.dart';
import '../../../features/auth/data/services/auth_service.dart';

class ChildWordRestrictionsScreen extends StatefulWidget {
  final Child child;

  const ChildWordRestrictionsScreen({super.key, required this.child});

  @override
  State<ChildWordRestrictionsScreen> createState() =>
      _ChildWordRestrictionsScreenState();
}

class _ChildWordRestrictionsScreenState
    extends State<ChildWordRestrictionsScreen> {
  final TextEditingController _wordController = TextEditingController();

  final AuthService _authService = AuthService();
  late RestrictedWordsService _restrictedWordsService;

  List<String> _restrictedWords = [];
  bool _isLoading = true;

  static const Color navy = Color(0xFF0A2E66);

  @override
  void initState() {
    super.initState();
    _restrictedWordsService =
        RestrictedWordsService(apiClient: _authService.apiClient);
    _loadRestrictedWords();
  }

  Future<void> _loadRestrictedWords() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final key = 'restricted_words_${widget.child.id}';

    try {
      final response = await _restrictedWordsService.getChildRestrictedWords(
        childId: widget.child.id,
      );

      if (response.isSuccess && response.data != null) {
        _restrictedWords = response.data!;
        await prefs.setString(key, jsonEncode(_restrictedWords));
      } else {
        final local = prefs.getString(key) ?? '[]';
        _restrictedWords = List<String>.from(jsonDecode(local));
      }
    } catch (_) {
      final local = prefs.getString(key) ?? '[]';
      _restrictedWords = List<String>.from(jsonDecode(local));
    }

    setState(() => _isLoading = false);
  }

  Future<void> _addWord() async {
  final word = _wordController.text.trim();
  if (word.isEmpty || _restrictedWords.contains(word)) return;

  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(
    'active_child_id',
    widget.child.id.toString(),
  );

  final key = 'restricted_words_${widget.child.id}';

  final response = await _restrictedWordsService.addChildRestrictedWord(
    childId: widget.child.id,
    word: word,
  );

  if (response.isSuccess) {
    setState(() {
      _restrictedWords.add(word);
    });

    await prefs.setString(key, jsonEncode(_restrictedWords));
    _wordController.clear();
  }
}
  Future<void> _removeWord(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'restricted_words_${widget.child.id}';

    final response = await _restrictedWordsService.removeChildRestrictedWord(
      childId: widget.child.id,
      word: word,
    );

    if (response.isSuccess) {
      setState(() {
        _restrictedWords.remove(word);
      });
      await prefs.setString(key, jsonEncode(_restrictedWords));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('كلمات محظورة - ${widget.child.name}'),
          centerTitle: true,
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _wordController,
                        decoration: InputDecoration(
                          hintText: 'أدخل كلمة محظورة',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addWord,
                          ),
                        ),
                        onSubmitted: (_) => _addWord(),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child:
                            _restrictedWords.isEmpty
                                ? const Center(
                                  child: Text('لا توجد كلمات محظورة'),
                                )
                                : Wrap(
                                  spacing: 8,
                                  children:
                                      _restrictedWords
                                          .map(
                                            (word) => Chip(
                                              label: Text(word),
                                              deleteIcon: const Icon(Icons.close),
                                              onDeleted:
                                                  () => _removeWord(word),
                                            ),
                                          )
                                          .toList(),
                                ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: navy,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('تم'),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}

