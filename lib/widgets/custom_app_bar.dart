import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final Color? color;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final double elevation;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.color,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.elevation = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the Theme's AppBarTheme when available so all app bars are consistent
    final theme = Theme.of(context);
    final appBarTheme = theme.appBarTheme;
    final Color base = appBarTheme.backgroundColor ?? color ?? (theme.brightness == Brightness.dark ? Colors.black : Colors.blue.shade800);
    final double? toolbarH = appBarTheme.toolbarHeight;

    return AppBar(
      title: Text(title, style: appBarTheme.titleTextStyle ?? const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      centerTitle: centerTitle,
      elevation: elevation,
      toolbarHeight: toolbarH,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      bottom: bottom,
      backgroundColor: base,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.brightness == Brightness.dark
                ? [Colors.grey.shade900, Colors.black]
                : [base.withOpacity(0.98), base.withOpacity(0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
