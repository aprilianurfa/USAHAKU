import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/view_metrics.dart';
import '../../core/widgets/keyboard_spacer.dart';
import '../../providers/input_draft_provider.dart';

class CheckoutSheet extends StatefulWidget {
  final int total;
  final List<String> customerNames;
  final String initialCustomer;
  final Function(int total, int uangDiterima, int kembalian, String customerName) onProcess;

  const CheckoutSheet({
    super.key,
    required this.total,
    required this.customerNames,
    required this.initialCustomer,
    required this.onProcess,
  });

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  late TextEditingController _payController;
  late TextEditingController _customerController;
  
  // Local state for immediate feedback WITHOUT Provider or total sheet rebuild
  final ValueNotifier<int> _uangDiterimaNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _payController = TextEditingController();
    _customerController = TextEditingController(text: widget.initialCustomer);
  }

  @override
  void dispose() {
    _payController.dispose();
    _customerController.dispose();
    _uangDiterimaNotifier.dispose();
    super.dispose();
  }

  void _handlePayChanged(String val) {
    // Business logic runs locally, NOT in provider per keystroke
    String clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    int amount = int.tryParse(clean) ?? 0;
    _uangDiterimaNotifier.value = amount;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Optimization: Dynamic height based on keyboard to prevent laggy jumps
      height: MediaQuery.viewInsetsOf(context).bottom > 0 
          ? getViewportScreenHeight(context) * 0.95 
          : getViewportScreenHeight(context) * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: RepaintBoundary(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const _CheckoutHandle(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _CheckoutHeaderInfo(),
                    const SizedBox(height: 20),
                    
                    _TotalRow(total: widget.total),
                    const Divider(height: 30),
                    
                    _CustomerField(
                      controller: _customerController,
                      customerNames: widget.customerNames,
                    ),
                    const SizedBox(height: 20),

                    _PaymentInputField(
                      controller: _payController,
                      onChanged: _handlePayChanged,
                    ),
                    const SizedBox(height: 15),
                    
                    _QuickMoneyChips(
                      total: widget.total,
                      onSelected: (val) {
                        _payController.text = val.toString();
                        _handlePayChanged(val.toString());
                      },
                    ),
                    const SizedBox(height: 25),
                    
                    _ChangeDisplay(
                      total: widget.total,
                      notifier: _uangDiterimaNotifier,
                    ),
                    const SizedBox(height: 30),
                    
                    _ProcessButton(
                      total: widget.total,
                      notifier: _uangDiterimaNotifier,
                      onPressed: () {
                        final val = _uangDiterimaNotifier.value;
                        final kembalian = val - widget.total;
                        // Optimization: Avoid broad rebuild of sheet
                        context.read<InputDraftProvider>().setPayAmount(_payController.text);
                        widget.onProcess(widget.total, val, kembalian, _customerController.text);
                      },
                    ),
                    const KeyboardSpacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutHandle extends StatelessWidget {
  const _CheckoutHandle();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
    );
  }
}

class _CheckoutHeaderInfo extends StatelessWidget {
  const _CheckoutHeaderInfo();
  @override
  Widget build(BuildContext context) {
    return const Text("Pembayaran", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
  }
}

class _TotalRow extends StatelessWidget {
  final int total;
  const _TotalRow({required this.total});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Total Tagihan", style: TextStyle(fontSize: 16, color: Colors.grey)),
        Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(total), 
             style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
      ],
    );
  }
}

class _CustomerField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> customerNames;
  const _CustomerField({required this.controller, required this.customerNames});

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (v) => v.text.isEmpty ? const Iterable<String>.empty() : customerNames.where((o) => o.toLowerCase().contains(v.text.toLowerCase())),
      onSelected: (s) => controller.text = s,
      fieldViewBuilder: (ctx, fieldController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          onChanged: (v) => controller.text = v,
          decoration: InputDecoration(
            labelText: "Nama Pelanggan",
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
        );
      },
    );
  }
}

class _PaymentInputField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _PaymentInputField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: "Bayar Cash",
        prefixText: "Rp ",
        hintText: "0",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
      ),
    );
  }
}

class _QuickMoneyChips extends StatelessWidget {
  final int total;
  final ValueChanged<int> onSelected;
  const _QuickMoneyChips({required this.total, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final suggestions = [20000, 50000, 100000, total].toSet().toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: suggestions.map((s) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ActionChip(
            label: Text(s == total ? "Uang Pas" : NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(s)),
            onPressed: () => onSelected(s),
            backgroundColor: Colors.white,
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        )).toList(),
      ),
    );
  }
}

class _ChangeDisplay extends StatelessWidget {
  final int total;
  final ValueNotifier<int> notifier;
  const _ChangeDisplay({required this.total, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: notifier,
      builder: (context, val, _) {
        final change = val - total;
        final isEnough = val >= total;
        
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isEnough ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isEnough ? Colors.green.shade200 : Colors.red.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Kembalian", style: TextStyle(fontWeight: FontWeight.bold, color: isEnough ? Colors.green.shade800 : Colors.red.shade800)),
              Text(
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(change),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isEnough ? Colors.green.shade800 : Colors.red.shade800),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProcessButton extends StatelessWidget {
  final int total;
  final ValueNotifier<int> notifier;
  final VoidCallback onPressed;
  const _ProcessButton({required this.total, required this.notifier, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: notifier,
      builder: (context, val, _) {
        final isEnough = val >= total;
        return Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            gradient: isEnough ? AppTheme.defaultGradient : null,
            color: isEnough ? null : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isEnough ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))] : null,
          ),
          child: ElevatedButton(
            onPressed: isEnough ? onPressed : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            child: const Text("PROSES BAYAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        );
      },
    );
  }
}
