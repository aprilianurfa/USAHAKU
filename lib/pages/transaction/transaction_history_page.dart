import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../repositories/transaction_repository.dart';
import 'package:usahaku_main/core/app_shell.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final TransactionRepository _transactionRepository = TransactionRepository();
  final TransactionService _transactionService = TransactionService();

  List<Transaksi> _transactions = [];
  List<String> _customerNames = ['Semua'];
  bool _isLoading = true;
  DateTimeRange? _selectedDateRange;
  String _selectedCustomer = 'Semua';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(start: DateTime(now.year, now.month, now.day), end: now);
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    await _fetchCustomerNames();
    _fetchTransactions();
    _transactionRepository.sync().then((_) {
      if (mounted) _fetchTransactions();
    });
  }

  Future<void> _fetchCustomerNames() async {
    try {
      final names = await _transactionService.getCustomerNames();
      if (mounted) setState(() => _customerNames = ['Semua', ...names]);
    } catch (e) {
      debugPrint("Err fetching customers: $e");
    }
  }

  Future<void> _fetchTransactions({bool forceSync = false}) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      if (forceSync) await _transactionRepository.sync();
      DateTime endOfDay = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
      final data = await _transactionRepository.getAllTransactions(startDate: _selectedDateRange!.start, endDate: endOfDay, namaPelanggan: _selectedCustomer);
      if (mounted) setState(() { _transactions = data; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
      }
    }
  }

  void _onDateRangeChanged(DateTimeRange range) {
    setState(() => _selectedDateRange = range);
    _fetchTransactions();
  }

  void _onCustomerChanged(String customer) {
    setState(() => _selectedCustomer = customer);
    _fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: false, // MANDATORY
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => AppShell.of(context).toggleSidebar(),
        ),
        title: const Text("Riwayat Transaksi"),
        elevation: 0, backgroundColor: Colors.transparent, foregroundColor: Colors.white,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.defaultGradient)),
      ),
      body: Column(
        children: [
          const _HistoryHeaderSpacer(),
          _FilterBar(range: _selectedDateRange, onPick: _onDateRangeChanged, onRefresh: () => _fetchTransactions(forceSync: true)),
          _CustomerFilterBar(customers: _customerNames, selected: _selectedCustomer, onChanged: _onCustomerChanged),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator())
                : (_transactions.isEmpty ? const _EmptyHistoryState() : _TransactionList(transactions: _transactions)),
          ),
        ],
      ),
    );
  }
}

class _HistoryHeaderSpacer extends StatelessWidget {
  const _HistoryHeaderSpacer();
  @override
  Widget build(BuildContext context) {
    return Container(width: double.infinity, height: 20, decoration: const BoxDecoration(gradient: AppTheme.defaultGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))));
  }
}

class _FilterBar extends StatelessWidget {
  final DateTimeRange? range;
  final ValueChanged<DateTimeRange> onPick;
  final VoidCallback onRefresh;
  const _FilterBar({this.range, required this.onPick, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    String dateLabel = range != null ? "${DateFormat('dd/MM').format(range!.start)} - ${DateFormat('dd/MM').format(range!.end)}" : "Pilih Tanggal";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), color: Colors.white,
      child: Row(children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showDateRangePicker(context: context, initialDateRange: range, firstDate: DateTime(2020), lastDate: DateTime.now());
              if (picked != null) onPick(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor), const SizedBox(width: 8), Text(dateLabel, style: const TextStyle(fontSize: 14))]),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh, color: AppTheme.primaryColor))
      ]),
    );
  }
}

class _CustomerFilterBar extends StatelessWidget {
  final List<String> customers;
  final String selected;
  final ValueChanged<String> onChanged;
  const _CustomerFilterBar({required this.customers, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50, color: Colors.white, padding: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: customers.length,
        itemBuilder: (ctx, i) {
          final name = customers[i];
          final isSelected = selected == name;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(name), selected: isSelected, onSelected: (val) { if (val) onChanged(name); },
              selectedColor: AppTheme.primaryColor, labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 12),
              backgroundColor: Colors.grey.shade100, side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<Transaksi> transactions;
  const _TransactionList({required this.transactions});
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (ctx, i) => _TransactionCard(transaction: transactions[i]),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaksi transaction;
  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');
    
    return Card(
      elevation: 0, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: CircleAvatar(backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1), child: const Icon(Icons.receipt_long_outlined, color: AppTheme.primaryColor)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(transaction.namaPelanggan ?? "Umum", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(dateFmt.format((transaction.tanggal ?? DateTime.now()).toLocal())),
          Text("${transaction.items.length} Barang Dibeli", style: const TextStyle(fontSize: 12, color: Colors.grey))
        ]),
        trailing: Text(currency.format(transaction.totalBayar), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.only(bottom: 8), child: Text("Detail Barang:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
          ...transaction.items.map((item) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text("${item.namaBarang} x${item.qty}", style: const TextStyle(fontSize: 14))),
            Text(currency.format(item.subtotal), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ]))),
          const Divider(),
          _AmountRow(label: "Bayar", amount: currency.format(transaction.bayar)),
          const SizedBox(height: 4),
          _AmountRow(label: "Kembalian", amount: currency.format(transaction.kembalian), isHighlighted: true),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool isHighlighted;
  const _AmountRow({required this.label, required this.amount, this.isHighlighted = false});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      Text(amount, style: TextStyle(fontSize: 13, fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal, color: isHighlighted ? Colors.green : Colors.black)),
    ]);
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.history, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      const Text("Belum ada transaksi di periode ini", style: TextStyle(color: Colors.grey)),
    ]));
  }
}
