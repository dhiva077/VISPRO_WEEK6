## Step 11 – Reflection Questions

### 1. Apa perbedaan antara route di Flutter dan deep link di Android?
Route di Flutter adalah jalur navigasi internal antar halaman (widget) di dalam aplikasi yang hanya berlaku saat aplikasi berjalan.
Sedangkan deep link berada di level sistem Android dan berfungsi sebagai pintu masuk dari luar aplikasi (seperti browser atau aplikasi lain) untuk membuka halaman tertentu di dalam aplikasi Flutter.

### 2. Mengapa Android memerlukan intent filter?
Android membutuhkan intent-filter agar sistem tahu jenis tautan atau aksi apa yang bisa ditangani oleh aplikasi kita.
Dengan adanya intent filter, sistem Android dapat mengarahkan tautan dengan skema tertentu (misalnya myapp://details/...) agar dibuka menggunakan aplikasi kita.

### 3. Apa peran package app_links?
ackage app_links berfungsi sebagai jembatan antara sistem native Android (yang mengirim intent saat deep link dibuka) dengan Flutter.
Package ini mendengarkan tautan yang masuk melalui stream dan mengirimkan data URI ke Flutter, sehingga aplikasi dapat menavigasi ke halaman yang sesuai.

### 4. Apa yang terjadi jika deep link dibuka saat app sudah berjalan?
Jika aplikasi sudah terbuka, deep link tidak akan memulai ulang aplikasi.
Sebaliknya, stream listener (uriLinkStream) akan mendeteksi tautan baru dan langsung menjalankan fungsi _handleLink() untuk berpindah ke halaman yang sesuai tanpa restart.

### 5. Jika adb membuka app tapi tidak navigasi ke halaman detail, apa yang kamu cek?
Pertama, periksa bagian <intent-filter> di file AndroidManifest.xml — pastikan nilai android:scheme dan android:host sesuai dengan yang digunakan di perintah adb.
Jika itu sudah benar, langkah berikutnya adalah memeriksa fungsi _handleLink() di Flutter untuk memastikan URI diparsing dengan benar dan Navigator.push() dijalankan dengan parameter yang tepat.

### Step 13: Wrap-Up Summary

Deep linking menghubungkan sistem navigasi Flutter dengan Android melalui intent filter, sehingga aplikasi dapat terbuka langsung ke halaman tertentu dari tautan eksternal.
Fitur ini sangat berguna untuk membuka halaman tertentu dari notifikasi, email, atau tautan berbagi.
Tantangan utama saya adalah konfigurasi AndroidManifest.xml agar scheme dan host dikenali, tetapi berhasil setelah menambahkan intent filter yang sesuai dan memperbaiki logika parsing di Flutter.
