import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';

class ParentAppsPolicyScreen extends StatefulWidget {
  final int childId;
  final String childName;
  final ApiClient apiClient;

  const ParentAppsPolicyScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.apiClient,
  });

  @override
  State<ParentAppsPolicyScreen> createState() => _ParentAppsPolicyScreenState();
}

class _ParentAppsPolicyScreenState extends State<ParentAppsPolicyScreen> {
  late final ApiClient _api;

  bool _loading = true;
  bool _saving = false;

  String _query = '';

  List<Map<String, dynamic>> _apps = [];
  List<Map<String, dynamic>> _filtered = [];

  // pkg -> limit_ms
  final Map<String, int> _limits = {};

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient;
    _loadChildApps();
    _loadExistingPolicy();
  }

  Future<void> _loadChildApps() async {
    setState(() => _loading = true);
    try {
      final url = ApiConstants.childApps(widget.childId);
      debugPrint('🟪 [ParentAppsPolicy] GET $url childId=${widget.childId}');

      final res = await _api.get<dynamic>(url, requiresAuth: true);

      debugPrint('🟪 [ParentAppsPolicy] apps success=${res.isSuccess} err=${res.error}');
      debugPrint('🟪 [ParentAppsPolicy] apps dataType=${res.data.runtimeType}');

      if (!res.isSuccess || res.data == null) {
        setState(() {
          _apps = [];
          _filtered = [];
          _loading = false;
        });
        return;
      }

      final data = res.data;
      if (data is List) {
        final list = data
            .map<Map<String, dynamic>>((e) {
          final m = (e as Map).map((k, v) => MapEntry(k.toString(), v));
          return {
            "package": (m["package"] ?? "").toString(),
            "name": (m["name"] ?? "").toString(),
          };
        })
            .where((x) => (x["package"] ?? "").toString().trim().isNotEmpty)
            .toList();

        list.sort((a, b) {
          final an = ((a["name"] ?? a["package"]) ?? "").toString().toLowerCase();
          final bn = ((b["name"] ?? b["package"]) ?? "").toString().toLowerCase();
          return an.compareTo(bn);
        });

        setState(() {
          _apps = list;
          _filtered = List.from(list);
          _loading = false;
        });

        debugPrint('✅ [ParentAppsPolicy] Loaded appsCount=${list.length}');
        debugPrint('✅ [ParentAppsPolicy] sampleFirst=${list.take(2).toList()}');
      } else {
        setState(() {
          _apps = [];
          _filtered = [];
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [ParentAppsPolicy] loadChildApps error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadExistingPolicy() async {
    try {
      final url = ApiConstants.childPolicyForParent(widget.childId);
      debugPrint('🟪 [ParentAppsPolicy] GET current policy $url');

      final res = await _api.get<dynamic>(url, requiresAuth: true);

      debugPrint('🟪 [ParentAppsPolicy] policy success=${res.isSuccess} err=${res.error}');
      debugPrint('🟪 [ParentAppsPolicy] policy data=${res.data}');

      if (!res.isSuccess || res.data == null) return;

      final data = res.data;
      if (data is Map && data["rules"] is List) {
        final rules = (data["rules"] as List)
            .whereType<Map>()
            .map((r) => r.map((k, v) => MapEntry(k.toString(), v)))
            .toList();

        _limits.clear();

        for (final r in rules) {
          final pkg = (r["package"] ?? "").toString().trim();
          final limitAny = r["limit_ms"];
          final limit = limitAny is int ? limitAny : int.tryParse(limitAny.toString()) ?? 0;

          if (pkg.isNotEmpty && limit > 0) {
            _limits[pkg] = limit;
          }
        }

        if (mounted) setState(() {});
        debugPrint('✅ [ParentAppsPolicy] Loaded existing rulesCount=${_limits.length}');
      }
    } catch (e) {
      debugPrint('❌ [ParentAppsPolicy] loadExistingPolicy error: $e');
    }
  }

  void _search(String q) {
    _query = q.trim().toLowerCase();
    if (_query.isEmpty) {
      setState(() => _filtered = List.from(_apps));
      return;
    }
    setState(() {
      _filtered = _apps.where((a) {
        final name = (a["name"] ?? "").toString().toLowerCase();
        final pkg = (a["package"] ?? "").toString().toLowerCase();
        return name.contains(_query) || pkg.contains(_query);
      }).toList();
    });
  }

  String _fmtMinutes(int ms) {
    final m = Duration(milliseconds: ms).inMinutes;
    return '$m د';
  }

  Future<void> _setLimitDialog(Map<String, dynamic> app) async {
    int hours = 0;
    int minutes = 10;

    final selected = await showModalBottomSheet<Duration>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: StatefulBuilder(
            builder: (ctx2, st) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Text(
                    (app["name"]?.toString().isNotEmpty == true)
                        ? app["name"].toString()
                        : app["package"].toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ساعات'),
                            DropdownButton<int>(
                              value: hours,
                              isExpanded: true,
                              items: List.generate(25, (i) => i)
                                  .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                                  .toList(),
                              onChanged: (v) => st(() => hours = v ?? 0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('دقائق'),
                            DropdownButton<int>(
                              value: minutes,
                              isExpanded: true,
                              items: [0, 5, 10, 15, 30, 45]
                                  .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                                  .toList(),
                              onChanged: (v) => st(() => minutes = v ?? 0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, Duration.zero),
                          child: const Text('حذف'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(
                            ctx,
                            Duration(hours: hours, minutes: minutes),
                          ),
                          child: const Text('حفظ'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        );
      },
    );

    if (!mounted || selected == null) return;

    final pkg = (app["package"] ?? "").toString().trim();
    if (pkg.isEmpty) return;

    if (selected.inMilliseconds == 0) {
      debugPrint('🟪 [ParentAppsPolicy] remove limit pkg=$pkg');
      setState(() => _limits.remove(pkg));
      debugPrint('🟪 [ParentAppsPolicy] limitsCount=${_limits.length}');
      return;
    }

    debugPrint('🟪 [ParentAppsPolicy] set limit pkg=$pkg ms=${selected.inMilliseconds}');
    setState(() => _limits[pkg] = selected.inMilliseconds);
    debugPrint('🟪 [ParentAppsPolicy] limitsCount=${_limits.length}');
  }

  Future<void> _savePolicyToServer() async {
    debugPrint('🟥 [ParentAppsPolicy] SAVE pressed. limitsCount=${_limits.length}');

    if (_saving) {
      debugPrint('🟡 [ParentAppsPolicy] already saving -> skip');
      return;
    }

    if (_limits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد حدود لحفظها')),
      );
      return;
    }

    setState(() => _saving = true);

    // SnackBar مباشر عشان تتأكد إن الزر انضغط فعلاً
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⏳ جاري حفظ السياسة...')),
    );

    try {
      final url = ApiConstants.childPolicyForParent(widget.childId);

      final rules = _limits.entries
          .map((e) => {"package": e.key, "limit_ms": e.value})
          .toList();

      debugPrint('🟪 [ParentAppsPolicy] PUT $url rulesCount=${rules.length}');
      debugPrint('🟪 [ParentAppsPolicy] rulesSample=${jsonEncode(rules.take(3).toList())}');

      final res = await _api.put<dynamic>(
        url,
        body: {"rules": rules},
        requiresAuth: true,
      );

      debugPrint('🟪 [ParentAppsPolicy] save success=${res.isSuccess} err=${res.error}');
      debugPrint('🟪 [ParentAppsPolicy] save data=${res.data}');

      if (!mounted) return;

      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم حفظ سياسة التطبيقات للطفل')),
        );

        // ✅ اختياري: أعد تحميل السياسة للتأكد أنها محفوظة فعلاً
        await _loadExistingPolicy();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ فشل حفظ السياسة: ${res.error ?? ""}')),
        );
      }
    } catch (e) {
      debugPrint('❌ [ParentAppsPolicy] savePolicyToServer error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ حدث خطأ أثناء حفظ السياسة')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
      debugPrint('🟥 [ParentAppsPolicy] SAVE finished.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = 'تطبيقات الطفل: ${widget.childName}';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Text(
                  '(${_limits.length})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            IconButton(
              tooltip: 'حفظ السياسة',
              onPressed: _saving ? null : _savePolicyToServer,
              icon: _saving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.save),
            ),
          ],
        ),

        // ✅ زر حفظ واضح جدًا أسفل الشاشة (هذا هو الأهم لحل مشكلتك)
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _savePolicyToServer,
              icon: const Icon(Icons.save),
              label: Text(_saving ? 'جاري الحفظ...' : 'حفظ السياسة (${_limits.length})'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextField(
                onChanged: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'ابحث باسم التطبيق أو اسم الحزمة',
                ),
              ),
              const SizedBox(height: 10),
              if (_loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                    child: Text(
                      _apps.isEmpty
                          ? 'لا توجد تطبيقات للطفل بعد.\nافتح تطبيق الطفل مرة واحدة ليتم رفع التطبيقات.'
                          : 'لا نتائج عن "${_query}"',
                      textAlign: TextAlign.center,
                    ),
                  )
                      : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final a = _filtered[i];
                      final pkg = (a["package"] ?? "").toString();
                      final name = (a["name"] ?? "").toString();
                      final limit = _limits[pkg];

                      return ListTile(
                        title: Text(name.isNotEmpty ? name : pkg),
                        subtitle: Text(pkg),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (limit != null)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(end: 8),
                                child: Text(
                                  _fmtMinutes(limit),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            const Icon(Icons.timer),
                          ],
                        ),
                        onTap: () => _setLimitDialog(a),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
