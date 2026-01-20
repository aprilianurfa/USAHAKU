import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';

class RiwayatTransaksiPage extends StatefulWidget {
  const RiwayatTransaksiPage({super.key});

  @override
  State<RiwayatTransaksiPage> createState() => _RiwayatTransaksiPageState();
}

class _RiwayatTransaksiPageState extends State<RiwayatTransaksiPage> {
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
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 0)),
      end: DateTime.now(),
    );
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    await _fetchCustomerNames();
    _fetchTransactions();
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

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      // Set end of day for the end date to catch all transactions on that day
      DateTime endOfDay = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
      
      final data = await _transactionService.getTransactions(
        startDate: _selectedDateRange!.start,
        endDate: endOfDay,
        namaPelanggan: _selectedCustomer,
      );
      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
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
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterBar(),
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
            onPressed: _fetchTransactions,
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
        subtitle: Text(dateFormatter.format(t.tanggal ?? DateTime.now())),
        trailing: Text(
          currencyFormatter.format(t.totalBayar),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
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

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 20),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Expanded(
            child: Text(
              'Riwayat Transaksi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48),
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
