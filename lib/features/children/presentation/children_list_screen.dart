import 'package:flutter/material.dart';
import '../../../services/child_service.dart';
import '../../../core/api/api_response.dart';
import '../../../models/child_model.dart';
import 'edit_child_screen.dart';

class ChildrenListScreen extends StatefulWidget {
  final String parentId;

  const ChildrenListScreen({Key? key, required this.parentId})
    : super(key: key);

  @override
  _ChildrenListScreenState createState() => _ChildrenListScreenState();
}

class _ChildrenListScreenState extends State<ChildrenListScreen> {
  List<Child> _children = [];
  bool _isLoading = false;
  String _errorMessage = '';
  late ChildService _childService;

  @override
  void initState() {
    super.initState();
    _childService = ChildService();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _childService.getParentChildren(
        parentId: widget.parentId,
      );

      if (response.isSuccess && response.data != null) {
        setState(() {
          _children = response.data!;
        });
      } else {
        setState(() {
          _errorMessage = response.error ?? 'فشل في تحميل قائمة الأطفال';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToAddChild() async {
    // Since AddChildScreen doesn't exist, we'll show a snackbar message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ميزة إضافة طفل غير متوفرة حالياً'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('قائمة الأطفال'),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.add), onPressed: _navigateToAddChild),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadChildren,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildContent(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddChild,
        child: Icon(Icons.add),
        tooltip: 'إضافة طفل',
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChildren,
              child: Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_children.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.child_care, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'لا توجد أطفال مسجلين',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToAddChild,
              child: Text('إضافة طفل أول'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _children.length,
      itemBuilder: (context, index) {
        final child = _children[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(Icons.child_care),
              backgroundColor: Colors.blue.withOpacity(0.2),
              foregroundColor: Colors.blue,
            ),
            title: Text(child.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('البريد: ${child.email}'),
                Text('العمر: ${child.age} سنة'),
              ],
            ),
            trailing: Text('تعديل'),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditChildScreen(child: child),
                ),
              );

              // If child was updated, refresh the list
              if (result != null) {
                _loadChildren();
              }
            },
          ),
        );
      },
    );
  }
}
