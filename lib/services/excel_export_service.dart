import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_model.dart';

class ExcelExportService {
  // تصدير بيانات الطلاب كملف Excel
  Future<String?> exportStudentsToExcel(List<User> students) async {
    try {
      // طلب إذن التخزين (Android)
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // Try manage external storage on newer Android if available
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            throw Exception('يجب منح إذن الوصول إلى التخزين');
          }
        }
      }

      // إنشاء ملف Excel جديد
      var excel = Excel.createExcel();
      // الحصول على ورقة (ستُنشأ إذا لم تكن موجودة)
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

      // كتابة الرأس كسلاسل نصية
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
      }

      // إضافة بيانات الطلاب
      for (int i = 0; i < students.length; i++) {
        User student = students[i];
        int rowIndex = i + 1;

        List<dynamic> rowData = [
          i + 1,
          student.name,
          student.email,
          student.school,
          student.grade,
          student.classNumber,
          student.totalScore,
          student.totalQuizzesCompleted,
          _formatDate(student.createdAt),
        ];

        for (int j = 0; j < rowData.length; j++) {
          var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex));
          cell.value = _toCellValue(rowData[j]);
        }
      }

      // إضافة ورقة ملخص
      Sheet summarySheet = excel['الملخص'];
      summarySheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('إجمالي عدد الطلاب');
      summarySheet.cell(CellIndex.indexByString('B1')).value = IntCellValue(students.length);

      summarySheet.cell(CellIndex.indexByString('A2')).value = TextCellValue('متوسط النقاط');
      double avgScore = students.isEmpty
          ? 0
          : students.map((s) => s.totalScore).reduce((a, b) => a + b) / students.length;
      summarySheet.cell(CellIndex.indexByString('B2')).value = DoubleCellValue(avgScore);

      // حذف الورقة الافتراضية إذا كانت موجودة
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // حفظ الملف
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = 'students_data_$timestamp.xlsx';

      Directory? directory;
      if (Platform.isAndroid) {
        // Prefer public Download folder on Android
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // fallback to external storage directory provided by path_provider
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        // desktop or other platforms
        try {
          directory = await getDownloadsDirectory();
        } catch (e) {
          directory = await getApplicationDocumentsDirectory();
        }
      }

      if (directory == null) {
        throw Exception('لا يمكن الوصول إلى مجلد التنزي��ات');
      }

      String filePath = '${directory.path}${Platform.pathSeparator}$fileName';
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

  CellValue _toCellValue(dynamic v) {
    if (v == null) return TextCellValue('');
    if (v is int) return IntCellValue(v);
    if (v is double) return DoubleCellValue(v);
    return TextCellValue(v.toString());
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
