import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:typed_data';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  final _storage = const FlutterSecureStorage();
  
  BluetoothDevice? _connectedDevice;

  Future<bool> get isConnected async => await _bluetooth.isConnected ?? false;

  Future<List<BluetoothDevice>> getBondedDevices() async {
    return await _bluetooth.getBondedDevices();
  }

  Future<void> connect(BluetoothDevice device) async {
    try {
      await _bluetooth.connect(device);
      _connectedDevice = device;
      await _storage.write(key: 'last_printer_name', value: device.name);
      await _storage.write(key: 'last_printer_address', value: device.address);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _bluetooth.disconnect();
    _connectedDevice = null;
  }

  Future<void> printReceipt(Transaksi transaction, {String shopName = "USAHAKU", String? shopLogo}) async {
    bool? connected = await _bluetooth.isConnected;
    if (connected != true) return;

    // Formatting date
    String dateStr = DateFormat('dd/MM/yyyy HH:mm').format(transaction.tanggal);

    // Header
    _bluetooth.printNewLine();
    _bluetooth.printCustom(shopName.toUpperCase(), 3, 1);
    _bluetooth.printCustom("Premium POS Solution", 0, 1);
    _bluetooth.printNewLine();
    
    _bluetooth.printCustom("STRUK PENJUALAN", 1, 1);
    _bluetooth.printCustom("ID: ${transaction.id.substring(0, 8).toUpperCase()}", 0, 1);
    _bluetooth.printCustom(dateStr, 0, 1);
    _bluetooth.printCustom("Kasir: Owner", 0, 1);
    _bluetooth.printCustom("Pelanggan: ${transaction.namaPelanggan}", 0, 1);
    _bluetooth.printCustom("--------------------------------", 1, 1);

    // Items
    for (var item in transaction.items) {
      _bluetooth.printCustom(item.namaBarang, 1, 0);
      _bluetooth.printLeftRight(
        "${item.qty} x ${NumberFormat("#,###").format(item.harga)}",
        NumberFormat("#,###").format(item.subtotal),
        1,
      );
    }

    _bluetooth.printCustom("--------------------------------", 1, 1);

    // Totals
    _bluetooth.printLeftRight("TOTAL", NumberFormat("#,###").format(transaction.totalBayar), 2);
    _bluetooth.printLeftRight("TUNAI", NumberFormat("#,###").format(transaction.bayar), 1);
    _bluetooth.printLeftRight("KEMBALI", NumberFormat("#,###").format(transaction.kembalian), 1);
    
    _bluetooth.printNewLine();
    _bluetooth.printCustom("Terima Kasih Atas", 1, 1);
    _bluetooth.printCustom("Kunjungan Anda", 1, 1);
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.paperCut();
  }

  Future<void> printShiftReport(Map<String, dynamic> data, {String shopName = "USAHAKU", String? userName}) async {
    bool? connected = await _bluetooth.isConnected;
    if (connected != true) return;

    String dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    _bluetooth.printNewLine();
    _bluetooth.printCustom(shopName.toUpperCase(), 3, 1);
    _bluetooth.printCustom("LAPORAN TUTUP KASIR", 1, 1);
    _bluetooth.printNewLine();
    
    _bluetooth.printLeftRight("Waktu Cetak", dateStr, 0);
    _bluetooth.printLeftRight("Kasir", userName ?? "N/A", 0);
    _bluetooth.printCustom("--------------------------------", 1, 1);

    _bluetooth.printLeftRight("Modal Awal", NumberFormat("#,###").format(double.tryParse((data['initialCash'] ?? data['modal_awal'])?.toString() ?? '0') ?? 0), 1);
    _bluetooth.printLeftRight("Total Penjualan", NumberFormat("#,###").format(double.tryParse((data['totalSales'] ?? data['total_penjualan'])?.toString() ?? '0') ?? 0), 1);
    _bluetooth.printCustom("--------------------------------", 1, 1);
    
    _bluetooth.printLeftRight("UANG SISTEM", NumberFormat("#,###").format(double.tryParse((data['expected'] ?? data['expectedCash'])?.toString() ?? '0') ?? 0), 1);
    _bluetooth.printLeftRight("UANG FISIK", NumberFormat("#,###").format(double.tryParse((data['actual'] ?? data['actualCash'])?.toString() ?? '0') ?? 0), 1);
    
    double diff = double.tryParse((data['difference'] ?? data['selisih'])?.toString() ?? '0') ?? 0;
    _bluetooth.printLeftRight("SELISIH", NumberFormat("#,###").format(diff), 2);
    
    _bluetooth.printNewLine();
    _bluetooth.printCustom("REKAP PENJUALAN", 1, 1);
    _bluetooth.printLeftRight("Total Transaksi", "${data['transactionCount'] ?? 0}", 1);
    
    _bluetooth.printNewLine();
    _bluetooth.printCustom("Laporan ini sah dan final", 0, 1);
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.paperCut();
  }

  Future<void> testPrint() async {
    bool? connected = await _bluetooth.isConnected;
    if (connected != true) return;

    _bluetooth.printNewLine();
    _bluetooth.printCustom("TEST PRINT SUCCESS", 2, 1);
    _bluetooth.printCustom("Printer Ready", 1, 1);
    _bluetooth.printNewLine();
    _bluetooth.paperCut();
  }
}
