import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mboistats/theme.dart';
import 'package:mboistats/services/recommendation_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  String _userType = '';

  // State Pilihan
  String? _selectedMajor;
  final List<String> _selectedSectors = [];
  bool _isLoading = false;
  String _majorSearchQuery = '';
  Timer? _debounceTimer;

  // Daftar Jurusan (Single Source of Truth dari RecommendationService / Supabase)
  List<String> _majors = RecommendationService.defaultMajorSectorMapping.keys.toList();

  @override
  void initState() {
    super.initState();
    _loadMajorsFromSupabase();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadMajorsFromSupabase() async {
    final mapping = await RecommendationService.getMajorSectorMapping();
    if (mounted && mapping.isNotEmpty) {
      setState(() {
        _majors = mapping.keys.toList();
      });
    }
  }

  // Daftar Sektor & Info Label Visual
  final List<Map<String, String>> _sectors = [
    {'key': 'perekonomian', 'title': 'Perekonomian', 'desc': 'LPE, PDRB & Laju Ekonomi'},
    {'key': 'tenaga_kerja', 'title': 'Tenaga Kerja', 'desc': 'TPAK, TPT & Ketenagakerjaan'},
    {'key': 'ipm', 'title': 'IPM', 'desc': 'Indeks Pembangunan Manusia'},
    {'key': 'kemiskinan', 'title': 'Kemiskinan', 'desc': 'Tingkat & Indeks Kemiskinan'},
    {'key': 'kependudukan', 'title': 'Kependudukan', 'desc': 'Penduduk & Demografi Wilayah'},
    {'key': 'kesejahteraan', 'title': 'Kesejahteraan', 'desc': 'Gini Rasio & Pengeluaran Perkapita'},
    {'key': 'pertanian', 'title': 'Pertanian', 'desc': 'Produksi Padi & Hasil Panen'},
  ];

  // Mengubah Pilihan Jurusan & Pre-Select Sektor
  void _onMajorSelected(String major) async {
    setState(() {
      _selectedMajor = major;
    });

    // Ambil default sektor yang relevan (offline/online)
    final sectors = await RecommendationService.getRelevantSectorsForMajor(major);
    
    setState(() {
      _selectedSectors.clear();
      _selectedSectors.addAll(sectors);
    });

    // Pindah ke slide berikutnya dengan delay kecil agar animasi halus
    Future.delayed(const Duration(milliseconds: 300), () {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  // Toggle Sektor Pilihan secara Manual
  void _toggleSector(String sectorKey) {
    setState(() {
      if (_selectedSectors.contains(sectorKey)) {
        _selectedSectors.remove(sectorKey);
      } else {
        _selectedSectors.add(sectorKey);
      }
    });
  }

  // Menyimpan data onboarding & Keluar
  void _submitOnboarding() async {
    if (_selectedMajor == null) return;
    
    setState(() {
      _isLoading = true;
    });

    // Simpan ke Supabase via device_id
    await RecommendationService.saveProfile(_selectedMajor!, _selectedSectors);

    setState(() {
      _isLoading = false;
    });

    // Pindah ke Halaman Utama dan bersihkan stack navigasi
    Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
                onPressed: () {
                  int targetPage = _currentStep - 1;
                  if (_userType == 'umum' && _currentStep == 2) {
                    targetPage = 0;
                  }
                  _pageController.animateToPage(
                    targetPage,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                  );
                },
              )
            : null,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            _userType == 'mahasiswa' ? 3 : 2,
            (index) {
              int displayStep = _currentStep;
              if (_userType != 'mahasiswa' && _currentStep == 2) {
                displayStep = 1;
              }
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: displayStep == index ? blue1 : Colors.grey.shade300,
                ),
              );
            },
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentStep = page;
                });
              },
              physics: const NeverScrollableScrollPhysics(), // Mencegah geser manual tanpa memilih
              children: [
                _buildUserTypeStep(),
                _buildMajorStep(),
                _buildSectorStep(),
              ],
            ),
    );
  }

  // Slide 0: Tipe Pengguna
  Widget _buildUserTypeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Selamat Datang di Mboisstats+",
            style: bold18.copyWith(color: dark1, fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            "Pilih tipe pengguna Anda untuk mempersonalisasi pengalaman Mboisstats+.",
            style: regular14.copyWith(color: dark3),
          ),
          const SizedBox(height: 24),
          _buildUserTypeCard(
            type: 'umum',
            title: 'Umum',
            icon: Icons.public,
            desc: 'Saya masyarakat umum yang ingin mengakses data statistik',
          ),
          const SizedBox(height: 16),
          _buildUserTypeCard(
            type: 'mahasiswa',
            title: 'Mahasiswa',
            icon: Icons.school,
            desc: 'Saya mahasiswa yang membutuhkan data untuk penelitian',
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeCard({
    required String type,
    required String title,
    required IconData icon,
    required String desc,
  }) {
    final isSelected = _userType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _userType = type;
        });
        if (type == 'umum') {
          setState(() {
            _selectedMajor = 'Umum';
            _selectedSectors.clear();
          });
          Future.delayed(const Duration(milliseconds: 300), () {
            _pageController.animateToPage(
              2, // Skip jurusan, jump to sector
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          });
        } else {
          Future.delayed(const Duration(milliseconds: 300), () {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? blue1.withOpacity(0.05) : Colors.white,
          border: Border.all(
            color: isSelected ? blue1 : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: isSelected ? blue1 : dark3),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: bold16.copyWith(color: isSelected ? blue1 : dark1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: regular14.copyWith(color: dark3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Slide 1: Pemilihan Jurusan
  Widget _buildMajorStep() {
    final filteredMajors = _majors
        .where((m) => m.toLowerCase().contains(_majorSearchQuery.toLowerCase()))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Pilih Jurusan Anda",
            style: bold18.copyWith(color: dark1, fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            "Pilih latar belakang akademik Anda untuk memetakan visualisasi awal yang relevan.",
            style: regular14.copyWith(color: dark3),
          ),
          const SizedBox(height: 16),

          // Search Field untuk Jurusan
          TextField(
            onChanged: (val) {
              _debounceTimer?.cancel();
              _debounceTimer = Timer(const Duration(milliseconds: 250), () {
                if (mounted) {
                  setState(() {
                    _majorSearchQuery = val;
                  });
                }
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari jurusan Anda (mis: Informatika, Ekonomi, Hukum)...',
              hintStyle: regular14.copyWith(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: blueLight, size: 22),
              suffixIcon: _majorSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _debounceTimer?.cancel();
                        setState(() {
                          _majorSearchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: const Color(0xFFF7FDFF),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: blueLight, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (filteredMajors.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      'Jurusan tidak ditemukan',
                      style: semibold14.copyWith(color: dark2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pilih opsi "Lainnya" jika jurusan Anda tidak ada pada daftar.',
                      style: regular12_5.copyWith(color: dark3),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredMajors.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final major = filteredMajors[index];
                final isSelected = _selectedMajor == major;
                return InkWell(
                  onTap: () => _onMajorSelected(major),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? blue1.withOpacity(0.05) : Colors.white,
                      border: Border.all(
                        color: isSelected ? blue1 : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            major,
                            style: semibold14.copyWith(
                              color: isSelected ? blue1 : dark1,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: blue1)
                        else
                          const Icon(Icons.circle_outlined, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // Slide 2: Pemilihan & Kustomisasi Sektor
  Widget _buildSectorStep() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Personalisasikan Minat Anda",
                  style: bold18.copyWith(color: dark1, fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  _userType == 'umum'
                      ? "Pilih sektor statistik yang Anda minati. Minimum 2 pilihan."
                      : "Sektor di bawah telah kami tandai berdasarkan jurusan Anda. Anda bebas menambah atau menghilangkannya.",
                  style: regular14.copyWith(color: dark3),
                ),
                const SizedBox(height: 8),
                Text(
                  "Pilih minimal 2 sektor yang diminati",
                  style: regular12_5.copyWith(color: blue1, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sectors.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final sector = _sectors[index];
                    final key = sector['key']!;
                    final isSelected = _selectedSectors.contains(key);
                    return InkWell(
                      onTap: () => _toggleSector(key),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? blue1.withOpacity(0.05) : Colors.white,
                          border: Border.all(
                            color: isSelected ? blue1 : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sector['title']!,
                                    style: semibold14.copyWith(
                                      color: isSelected ? blue1 : dark1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    sector['desc']!,
                                    style: regular12_5.copyWith(color: dark3),
                                  ),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: isSelected,
                              activeColor: blue1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (val) => _toggleSector(key),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // Tombol Submit / Simpan
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: blue1,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _selectedSectors.length < 2 ? null : _submitOnboarding,
              child: Text(
                "Selesai & Masuk Aplikasi",
                style: bold16.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
