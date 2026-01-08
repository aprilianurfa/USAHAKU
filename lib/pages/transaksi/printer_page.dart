import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

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
      appBar: AppBar(
        title: const Text("Koneksi Printer Bluetooth"),
        backgroundColor: const Color(0xFF1A46BE),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // DROPDOWN PILIH PERANGKAT
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueGrey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<BluetoothDevice>(
                isExpanded: true,
                underline: const SizedBox(),
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
            const SizedBox(height: 20),
            
            // TOMBOL CONNECT / DISCONNECT
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _connected ? null : _connect,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("Hubungkan"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _connected ? _disconnect : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("Putuskan"),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // TOMBOL TEST PRINT
            ElevatedButton(
              onPressed: _connected ? _testPrint : null,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text("Cetak Struk Percobaan"),
            ),
            
            const Divider(height: 40),
            
            const Text(
              "Catatan: Pastikan printer thermal Bluetooth Anda sudah dipasangkan (paired) di pengaturan Bluetooth HP sebelum dibuka di aplikasi ini.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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