import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../../core/theme.dart';

class PrinterPage extends StatefulWidget {
  const PrinterPage({Key? key}) : super(key: key);

  @override
  State<PrinterPage> createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _getDevices();
  }

  // Mengambil daftar perangkat bluetooth yang sudah dipasangkan (paired)
  void _getDevices() async {
    List<BluetoothDevice> devices = [];
    devices = await bluetooth.getBondedDevices();
    setState(() {
      _devices = devices;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // ======================
          // CUSTOM HEADER
          // ======================
          Container(
            padding: const EdgeInsets.only(top: 40, bottom: 20, left: 10, right: 10),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
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
                    'Koneksi Printer Bluetooth',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Balance for back button
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // DROPDOWN PILIH PERANGKAT
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.blueGrey.shade200),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                         BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                      ]
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<BluetoothDevice>(
                        isExpanded: true,
                        hint: const Text("Pilih Printer Bluetooth"),
                        value: _selectedDevice,
                        items: _devices.map((device) {
                          return DropdownMenuItem(
                            value: device,
                            child: Text(device.name ?? "Tanpa Nama"),
                          );
                        }).toList(),
                        onChanged: (device) {
                          setState(() {
                            _selectedDevice = device;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // TOMBOL CONNECT / DISCONNECT
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _connected ? null : _connect,
                          icon: const Icon(Icons.bluetooth_connected),
                          label: const Text("Hubungkan"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _connected ? _disconnect : null,
                          icon: const Icon(Icons.bluetooth_disabled),
                          label: const Text("Putuskan"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // TOMBOL TEST PRINT
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _connected ? _testPrint : null,
                      icon: const Icon(Icons.print),
                      label: const Text("Cetak Struk Percobaan"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  const Divider(),
                  
                  const Text(
                    "Catatan: Pastikan printer thermal Bluetooth Anda sudah dipasangkan (paired) di pengaturan Bluetooth HP sebelum dibuka di aplikasi ini.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _connect() {
    if (_selectedDevice != null) {
      bluetooth.connect(_selectedDevice!).then((value) {
        setState(() => _connected = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Printer Berhasil Terhubung")));
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $error")));
      });
    }
  }

  void _disconnect() {
    bluetooth.disconnect();
    setState(() => _connected = false);
  }

  void _testPrint() async {
    // Logika cetak struktur sederhana
    bluetooth.isConnected.then((isConnected) {
      if (isConnected == true) {
        bluetooth.printNewLine();
        bluetooth.printCustom("TOKO BERKAH", 3, 1); // Ukuran besar, rata tengah
        bluetooth.printCustom("Premium Member POS", 1, 1);
        bluetooth.printNewLine();
        bluetooth.printLeftRight("Barang A", "10.000", 1);
        bluetooth.printLeftRight("Barang B", "25.000", 1);
        bluetooth.printCustom("--------------------------------", 1, 1);
        bluetooth.printLeftRight("TOTAL", "35.000", 2);
        bluetooth.printNewLine();
        bluetooth.printCustom("Terima Kasih", 1, 1);
        bluetooth.printNewLine();
        bluetooth.paperCut();
      }
    });
  }
}