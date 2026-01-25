import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/product_provider.dart';

class TransactionSearchBar extends StatefulWidget {
  const TransactionSearchBar({super.key});

  @override
  State<TransactionSearchBar> createState() => _TransactionSearchBarState();
}

class _TransactionSearchBarState extends State<TransactionSearchBar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: context.read<ProductProvider>().searchQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _executeSearch() {
    // Only commit to provider on specific actions (Submit/Clear)
    context.read<ProductProvider>().searchProducts(_controller.text);
    // Unfocus for better UX on smaller devices after search commit
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: TextField(
        controller: _controller,
        onSubmitted: (_) => _executeSearch(),
        textInputAction: TextInputAction.search,
        // STRICT: onChanged DOES NOT call provider or business logic
        onChanged: (_) {
          // No-op or purely local visual feedback if needed
        },
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: "Cari produk / Barcode...",
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, size: 24, color: Colors.indigo.shade300),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () {
              _controller.clear();
              context.read<ProductProvider>().searchProducts('');
            },
          ),
        ),
      ),
    );
  }
}
