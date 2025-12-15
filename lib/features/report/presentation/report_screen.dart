
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';



class AppUsageDetail {
  final String appName;
  final double percentage; // 0.0 to 1.0

  AppUsageDetail({required this.appName, required this.percentage});
}

class ReportData {
  final Duration dailyUsage;
  final Duration weeklyUsage;
  final List<AppUsageDetail> appUsageDetails;
  final int blockedAttempts;
  String? summary; // سيتم توليده لاحقًا

  ReportData({
    required this.dailyUsage,
    required this.weeklyUsage,
    required this.appUsageDetails,
    required this.blockedAttempts,
    this.summary,
  });
}



final ReportData placeholderData = ReportData(
  dailyUsage: const Duration(hours: 3, minutes: 20),
  weeklyUsage: const Duration(hours: 18),
  blockedAttempts: 5,
  appUsageDetails: [
    AppUsageDetail(appName: 'يوتيوب', percentage: 0.40),
    AppUsageDetail(appName: 'تيك توك', percentage: 0.30),
    AppUsageDetail(appName: 'واتساب', percentage: 0.20),
    AppUsageDetail(appName: 'باقي التطبيقات', percentage: 0.10),
  ],
);



class ReportScreen extends StatelessWidget {
  final ReportData data;

  const ReportScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D47A1), // لون أزرق داكن
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUsageCard(
                title: 'مدة إستخدام التطبيقات',
                icon: Icons.access_time,
                content: [
                  Text(
                    'اليوم: ${data.dailyUsage.inHours} ساعات ${data.dailyUsage.inMinutes.remainder(60)} دقيقة',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'الأسبوع: ${data.weeklyUsage.inHours} ساعة',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildUsageBreakdownCard(data.appUsageDetails),
              const SizedBox(height: 16),
              _buildBlockedAccessCard(data.blockedAttempts),
              const SizedBox(height: 16),
              _buildSummaryCard(data.summary ?? 'جاري توليد الملخص...'),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _exportReport(context, data),
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text(
                  'تصدير التقرير',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Color iconColor, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildUsageCard({required String title, required IconData icon, required List<Widget> content}) {
    return _buildCard(
      title: title,
      icon: icon,
      iconColor: Colors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content,
      ),
    );
  }

  Widget _buildUsageBreakdownCard(List<AppUsageDetail> details) {
    return _buildCard(
      title: 'مدة إستخدام التطبيقات',
      icon: Icons.apps,
      iconColor: Colors.blue,
      child: Column(
        children: details.map((detail) => _buildProgressBar(detail)).toList(),
      ),
    );
  }

  Widget _buildProgressBar(AppUsageDetail detail) {
    final percentageText = '(${((detail.percentage) * 100).toInt()}%)';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${detail.appName} $percentageText'),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: detail.percentage,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D47A1)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedAccessCard(int attempts) {
    return _buildCard(
      title: 'عدد الدخول للمواقع المحظورة',
      icon: Icons.block,
      iconColor: Colors.red,
      child: Text(
        'عدد المحاولات: $attempts مرات',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildSummaryCard(String summary) {
    return _buildCard(
      title: 'ملخص',
      icon: Icons.description,
      iconColor: Colors.orange,
      child: Text(
        summary,
        style: const TextStyle(fontSize: 16, height: 1.5),
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // 4. تصدير التقرير (سيتم استكمالها في المرحلة 4)
  // -----------------------------------------------------------------------------

  Future<void> _exportReport(BuildContext context, ReportData data) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري تصدير التقرير...')),
    );
    // سيتم استكمال منطق تصدير PDF في المرحلة القادمة
    final pdf = await _generatePdf(data);
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'تقرير_الاستخدام_الأسبوعي.pdf');
  }

  Future<pw.Document> _generatePdf(ReportData data) async {
    final pdf = pw.Document(title: 'تقرير الاستخدام الأسبوعي');

    // تحميل خط يدعم اللغة العربية
    final font = await PdfGoogleFonts.notoSansArabicRegular();
    final boldFont = await PdfGoogleFonts.notoSansArabicBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('تقرير الاستخدام الأسبوعي', style: pw.TextStyle(font: boldFont, fontSize: 24)),
                pw.Divider(),
                
                // مدة الاستخدام
                _buildPdfSection(
                  title: 'مدة إستخدام التطبيقات',
                  content: [
                    pw.Text('اليوم: ${data.dailyUsage.inHours} ساعات ${data.dailyUsage.inMinutes.remainder(60)} دقيقة', style: pw.TextStyle(font: font, fontSize: 14)),
                    pw.Text('الأسبوع: ${data.weeklyUsage.inHours} ساعة', style: pw.TextStyle(font: font, fontSize: 14)),
                  ],
                  font: font,
                  boldFont: boldFont,
                ),
                pw.SizedBox(height: 20),

                // تفاصيل الاستخدام
                _buildPdfSection(
                  title: 'تفاصيل إستخدام التطبيقات',
                  content: data.appUsageDetails.map((detail) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('${detail.appName} (${((detail.percentage) * 100).toInt()}%)', style: pw.TextStyle(font: font, fontSize: 12)),
                          pw.SizedBox(height: 2),
                          pw.Stack(
                            children: [
                              // الخلفية الرمادية
                              pw.Container(
                                height: 8,
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.grey300,
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                              ),
                              // شريط التقدم الأزرق
                              pw.Container(
                                height: 8,
                                width: detail.percentage * double.infinity, // استخدام نسبة مئوية من العرض
                                decoration: pw.BoxDecoration(
                                  color: PdfColor.fromHex('0D47A1'),
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  font: font,
                  boldFont: boldFont,
                ),
                pw.SizedBox(height: 20),

                // المواقع المحظورة
                _buildPdfSection(
                  title: 'عدد الدخول للمواقع المحظورة',
                  content: [
                    pw.Text('عدد المحاولات: ${data.blockedAttempts} مرات', style: pw.TextStyle(font: font, fontSize: 14)),
                  ],
                  font: font,
                  boldFont: boldFont,
                ),
                pw.SizedBox(height: 20),

                // الملخص
                _buildPdfSection(
                  title: 'ملخص أسبوعي',
                  content: [
                    pw.Text(data.summary ?? 'لا يوجد ملخص متاح.', style: pw.TextStyle(font: font, fontSize: 14, lineSpacing: 1.5)),
                  ],
                  font: font,
                  boldFont: boldFont,
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfSection({
    required String title,
    required List<pw.Widget> content,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 18, color: PdfColor.fromHex('0D47A1'))),
        pw.Divider(color: PdfColors.grey400),
        ...content,
      ],
    );
  }
}