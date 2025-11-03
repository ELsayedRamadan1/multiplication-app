import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/multiplication_table_model.dart';
import '../theme_provider.dart';

// Function to convert English digits to Arabic
String _toArabicNumber(int number) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  
  String result = number.toString();
  for (int i = 0; i < english.length; i++) {
    result = result.replaceAll(english[i], arabic[i]);
  }
  return result;
}

class TableScreen extends StatelessWidget {
  final MultiplicationTable table;

  const TableScreen({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('جدول ${table.number}'),
        backgroundColor: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
            ? Colors.black
            : Colors.blue.shade800,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                ? [Colors.grey.shade900, Colors.black]
                : [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: table.multiplications.length,
          itemBuilder: (context, index) {
            int multiplier = index + 1;
            int result = table.multiplications[index];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                    ? Colors.grey.shade800
                    : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                      ? Colors.blueAccent
                      : Colors.blue.shade700,
                  child: Text(_toArabicNumber(table.number), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: Text(
                  '${_toArabicNumber(table.number)} × ${_toArabicNumber(multiplier)} = ${_toArabicNumber(result)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  textDirection: TextDirection.rtl,
                ),
                trailing: Icon(Icons.arrow_forward, color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                    ? Colors.blueAccent
                    : Colors.blue.shade700),
                onTap: () {},
              ),
            );
          },
        ),
      ),
    );
  }
}
