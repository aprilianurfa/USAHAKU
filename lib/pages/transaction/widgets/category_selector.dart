import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/product_provider.dart';
import '../../../models/category_hive.dart';
import '../../../core/theme.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Selector<ProductProvider, (List<CategoryHive>, String)>(
        selector: (_, p) => (p.categories, p.selectedCategoryId),
        builder: (ctx, data, _) {
          final categories = data.$1;
          final selectedId = data.$2;
          
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildCategoryPill(context, 'All', 'Semua', selectedId),
              ...categories.map((c) => 
                _buildCategoryPill(context, c.id, c.nama, selectedId)
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildCategoryPill(BuildContext context, String id, String label, String selectedId) {
    bool isSelected = selectedId == id;
    return GestureDetector(
      onTap: () {
        context.read<ProductProvider>().setCategory(id);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
          boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
