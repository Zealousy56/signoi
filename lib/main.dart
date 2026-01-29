import 'package:flutter/material.dart';
import 'package:signoi/pages/home.dart';
import 'package:signoi/pages/noise.dart';
import 'package:signoi/pages/progress.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Highway Gothic'),
      
      home: const RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _sharedItems = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _shortTermItems = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _homePageItems = <Map<String, dynamic>>[]; // Items displayed on home page

  void _updateSharedItems(List<Map<String, dynamic>> newItems) {
    setState(() {
      _sharedItems = newItems;
    });
  }

  void _updateShortTermItems(List<Map<String, dynamic>> newItems) {
    setState(() {
      _shortTermItems = newItems;
    });
  }

  void _updateHomePageItems(List<Map<String, dynamic>> newItems) {
    setState(() {
      _homePageItems = newItems;
    });
  }

  void _onTap(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) { 
    final List<Widget> pages = <Widget>[
      HomePage(
        items: _homePageItems,
        onItemsChanged: _updateHomePageItems,
        shortTermItems: _shortTermItems,
        onShortTermItemsChanged: _updateShortTermItems,
        sharedItems: _sharedItems,
        onSharedItemsChanged: _updateSharedItems,
      ),
      const NoisePage(),
      ProgressPage(
        items: _sharedItems,
        onItemsChanged: _updateSharedItems,
        shortTermItems: _shortTermItems,
        onShortTermItemsChanged: _updateShortTermItems,
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.wifi), label: 'Signal'),
          BottomNavigationBarItem(icon: Icon(Icons.graphic_eq), label: 'Noise'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Progress'),
        ],
      ),
    );
  }
}