class DummyData {
  // =======================
  // DATA KATEGORI BARANG
  // =======================
  static List<Map<String, dynamic>> kategori = [
    {'id': 1, 'nama': 'Makanan'},
    {'id': 2, 'nama': 'Minuman'},
    {'id': 3, 'nama': 'Jasa'},
  ];

  // =======================
  // DATA BARANG / JASA
  // =======================
  static List<Map<String, dynamic>> barang = [
    {
      'id': 1,
      'nama': 'Nasi Goreng',
      'kategori': 'Makanan',
      'harga': 15000,
      'stok': 20,
      'barcode': '1234567890',
    },
    {
      'id': 2,
      'nama': 'Es Teh',
      'kategori': 'Minuman',
      'harga': 5000,
      'stok': 50,
      'barcode': '9876543210',
    },
    {
      'id': 3,
      'nama': 'Jasa Service',
      'kategori': 'Jasa',
      'harga': 50000,
      'stok': 999,
      'barcode': '-',
    },
  ];

  // =======================
  // DATA PELANGGAN
  // =======================
  static List<Map<String, dynamic>> pelanggan = [
    {
      'id': 1,
      'nama': 'Pelanggan Umum',
      'noHp': '-',
    },
    {
      'id': 2,
      'nama': 'Budi',
      'noHp': '08123456789',
    },
  ];

  // =======================
  // DATA TRANSAKSI
  // =======================
  static List<Map<String, dynamic>> transaksi = [
    {
      'id': 1,
      'tanggal': DateTime.now(),
      'pelanggan': 'Pelanggan Umum',
      'total': 30000,
      'items': [
        {'nama': 'Nasi Goreng', 'qty': 2, 'harga': 15000},
      ],
    },
  ];

  // =======================
  // DATA PEMBELIAN
  // =======================
  static List<Map<String, dynamic>> pembelian = [
    {
      'id': 1,
      'tanggal': DateTime.now(),
      'supplier': 'Supplier A',
      'total': 200000,
    },
  ];

  // =======================
  // DATA LAPORAN RINGKASAN (FIXED)
  // =======================
  static Map<String, int> laporanRingkasan = {
    'penjualanHariIni': 500000,
    'jumlahTransaksi': 25,
    'totalBiaya': 350000, // ✅ WAJIB ADA
    'labaBersih': 150000,
    'stokMenipis': 3,
  };

  // =======================
  // DATA USER
  // =======================
  static List<Map<String, dynamic>> users = [
    {
      'id': 1,
      'nama': 'Admin',
      'email': 'admin@usahaku.com',
      'password': '123456',
      'role': 'admin',
    },
    {
      'id': 2,
      'nama': 'Kasir',
      'email': 'kasir@usahaku.com',
      'password': '123456',
      'role': 'kasir',
    },
  ];

  // =======================
  // LOGIN
  // =======================
  static Map<String, dynamic>? login(
    String email,
    String password,
  ) {
    try {
      return users.firstWhere(
        (u) => u['email'] == email && u['password'] == password,
      );
    } catch (_) {
      return null;
    }
  }

  // =======================
  // REGISTER
  // =======================
  static void register({
    required String nama,
    required String email,
    required String password,
  }) {
    users.add({
      'id': users.length + 1,
      'nama': nama,
      'email': email,
      'password': password,
      'role': 'kasir',
    });
  }
}
