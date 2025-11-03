import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_model.dart';

class ExcelExportService {
  // تصدير بيانات الطلاب كملف Excel
  Future<String?> exportStudentsToExcel(List<User> students) async {
    try {
      // طلب إذن التخزين
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('يجب منح إذن الوصول إلى التخزين');
        }
      }

      // إنشاء ملف Excel جديد
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['بيانات الطلاب'];

      // إضافة الرأس (العناوين)
      List<String> headers = [
        'الرقم',
        'الاسم الكامل',
        'البريد الإلكتروني',
        'المدرسة',
        'الصف',
        'الفصل',
        'المجموع الكلي',
        'عدد الاختبارات المكتملة',
        'تاريخ الإنشاء'
      ];

      // تنسيق الرأس
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue,
          fontColorHex: ExcelColor.white,
        );
      }

      // إضافة بيانات الطلاب
      for (int i = 0; i < students.length; i++) {
        User student = students[i];
        int rowIndex = i + 1;

        List<CellValue> rowData = [
          IntCellValue(i + 1),
          TextCellValue(student.name),
          TextCellValue(student.email),
          TextCellValue(student.school),
          IntCellValue(student.grade),
          IntCellValue(student.classNumber),
          IntCellValue(student.totalScore),
          IntCellValue(student.totalQuizzesCompleted),
          TextCellValue(_formatDate(student.createdAt)),
        ];

        for (int j = 0; j < rowData.length; j++) {
          var cell = sheetObject.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = rowData[j];
        }
      }

      // إضافة ورقة ملخص
      Sheet summarySheet = excel['الملخص'];
      summarySheet.cell(CellIndex.indexByString('A1')).value =
          TextCellValue('إجمالي عدد الطلاب');
      summarySheet.cell(CellIndex.indexByString('B1')).value =
          IntCellValue(students.length);

      summarySheet.cell(CellIndex.indexByString('A2')).value =
          TextCellValue('متوسط النقاط');
      double avgScore = students.isEmpty
          ? 0
          : students.map((s) => s.totalScore).reduce((a, b) => a + b) /
              students.length;
      summarySheet.cell(CellIndex.indexByString('B2')).value =
          DoubleCellValue(avgScore);

      // تنسيق ورقة الملخص
      summarySheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.green,
        fontColorHex: ExcelColor.white,
      );
      summarySheet.cell(CellIndex.indexByString('A2')).cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.green,
        fontColorHex: ExcelColor.white,
      );

      // حذف الورقة الافتراضية إذا كانت موجودة
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // حفظ الملف
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = 'students_data_$timestamp.xlsx';

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        throw Exception('لا يمكن الوصول إلى مجلد التنزيلات');
      }

      String filePath = '${directory.path}/$fileName';
      File file = File(filePath);

      // حفظ البيانات
      var fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        return filePath;
      } else {
        throw Exception('فشل في إنشاء الملف');
      }
    } catch (e) {
      print('خطأ في تصدير البيانات: $e');
      rethrow;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
