import 'package:flutter/material.dart';
import 'package:smart_wrong_notebook/src/core/constants/app_strings.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: const SizedBox.expand(),
        bottomNavigationBar: NavigationBar(
          destinations: const <Widget>[
            NavigationDestination(icon: Icon(Icons.home_outlined), label: AppStrings.homeTab),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: AppStrings.notebookTab),
            NavigationDestination(icon: Icon(Icons.refresh_outlined), label: AppStrings.reviewTab),
            NavigationDestination(icon: Icon(Icons.settings_outlined), label: AppStrings.settingsTab),
          ],
          selectedIndex: 0,
        ),
      ),
    );
  }
}
