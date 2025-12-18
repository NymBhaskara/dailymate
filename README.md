# DailyMate 🚀

[cite_start]**DailyMate** adalah platform pengembangan diri yang didesain untuk kesederhanaan dan konsistensi[cite: 783]. [cite_start]Aplikasi ini membantu pengguna membangun kebiasaan positif melalui *random task generator* (generator tugas) yang memberikan tugas mikro berdasarkan kategori fokus: Kesehatan, Sosial, atau Literatur[cite: 784, 785].

## 👥 Anggota Kelompok 5

| Nama | NRP |
| :--- | :--- |
| **Muhammad Akmal Rafiansyah** | 5026231101 |
| **I Nyoman Mahadyana Bhaskara** | 5026231162 |
| **Javier Pandapotan Valerian** | 5026231201 |
| **Redo Adika Dharmawan** | 5026231171 |

---

## ✨ Fitur Utama

1.  [cite_start]**Random Task Generator**: Mendapatkan tugas acak dari database berdasarkan kategori (Health, Social, Literature)[cite: 796].
2.  [cite_start]**Mastery Level (XP System)**: Sistem gamifikasi di mana pengguna mendapatkan XP setiap kali menyelesaikan tugas untuk menaikkan level di setiap kategori[cite: 787].
3.  [cite_start]**Task History**: Melacak riwayat tugas yang telah diselesaikan, dikelompokkan berdasarkan waktu (Today, Yesterday, Older)[cite: 807].
4.  [cite_start]**Authentication**: Login dan Sign Up aman menggunakan Supabase Auth[cite: 873].

---

## 🛠️ Teknologi yang Digunakan

* [cite_start]**Frontend Framework**: Flutter (Dart) [cite: 873]
* [cite_start]**Backend & Database**: Supabase (PostgreSQL) [cite: 863]
* [cite_start]**Fitur Supabase**: Authentication, Database (CRUD), Realtime[cite: 873].

---

## 📂 Struktur Folder

Berikut adalah struktur folder utama dalam folder `lib/` proyek ini:

```text
lib/
├── env.dart             # Konfigurasi Environment (API Keys Supabase)
├── history_page.dart    # Halaman riwayat tugas yang sudah selesai
├── home_page.dart       # Halaman utama (Generate Task & Task List)
├── login_page.dart      # Halaman Login dan Registrasi
├── main.dart            # Entry point aplikasi & Auth Wrapper
└── profile_page.dart    # Halaman profil pengguna & Mastery Progress
