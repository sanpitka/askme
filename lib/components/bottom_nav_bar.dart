import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final void Function(int)? onTap;
  final int currentPage;
  const BottomNavBar({super.key, required this.onTap, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentPage,
      onTap: (value) => onTap!(value),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profiili',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined),
          label: 'Harjoitukset',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Asetukset',
        ),
      ],
    );
  }
}