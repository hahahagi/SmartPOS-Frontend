PROJECT BRIEF FRONTEND
SISTEM KASIR SWALAYAN (FLUTTER)

1. TUJUAN APLIKASI FRONTEND (KASIR APP)
   Aplikasi Flutter ini berperan sebagai _User Interface_ (UI) dan pengelola _workflow_ bagi kasir swalayan. Fokus utama adalah kecepatan dan efisiensi operasional.

Menggantikan scanner fisik dengan kamera HP.
Menyediakan fungsi POS inti (keranjang, pembayaran, struk).
Menjamin interaksi yang intuitif dan cepat (UX Kasir).
TEKNOLOGI & ARSITEKTUR
Komponen Detail
Platform Utama Android (iOS Opsional)
Framework Flutter 3.x
State Management Riverpod / Provider (Disarankan Riverpod)
Barcode Scanner mobile*scanner
HTTP Client dio
Local Storage shared_preferences dan hive (untuk token dan cache)
Arsitektur MVVM + Clean Architecture Lite 2. STRUKTUR HALAMAN APLIKASI
2.1. SplashScreen
Tujuan: Cek status autentikasi dan ketersediaan token.
Flow: Jika token ada → Dashboard, Jika tidak ada → Login.
2.2. LoginPage
Fungsi: Mengirim kredensial ke API /api/login.
Keamanan: Simpan token (Sanctum) ke local storage (shared_preferences).
2.3. DashboardPage
Komponen: Card (Total Transaksi Hari Ini) dan Tombol Shortcut.
Shortcut: Mulai Transaksi, Scan Barcode, Cari Produk Manual, Riwayat Transaksi.
2.4. StartTransactionPage (POS Main Page)
Header: Nomor Transaksi (Local Generated) dan Nama Kasir (dari token).
Input Area: Tombol Scan Kamera, TextField Input Manual Barcode.
Keranjang (Cart): Daftar item dengan Nama, Harga, Kontrol Qty (+/–), Subtotal.
Summary: Total pcs, Total belanja, Tombol Bayar.
2.5. BarcodeScannerPage
Teknologi: Menggunakan mobile_scanner.
Fitur: Live scanning, Auto detect, Vibrate saat sukses scan.
Return: Mengirim kode barcode kembali ke POS Page untuk \_API lookup*.
2.7. PaymentPage
Komponen: Total Belanja, Dropdown Metode Bayar (Cash, QRIS, Debit).
Logic (Cash): Field "Uang Diterima" dan auto hitung "Kembalian".
2.8. ReceiptPage (Struk)
Tampilan: Detail Struk (Invoice, Item List, Total, Kembalian).
Aksi: Tombol "Done" (kembali ke Dashboard). 3. STRUKTUR DIREKTORI (CLEAN ARCHITECTURE LITE)
lib/
├─ data/
│ ├─ models/ (Product, User, Transaction DTOs)
│ ├─ services/ (API layer - Dio)
│ └─ repositories/ (Auth, Product, Transaction Repos)
├─ providers/ (Riverpod state management)
├─ ui/
│ ├─ pages/ (Halaman Utama)
│ ├─ widgets/ (Komponen Reusable)
│ └─ components/ (Komponen Spesifik Halaman)
├─ utils/ (Helper, Formatters)
├─ config/ (API base URL, themes)
└─ main.dart 4. DETAIL STATE MANAGEMENT (RIVERPOD)
Penggunaan Riverpod sangat diutamakan untuk reaktivitas dan _caching_.

AuthProvider: Mengelola status login, token, dan data user (kasir/admin).
ProductProvider: Melakukan _fetch_ produk, _caching_ data produk yang sering diakses.
CartProvider: Mengelola list keranjang, logika tambah/hapus/ubah qty, dan kalkulasi total harga secara _real-time_.
TransactionProvider: Mengirim data transaksi ke backend, menampilkan riwayat transaksi.
ScannerProvider: Mengelola state kamera scanner (aktif/nonaktif). 5. SERVICE LAYER (DIO & INTERCEPTOR)
Base API Class: Implementasi _timeout handling_ dan _retry logic_ untuk koneksi buruk.
Interceptor: Digunakan untuk **mengotomatisasi penambahan HTTP Header Authorization: Bearer ** di setiap request.
Error Handling Interceptor: Khusus menangani response 401 (Unauthorized) untuk memicu _auto logout_ kasir. 6. INTEGRASI API KRUSIAL
Otentikasi:
POST /api/login

Scan Barcode (Cari Produk):
GET /api/products/barcode/{barcode}

Simpan Transaksi (Checkout):
POST /api/transactions

Riwayat Transaksi:
GET /api/transactions?date=today (Riwayat harian) 7. DETAIL WIDGET REUSABLE
Komponen Fungsi Spesifik
CustomAppBar Menampilkan Nama Kasir, Status Koneksi, dan Tombol Logout.
CartItemWidget Row item di keranjang dengan kontrol Qty Counter (+ / – ) dan Price Alignment.
ScannerOverlayWidget Overlay di kamera dengan Box Transparan, Corner Highlight, dan teks panduan.
PaymentMethodTile Tombol/Tile pilihan metode bayar (Cash, QRIS, Debit) dengan Icon & Label. 8. PENANGANAN KESALAHAN (ERROR HANDLING)
API Error:
400 (Bad Request): Tampilkan pesan error spesifik dari backend (misal: "Stok tidak cukup").
401 (Unauthorized): Wajib memicu _Auto Logout_ dan navigasi ke halaman Login.
500 (Server Error): Tampilkan _snackbar_ umum "Terjadi Kesalahan Server, coba beberapa saat lagi."
Logika Bisnis & Koneksi:
Barcode Not Found: Tampilkan dialog konfirmasi: "Produk tidak ditemukan. Input manual barcode/nama?"
Koneksi Jelek: Implementasi _Retry Logic_ (misal 3x) dan tampilkan modal "Koneksi lemah, mencoba kembali...". 9. PERILAKU OFFLINE
User masih bisa: Melihat keranjang, dan melakukan _Scan Barcode_ yang hasilnya dicari di **Local Cache** (jika data produk sudah pernah di-cache).
User **Tidak Dapat:** Submit transaksi. Transaksi akan ditahan di local storage dan disinkronisasi saat koneksi kembali. 10. ATURAN UI/UX
Typography: Font Inter atau Poppins. Heading 18–20px, Body 14–16px.
Warna Utama: Biru Kasir (#247CFF), Putih (#FFFFFF), Abu Light (#E7E7E7).
Button Style: Wajib Rounded 12 dan memiliki _soft shadow_.
Spacing: Padding standar 16px. 11. OPTIMASI KINERJA
Prioritas: Penggunaan const widget.
Data: Implementasi _caching_ gambar produk (jika ada) dan data produk di lokal.
Input: Menerapkan _Debounce_ pada input barcode manual untuk mengurangi beban API.
Kamera: Melakukan _Preload_ kamera scanner.
Riverpod: Menggunakan autoDispose pada provider untuk halaman yang sifatnya sementara. 12. BUILD OUTPUT & DELIVERABLES
Output: APK release (Build siap instal).
Branding: Splash screen dan App icon "SmartPOS" harus diterapkan.
Deliverables: Flutter Project Ready to Run (Source Code), Folder structure clean, API integration lengkap, Dokumentasi (README & Postman).

flutter run --dart-define=API_BASE_URL=http://34.59.193.254/api

php artisan serve --host 0.0.0.0 --port 8000

flutter build apk --release --dart-define=API_BASE_URL=http://34.59.193.254/api