import 'package:flutter/material.dart';
import 'About_page.dart'; // Import HomePage
import 'HistoryPage.dart';
import 'HomePage.dart';
import 'HomePage2.dart';
import 'logout_page.dart';


class BottomNavBar extends StatefulWidget {
  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [

    HistoryPage(),
    ImageClassificationPage(),
    ImageClassificationPage2(),
    AboutPage(),
    LogoutPage(),
  ];

  void _onItemTapped(int index) {
    if (index == 5) {
      // Simulate logout logic if needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged out! Returning to login screen...')),
      );
      Future.delayed(Duration(seconds: 5), () {
        // Perform logout action or navigate to login page
      });
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.history, color: Colors.orange),
            label: 'History of Use',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt, color: Colors.red),
            label: 'x-ray',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera, color: Colors.green),
            label: 'ct-scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info, color: Colors.blue),
            label: 'About',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.exit_to_app, color: Colors.purple),
            label: 'Logout',
          ),
        ],
      ),
    );
  }
}
