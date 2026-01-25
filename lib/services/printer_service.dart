import 'dart:async';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart'; // For FocusManager
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/transaction_model.dart';
import '../models/transaction_item_model.dart';

/// Service untuk menangani pencetakan struk via Bluetooth Thermal Printer.
/// Menggunakan layout style "Alfamart/Indomaret" yang rapi untuk kertas 58mm.
class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  BluetoothDevice? _connectedDevice;

  // --- GETTERS ---
  Future<bool> get isConnected async => await _bluetooth.isConnected ?? false;

  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      return await _bluetooth.getBondedDevices();
    } catch (e) {
      debugPrint("Error getting devices: $e");
      return [];
    }
  }

  // --- CONNECTION MANAGEMENT ---

  Future<void> connect(BluetoothDevice device) async {
    try {
      if (await isConnected) {
        // If already connected to this device, returning
         if (_connectedDevice?.address == device.address) return;
         await disconnect();
      }
      
      await _bluetooth.connect(device);
      _connectedDevice = device;

      // Save as default
      await _storage.write(key: 'last_printer_name', value: device.name);
      await _storage.write(key: 'last_printer_address', value: device.address);
    } catch (e) {
      debugPrint("Printer connection failed: $e");
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (await isConnected) {
      await _bluetooth.disconnect();
      _connectedDevice = null;
    }
  }

  // --- SETTINGS MANAGEMENT ---

  Future<void> saveReceiptSettings({
    required String shopName,
    required String address,
    required String footer,
  }) async {
    await _storage.write(key: 'receipt_shop_name', value: shopName);
    await _storage.write(key: 'receipt_address', value: address);
    await _storage.write(key: 'receipt_footer', value: footer);
  }

  Future<Map<String, String>> getReceiptSettings() async {
    return {
      'shopName': await _storage.read(key: 'receipt_shop_name') ?? 'USAHAKU',
      'address': await _storage.read(key: 'receipt_address') ?? 'Solusi Kasir UMKM',
      'footer': await _storage.read(key: 'receipt_footer') ?? 'Terima Kasih, Datang Kembali!',
    };
  }

  // --- HELPER FORMATTING ---

  String _rupiah(num value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(value);
  }

  void _printDashedLine() {
    _bluetooth.printCustom("--------------------------------", 1, 1);
  }

  void _printDoubleDashedLine() {
    _bluetooth.printCustom("================================", 1, 1);
  }

  // --- CORE PRINT LOGIC (ALFAMART STYLE) ---

  // --- CORE PRINT LOGIC (ALFAMART STYLE) ---

  Future<void> printReceipt(Transaksi trx) async {
    // 1. BEST PRACTICE: Close Keyboard first
    FocusManager.instance.primaryFocus?.unfocus();

    // 2. Check Connection
    if (!await isConnected) {
      debugPrint("Printer not connected!");
      return;
    }

    // 3. BEST PRACTICE: Delay for UI settlement
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final settings = await getReceiptSettings();
      
      _bluetooth.printNewLine();
      _printHeader(settings);
      _printMeta(trx);
      _printItems(trx.items);
      _printTotals(trx);
      _printFooter(settings);
      
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();
      _bluetooth.paperCut();

    } catch (e) {
      debugPrint("Error printing receipt: $e");
    }
  }

  void _printHeader(Map<String, String> settings) {
    _bluetooth.printCustom(settings['shopName']!.toUpperCase(), 3, 1); // 3 = Bold + Big
    _bluetooth.printCustom(settings['address']!, 0, 1); // Normal centered
    _printDashedLine();
  }

  void _printMeta(Transaksi trx) {
    final dateStr = DateFormat('dd.MM.yy').format(trx.tanggal);
    final timeStr = DateFormat('HH:mm').format(trx.tanggal);

    _bluetooth.printLeftRight("Tgl : $dateStr", timeStr, 0);
    _bluetooth.printLeftRight("No  : ${trx.id.substring(0, 12)}...", "", 0);
    _bluetooth.printLeftRight("Ksr : ${trx.pelangganId == 'GUEST' ? 'Admin' : 'Kasir'}", "", 0);
    _bluetooth.printLeftRight("Plg : ${trx.namaPelanggan}", "", 0);
    _printDashedLine();
  }

  void _printItems(List<TransaksiItem> items) {
    for (var item in items) {
      _bluetooth.printCustom(item.namaBarang, 0, 0); 
      String qtyPrice = "${item.qty}x ${_rupiah(item.harga)}";
      String subtotal = _rupiah(item.subtotal);
      _bluetooth.printLeftRight(qtyPrice, subtotal, 0);
    }
    _printDashedLine();
  }

  void _printTotals(Transaksi trx) {
    _bluetooth.printLeftRight("TOTAL", _rupiah(trx.totalBayar), 1); 
    _bluetooth.printLeftRight("TUNAI", _rupiah(trx.bayar), 0);
    _bluetooth.printLeftRight("KEMBALI", _rupiah(trx.kembalian), 0);
    _printDashedLine();
  }

  void _printFooter(Map<String, String> settings) {
    _bluetooth.printCustom("Harga sudah termasuk PPN", 0, 1);
    _bluetooth.printCustom("Barang yang sudah dibeli", 0, 1);
    _bluetooth.printCustom("tidak dapat ditukar/dikembalikan", 0, 1);
    
    _bluetooth.printNewLine();
    _bluetooth.printCustom(settings['footer']!, 1, 1);
    _bluetooth.printCustom("LAYANAN KONSUMEN", 0, 1);
    _bluetooth.printCustom("SMS/WA: 0812-3456-7890", 0, 1);
  }

  // --- PRINT SHIFT REPORT ---
  
  Future<void> printShiftReport(Map<String, dynamic> data, {String? userName}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!await isConnected) return;
    await Future.delayed(const Duration(milliseconds: 500)); // Prevent UI lag

    try {
      final settings = await getReceiptSettings();
      final now = DateTime.now();
      
      _bluetooth.printNewLine();
      _bluetooth.printCustom(settings['shopName']!.toUpperCase(), 3, 1);
      _bluetooth.printCustom("LAPORAN SHIFT", 2, 1); // Bold centered
      
      _printDoubleDashedLine();
      
      _bluetooth.printLeftRight("Waktu Cetak", DateFormat("dd/MM HH:mm").format(now), 0);
      _bluetooth.printLeftRight("Kasir", userName ?? "Admin", 0);
      
      _printDashedLine();
      
      // Content
      double modal = double.tryParse((data['initialCash'] ?? data['modal_awal'])?.toString() ?? '0') ?? 0;
      double totalSales = double.tryParse((data['totalSales'] ?? data['total_penjualan'])?.toString() ?? '0') ?? 0;
      double expected = double.tryParse((data['expected'] ?? data['expectedCash'])?.toString() ?? '0') ?? 0;
      double actual = double.tryParse((data['actual'] ?? data['actualCash'])?.toString() ?? '0') ?? 0;
       double diff = double.tryParse((data['difference'] ?? data['selisih'])?.toString() ?? '0') ?? 0;
      int trxCount = int.tryParse((data['transactionCount'] ?? data['jumlah_transaksi'])?.toString() ?? '0') ?? 0;

      // Layout
      _bluetooth.printLeftRight("Modal Awal", _rupiah(modal), 0);
      _bluetooth.printLeftRight("Total Penjualan", _rupiah(totalSales), 0);
      _bluetooth.printLeftRight("Jml Transaksi", "$trxCount", 0);
      
      _printDashedLine();
      
      _bluetooth.printLeftRight("Uang Seharusnya", _rupiah(expected), 0);
      _bluetooth.printLeftRight("Uang Fisik", _rupiah(actual), 0);
      
      _printDashedLine();
      
      _bluetooth.printLeftRight("SELISIH", _rupiah(diff), 1); // Bold/Big
      
      if (diff == 0) {
        _bluetooth.printCustom("( BALANCE )", 1, 1);
      } else if (diff > 0) {
        _bluetooth.printCustom("( SURPLUS )", 1, 1);
      } else {
        _bluetooth.printCustom("( MINUS )", 1, 1);
      }

      _bluetooth.printNewLine();
      _bluetooth.printCustom("Diproses oleh System", 0, 1);
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();
      _bluetooth.paperCut();

    } catch (e) {
      debugPrint("Error printing shift report: $e");
    }
  }

  // --- TEST PRINT ---

  Future<void> testPrint() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!await isConnected) return;

    final settings = await getReceiptSettings();
    _bluetooth.printNewLine();
    _bluetooth.printCustom("TEST KONEKSI PRINTER", 1, 1);
    _bluetooth.printCustom(settings['shopName']!, 0, 1);
    _bluetooth.printCustom("Printer Ready!", 0, 1);
    _printDashedLine();
    _bluetooth.printLeftRight("Kiri", "Kanan", 0);
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.paperCut();
  }
}
