import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../repositories/transaction_repository.dart';
import '../../widgets/app_drawer.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final TransactionRepository _transactionRepository = TransactionRepository();
  final TransactionService _transactionService = TransactionService();
  final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final DateFormat dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

  List<Transaksi> _transactions = [];
  List<String> _customerNames = ['Semua'];
  bool _isLoading = true;
  DateTimeRange? _selectedDateRange;
  String _selectedCustomer = 'Semua';

  @override
  void initState() {
    super.initState();
    // Default to today
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: now,
    );
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    await _fetchCustomerNames();
    _fetchTransactions(); // Load local data immediately
    
    // Background Sync
    _transactionRepository.sync().then((_) {
      if (mounted) _fetchTransactions(); // Refresh UI after sync completes
    });
  }

  Future<void> _fetchCustomerNames() async {
    try {
      final names = await _transactionService.getCustomerNames();
      if (mounted) {
        setState(() {
          _customerNames = ['Semua', ...names];
        });
      }
    } catch (e) {
      print("Err fetching customers: $e");
    }
  }

  Future<void> _fetchTransactions({bool forceSync = false}) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      if (forceSync) {
        await _transactionRepository.sync();
      }

      // Set end of day for the end date to catch all transactions on that day
      DateTime endOfDay = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
      
      final data = await _transactionRepository.getAllTransactions(
        startDate: _selectedDateRange!.start,
        endDate: endOfDay,
        namaPelanggan: _selectedCustomer,
      );
      if (mounted) {
        setState(() {
          _transactions = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
      }
    }
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() => _selectedDateRange = picked);
      _fetchTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text("Riwayat Transaksi"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.defaultGradient,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Custom header removed, kept only filters if needed or adjusting layout
          // _buildHeader() removed
          Container(
             width: double.infinity,
             height: 20, 
             decoration: const BoxDecoration(
               gradient: AppTheme.defaultGradient,
               borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
             ),
          ),
          Transform.translate(
            offset: const Offset(0, -20),
            child: _buildFilterBar(),
          ),
          _buildCustomerFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final t = _transactions[index];
                          return _buildTransactionCard(t);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    String dateLabel = "Pilih Tanggal";
    if (_selectedDateRange != null) {
      dateLabel = "${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _pickDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(dateLabel, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () => _fetchTransactions(forceSync: true),
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Belum ada transaksi di periode ini", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaksi t) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: const Icon(Icons.receipt_long_outlined, color: AppTheme.primaryColor),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          t.namaPelanggan ?? "Umum", 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormatter.format((t.tanggal ?? DateTime.now()).toLocal())),
            Text(
              "${t.items.length} Barang Dibeli",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          ],
        ),
        trailing: Text(
          currencyFormatter.format(t.totalBayar),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text("Detail Barang:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
          ...t.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "${item.namaBarang} x${item.qty}", 
                    style: const TextStyle(fontSize: 14)
                  )
                ),
                Text(
                  currencyFormatter.format(item.subtotal), 
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
                ),
              ],
            ),
          )),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Bayar", style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(currencyFormatter.format(t.bayar), style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Kembalian", style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(currencyFormatter.format(t.kembalian), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildCustomerFilter() {
    return Container(
      height: 50,
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _customerNames.length,
        itemBuilder: (context, index) {
          final name = _customerNames[index];
          final isSelected = _selectedCustomer == name;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(name),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedCustomer = name);
                  _fetchTransactions();
                }
              },
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12,
              ),
              backgroundColor: Colors.grey.shade100,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }
}
