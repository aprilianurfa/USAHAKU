import 'package:flutter/material.dart';

class InputDraftProvider with ChangeNotifier {
  String _customerName = "Umum";
  String _payAmountRaw = "";
  int _payAmount = 0;

  String get customerName => _customerName;
  String get payAmountRaw => _payAmountRaw;
  int get payAmount => _payAmount;

  void setCustomerName(String name) {
    if (_customerName == name) return;
    _customerName = name;
    notifyListeners();
  }

  void setPayAmount(String raw) {
    if (_payAmountRaw == raw) return;
    _payAmountRaw = raw;
    String clean = raw.replaceAll(RegExp(r'[^0-9]'), '');
    _payAmount = int.tryParse(clean) ?? 0;
    notifyListeners();
  }

  void resetDraft() {
    _customerName = "Umum";
    _payAmountRaw = "";
    _payAmount = 0;
    notifyListeners();
  }
}
