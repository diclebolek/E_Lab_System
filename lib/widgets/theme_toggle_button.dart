import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return IconButton(
          icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          tooltip: themeProvider.isDarkMode ? 'Açık Mod' : 'Koyu Mod',
          onPressed: () {
            themeProvider.toggleTheme();
          },
        );
      },
    );
  }
}

