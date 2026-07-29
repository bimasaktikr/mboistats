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

    if (currentRoute == '/data' || currentRoute == '/berita') {
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
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
          return false;
        }
        return true;
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Colors.white,
          selectedItemColor: blueNormal,
          unselectedItemColor: const Color(0xFF8E8E93),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: pjsSemiBold12,
          unselectedLabelStyle: pjsRegular12,
          items: [
            BottomNavigationBarItem(
              icon: Image.asset(
                _selectedIndex == 0
                    ? 'assets_v2/navbar/beranda_on.png'
                    : 'assets_v2/navbar/beranda_off.png',
                width: 24,
                height: 24,
              ),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                _selectedIndex == 1
                    ? 'assets_v2/navbar/data_on.png'
                    : 'assets_v2/navbar/data_off.png',
                width: 24,
                height: 24,
              ),
              label: 'Data',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                _selectedIndex == 2
                    ? 'assets_v2/navbar/kontak_on.png'
                    : 'assets_v2/navbar/kontak_off.png',
                width: 24,
                height: 24,
              ),
              label: 'Kontak',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                _selectedIndex == 3
                    ? 'assets_v2/navbar/profil_on.png'
                    : 'assets_v2/navbar/profil_off.png',
                width: 24,
                height: 24,
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
