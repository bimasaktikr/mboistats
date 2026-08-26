# DESIGN.md - Mboistats UI Redesign Guidelines (v2)

Dokumen ini berisi panduan desain sistem dan spesifikasi pembaruan antarmuka pengguna (UI) untuk aplikasi **Mboistats (BPS Kota Malang)** pada branch `dev/v2`. Pembaruan ini bertujuan untuk memodernisasi tampilan, meningkatkan *User Experience* (UX), serta menyelaraskan identitas visual data statistik BPS.

---

## 1. Ringkasan & Visi Redesign (v2)

Pembaruan UI pada versi `dev/v2` berfokus pada tiga pilar utama:
* **Clean & Modern Data Presentation**: Penyajian indikator statistik strategis (Inflasi, PDRB, Kemiskinan, Tenaga Kerja) dengan tampilan visual yang lebih bersih dan mudah dipahami masyarakat.
* **Intuitive Navigation**: Pembaruan struktur *Bottom Navigation Bar* dan perbaikan hirarki menu utama.
* **Centralized Asset Management**: Pengelompokan aset desain baru yang terstruktur di dalam direktori `assets_v2/`.

---

## 2. Struktur Aset (`assets_v2/`)

Seluruh aset visual baru dialokasikan pada direktori `assets_v2/` dengan pembagian fungsi sebagai berikut:

```text
assets_v2/
├── colors/      # Acuan palet warna, panduan kontras, dan desain token
├── fonts/       # File font kustom (SF Pro Display / SF Pro Text)
├── icons/       # Ikon vektor (SVG/PNG) untuk antarmuka & fitur
├── navbar/      # Aset visual & spesifikasi Bottom Navigation Bar
└── pages/       # Mockup, wireframe, & acuan tata letak halaman aplikasi