import 'package:flutter/material.dart';

class AppTheme {
  // Paleta de colores centralizada — v1.0.1
  static const Color _primary = Color(0xFF5C35CC);    // Índigo profundo
  static const Color _secondary = Color(0xFF00BFA5);  // Teal vibrante
  static const Color _surface = Color(0xFFF5F3FF);    // Lavanda muy claro
  static const Color _onPrimary = Colors.white;
  static const Color _drawerBg = Color(0xFF1E1B4B);   // Índigo oscuro para drawer

  //! tema claro
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        primary: _primary,
        secondary: _secondary,
        surface: _surface,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      // ── AppBar ──────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: _onPrimary,
        titleTextStyle: TextStyle(
          color: _onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: _onPrimary),
      ),
      // ── Drawer ──────────────────────────────────────────
      drawerTheme: const DrawerThemeData(
        elevation: 4,
        backgroundColor: _drawerBg,
      ),
      // ── Floating Action Button ───────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _secondary,
        foregroundColor: Colors.white,
      ),
      // ── ElevatedButton ──────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: _onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      // ── Card ────────────────────────────────────────────
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      // ── Tipografía ──────────────────────────────────────
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF1E1B4B), fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xFF3D3878), fontSize: 14),
        titleLarge: TextStyle(
          color: _primary,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
        labelLarge: TextStyle(color: _primary, fontWeight: FontWeight.w600),
      ),
      // ── IconTheme general ───────────────────────────────
      iconTheme: const IconThemeData(color: _primary),
      // ── ListTile (para el Drawer) ────────────────────────
      listTileTheme: const ListTileThemeData(
        iconColor: _secondary,
        textColor: Colors.white70,
        selectedColor: _secondary,
      ),
    );
  }
}
