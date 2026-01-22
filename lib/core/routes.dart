import 'package:flutter/material.dart';

// AUTH
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';

// DASHBOARD
import '../pages/dashboard/dashboard_page.dart';

// PRODUCT & PURCHASE
import '../pages/product/product_page.dart';
import '../pages/product/category_page.dart';
import '../pages/product/purchase_page.dart';

// TRANSACTION
import '../pages/transaction/transaction_page.dart';
import '../pages/transaction/transaction_history_page.dart';
import '../pages/transaction/printer_page.dart';

// REPORT
import '../pages/report/summary_report.dart';
import '../pages/report/sales_report.dart';
import '../pages/report/profit_loss_report.dart';
import '../pages/report/cash_flow_report.dart';
import '../pages/report/product_sales_report.dart';
import '../pages/report/purchase_report.dart';
import '../pages/report/capital_report.dart';
import '../pages/report/expense_report.dart';
import '../pages/report/visitor_report.dart';
import '../pages/report/transaction_report.dart';
import '../pages/report/shift_report_page.dart';

// PROFILE & SETTINGS
import '../pages/profile/profile_page.dart';
import '../pages/settings/employee_list_page.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    // AUTH
    '/login': (context) => const LoginPage(),
    '/register': (context) => const RegisterPage(),

    // DASHBOARD
    '/dashboard': (context) => DashboardPage(),

    // PRODUCT
    '/product': (context) => const ProductPage(),
    '/category': (context) => const CategoryPage(),
    '/purchase': (context) => const PurchasePage(),

    // TRANSACTION
    '/transaction': (context) => const TransactionPage(),
    '/transaction-history': (context) => const TransactionHistoryPage(),
    '/printer-setting': (context) => PrinterPage(),

    // REPORT
    '/report': (context) => const SummaryReportPage(),
    '/report-sales': (context) => const SalesReportPage(),
    '/report-profit-loss': (context) => const ProfitLossReportPage(),
    '/report-cash-flow': (context) => const CashFlowReportPage(),
    '/report-product-sales': (context) => const ProductSalesReportPage(),
    '/report-purchase': (context) => const PurchaseReportPage(),
    '/report-capital': (context) => const CapitalReportPage(),
    '/report-expense': (context) => const ExpenseReportPage(),
    '/report-visitor': (context) => const VisitorReportPage(),
    '/report-transaction': (context) => const TransactionReportPage(),
    '/report-shift': (context) => const ShiftReportPage(),

    // PROFILE & SETTINGS
    '/profile': (context) => const ProfilePage(),
    '/employee-list': (context) => const EmployeeListPage(),
  };
}
