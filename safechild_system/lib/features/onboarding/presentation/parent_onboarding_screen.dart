import 'package:flutter/material.dart';
import '../../auth/presentation/parent_welcome_screen.dart';

class ParentOnboardingScreen extends StatefulWidget {
  const ParentOnboardingScreen({super.key});

  @override
  State<ParentOnboardingScreen> createState() => _ParentOnboardingScreenState();
}

class _ParentOnboardingScreenState extends State<ParentOnboardingScreen> {
  final _pc = PageController();
  int _index = 0;

  final _slides = const [
    _Slide(image: 'assets/images/childs.png', title: 'حماية طفلك تبدأ من هنا'),
    _Slide(
      image: 'assets/images/family.png',
      title: 'كن مطمئنًا على أبنائك دائمًا',
    ),
    _Slide(
      image: 'assets/images/hand.png',
      title: 'تحكم بما يشاهده أطفالك على الإنترنت',
    ),
  ];

  void _goToWelcome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ParentWelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F4FA),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // زر تخطي → يفتح شاشة الترحيب مباشرة
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _goToWelcome,
                  child: const Text(
                    'تخطي',
                    style: TextStyle(
                      color: Color(0xFF0D4F73),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _slides[i],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 10,
                    ),
                    height: 8,
                    width: active ? 16 : 8,
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF0A2E66) : Colors.black26,
                      borderRadius: BorderRadius.circular(50),
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0A2E66),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      if (_index < _slides.length - 1) {
                        _pc.nextPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        _goToWelcome(); // ← هنا الانتقال بعد “تم”
                      }
                    },
                    child: Text(_index == _slides.length - 1 ? 'تم' : 'التالي'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.image, required this.title});
  final String image, title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              image,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder:
                  (_, __, ___) => const Icon(Icons.broken_image, size: 100),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D4F73),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
