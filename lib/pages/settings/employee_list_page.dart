import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/theme.dart';
import '../../core/theme.dart';
import '../../widgets/app_drawer.dart';
import 'add_employee_page.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({Key? key}) : super(key: key);

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  final AuthService _authService = AuthService();
  late Future<dynamic> _employeesFuture;


  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  void _loadEmployees() {
    setState(() {
      _employeesFuture = _authService.getEmployees();
    });
  }

  Future<void> _deleteEmployee(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Karyawan"),
        content: Text("Yakin ingin menghapus $name?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await _authService.deleteEmployee(id);
      if (res != null && res['error'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Karyawan berhasil dihapus")),
          );
          _loadEmployees();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res?['error'] ?? "Gagal menghapus")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Daftar Karyawan", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.defaultGradient,
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder<dynamic>(
        future: _employeesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data;
          
          if (data is Map && data.containsKey('error')) {
             return Center(child: Text(data['error']));
          }

          if (data is! List) {
            return const Center(child: Text("Data tidak valid"));
          }

          final List employees = data;

          if (employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text("Belum ada karyawan", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadEmployees(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 80), // Add bottom padding for FAB
              itemCount: employees.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final emp = employees[i];
                final String name = emp['nama'] ?? 'Tanpa Nama';
                final String role = emp['role'] ?? 'Staff';
                final int id = emp['id'];

                return Card(
                  elevation: 0,
                  margin: EdgeInsets.zero, // Controlled by ListView separator
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      onPressed: () => _deleteEmployee(id, name),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          height: 55,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.defaultGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                ]
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final refresh = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddEmployeePage()),
                    );
                    if (refresh == true) {
                      _loadEmployees();
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_rounded, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        "TAMBAH KARYAWAN BARU",
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: 1.2
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ),
      ),
    );
  }
}
