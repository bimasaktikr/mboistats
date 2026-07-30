import 'package:flutter/material.dart';
import 'package:mboistats/theme.dart';

class Footer extends StatefulWidget {
  const Footer({Key? key}) : super(key: key);

  @override
  _FooterState createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  int _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentRoute = ModalRoute.of(context)!.settings.name;

    if (currentRoute == '/data' ||
        currentRoute == '/berita' ||
        currentRoute == '/infografis_full' ||
        currentRoute == '/publikasi_full' ||
        currentRoute == '/infografis' ||
        currentRoute == '/publikasi') {
      _selectedIndex = 1;
    } else if (currentRoute == '/contact') {
      _selectedIndex = 2;
    } else if (currentRoute == '/profil' || currentRoute == '/edit_profil') {
      _selectedIndex = 3;
    } else {
      _selectedIndex = 0; // Beranda default
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
        break;
      case 1:
        if (_selectedIndex != 0) {
          Navigator.of(context).pushReplacementNamed('/data');
        } else {
          Navigator.of(context).pushNamed('/data');
        }
        break;
      case 2:
        if (_selectedIndex != 0) {
          Navigator.of(context).pushReplacementNamed('/contact');
        } else {
          Navigator.of(context).pushNamed('/contact');
        }
        break;
      case 3:
        if (_selectedIndex != 0) {
          Navigator.of(context).pushReplacementNamed('/profil');
        } else {
          Navigator.of(context).pushNamed('/profil');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
          return false;
        }
        return true;
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, -3),
            ),
          ],
        ),
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            backgroundColor: Colors.transparent,
            selectedItemColor: blueNormal,
            unselectedItemColor: const Color(0xFF8E8E93),
            selectedFontSize: 13,
            unselectedFontSize: 13,
            selectedLabelStyle: pjsSemiBold14,
            unselectedLabelStyle: pjsMedium12,
            items: [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Image.asset(
                    _selectedIndex == 0
                        ? 'assets_v2/navbar/beranda_on.png'
                        : 'assets_v2/navbar/beranda_off.png',
                    width: 28,
                    height: 28,
                  ),
                ),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Image.asset(
                    _selectedIndex == 1
                        ? 'assets_v2/navbar/data_on.png'
                        : 'assets_v2/navbar/data_off.png',
                    width: 28,
                    height: 28,
                  ),
                ),
                label: 'Data',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Image.asset(
                    _selectedIndex == 2
                        ? 'assets_v2/navbar/kontak_on.png'
                        : 'assets_v2/navbar/kontak_off.png',
                    width: 28,
                    height: 28,
                  ),
                ),
                label: 'Kontak',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Image.asset(
                    _selectedIndex == 3
                        ? 'assets_v2/navbar/profil_on.png'
                        : 'assets_v2/navbar/profil_off.png',
                    width: 28,
                    height: 28,
                  ),
                ),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
