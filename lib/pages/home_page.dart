import 'package:flutter/material.dart';
//import '../components/bottom_nav_bar.dart';
import 'excercises_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final List<Widget> _pages = [
    const ProfilePage(),
    const ExercisesPage(),
    const SettingsPage(),
  ];

  int currentPage = 1;

  void navigateBottomBar(int index) {
    setState(() {
      currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*bottomNavigationBar: BottomNavBar(
        onTap: (index) => navigateBottomBar(index),
        currentPage: currentPage,
      ),*/
      body: _pages[currentPage],
    );
  }
}
