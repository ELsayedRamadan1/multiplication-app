# Multiplication Master

تطبيق تعليمي لإدارة واختبار طلاب جدول الضرب، مع واجهة للمعلمين لإدارة الأسئلة والواجبات، وللطلبة للاختبار ومراجعة الجداول.

هذا المستودع يحتوي على مشروع Flutter (Android / iOS / web / desktop) مهيأ للعمل مع Firebase (Authentication و Firestore). هذا الملف يشرح كيفية تشغيل المشروع محليًا، إعداد بيئة Firebase، والممارسات المطلوبة للمساهمة في المشروع.

---

## المحتويات
- نظرة عامة
- المزايا الرئيسية
- المتطلبات المسبقة
- إعداد المشروع محليًا
- إعداد Firebase (موجز)
- تشغيل التطبيق
- التطوير والاختبار
- أسلوب البرمجة والـ Lint
- مقترحات للـ CI/CD
- بنية المشروع
- كيفية المساهمة
- الترخيص

---

## نظرة عامة
Multiplication Master (أحيانًا يظهر في الكود كـ `multiplication_table_app`) هو تطبيق تعليمي يوفِّر:
- لوحة للمعلمين لإنشاء أسئلة مخصصة وواجبات ومراجعة نتائج الطلاب.
- واجهة للطلاب لحل اختبارات جدول الضرب وتتبع الأداء.
- تخزين مدمج في Firebase Firestore ومصادقة عبر Firebase Auth (بما في ذلك Google Sign-In).

المشروع مصمّم ليعمل على منصات متعددة (Android، iOS، web، Windows، macOS، Linux) باستخدام Flutter.

## المزايا الرئيسية
- إنشاء أسئلة نصية وصورية.
- إنشاء واجبات (يدويًا أو عشوائيًا) وتعيين طلاب.
- تصفية الطلاب حسب الصف والفصل للمعلمين مع حفظ الإعداد كـ default.
- تسجيل/تسجيل دخول عبر البريد أو Google.
- تصدير نتائج إلى CSV (على الأجهزة الداعمة).

## المتطلبات المسبقة
- Flutter SDK (البيئة المتوافقة كما في `pubspec.yaml`): SDK >= 3.8.1
- Android SDK / Xcode setup إذا كنت تستهدف Android / iOS
- حساب Firebase مع مشروع مفعل (Authentication, Firestore)
- أدوات بناء إن أردت بناء نسخة Android: `gradle`, `adb`، وبيئة Java المناسبة

تأكد من تثبيت Flutter وتشغيل `flutter doctor` قبل المتابعة.

## إعداد المشروع محليًا
1. استنساخ المستودع:

```bash
git clone <repo-url>
cd multiplication_table_app
```

2. تثبيت الحزم:

```bash
flutter pub get
```

3. إعداد مفاتيح / ملفات Firebase:
- الملف `android/app/google-services.json` موجود في المستودع (تحقّق أن المشروع المرتبط هو مشروعك أو استبدله بملفك).
- يوجد ملف `lib/firebase_options.dart` في المشروع؛ إذا كنت تستبدل مشروع Firebase فأنشئ ملف الإعدادات عبر `flutterfire configure` أو استخدم إعداداتك ثم اكتب الملف/استبدله.

4. إعدادات محلية إضافية (Android):
- تأكد من أن `local.properties` يحتوي على مسار `sdk.dir` الصحيح. عند فتح المشروع في Android Studio عادة يُنشأ تلقائيًا.

## إعداد Firebase (موجز)
1. أنشئ مشروعًا في Firebase Console.
2. فعّل Authentication (Email/Password, Google Sign-In إن رغبت).
3. أنشئ قاعدة بيانات Firestore وقواعد أمان مناسبة (راجع قسم الأمان في README أدناه).
4. أضف تطبيق Android و/أو iOS وأحصل على ملفات `google-services.json` و `GoogleService-Info.plist` وضعها في المسارات المناسبة.
5. اگر أردت تهيئة `lib/firebase_options.dart` استخدم أداة `flutterfire cli`:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

> ملحوظة: المشروع يحتوي على أمثلة لطريقة حفظ إعدادات المعلم (teacherDefaultGrade / teacherDefaultClassNumber) — تأكد من أن مستندات المستخدم تتضمن الحقول المناسبة.

## تشغيل التطبيق
- لتشغيل على Android (جهاز أو محاكي):

```bash
flutter run -d android
```

- لتشغيل على iOS (Mac + Xcode):

```bash
flutter run -d ios
```

- لتشغيل على الويب:

```bash
flutter run -d chrome
```

- لبناء APK للإصدار:

```bash
flutter build apk --release
```

## التطوير والاختبار
- تحليل الشيفرة (static analysis):

```bash
flutter analyze
```

- تشغيل الاختبارا�� الوحدوية (إن وُجدت):

```bash
flutter test
```

- تشغيل linters: المشروع يستخدم `flutter_lints` (انظر `pubspec.yaml`). ننصح بتشغيل `dart fix --apply` بين الحين والآخر للتوافق.

## أسلوب البرمجة وجودة الشيفرة
- استخدم Provider كحاليًا لإدارة الحالة. من المستحسن التفكير بالترقي إلى Riverpod أو Bloc لفصل المنطق بصورة أوضح في المستقبل.
- احرص على إلغاء `StreamSubscription` وإلغاء الـ timers أو أي callback عند `dispose()` لتجنب أخطاء مثل `setState() called after dispose`.
- راجع تحذيرات `withOpacity` وغيّرها إلى الطرق الموصى بها عند الحاجة.

## اقتراحات 개선 (مقترحات تم تنفيذ بعضها)
- استخراج الحوارات المتكررة إلى مكونات قابلة لإعادة الاستخدام (مثل Student Selector, Assignment Form).
- إضافة تخزين محلي (Hive/SQLite) لتعزيز العمل في وضع عدم الاتصال.
- إضافة مراقبة أخطاء مركزيّة (Crashlytics / Sentry).
- إعداد CI مثل GitHub Actions لتشغيل `flutter analyze`, `flutter test`, و `flutter format --set-exit-if-changed`.

## بنية المشروع (سريعة)
- `lib/main.dart` - نقطة الدخول
- `lib/screens/` - شاشات التطبيق
- `lib/widgets/` - مكونات واجهة قابلة لإعادة الاستخدام
- `lib/services/` - منطق العمل مع Firestore/Auth وعمليات التطبيق
- `lib/models/` - موديلات البيانات

## قواعد أمان Firestore (ملاحظة)
عند رفع المشروع إلى GitHub لا تترك قواعد كونفج Firebase ضعيفة. حدّد قواعد Firestore بحيث:
- يقرأ الطالب بياناته فقط.
- يقرأ المعلم قائمة طلابه فقط أو قاعدة بيانات عامة تعتمد على المدرسة/المعلم.
- عمليات كتابة الواجبات/الأسئلة تجري فقط عبر المستخدم المصرّح (المعلّم).

راجع `firestore.rules` في هذا المستودع لتعديل أو تخصيص القواعد حسب هيكل بياناتك.

## كيف تساهم؟
1. افتح issue لشرح الميزة أو المشكلة.
2. اعمل فرعًا جديدًا من `main`:

```bash
git checkout -b feat/your-feature
```

3. نفّذ التغييرات وأضف unit/widget tests للميزات الحساسة.
4. ارفع Pull Request مع شرح التغييرات.

النقاط المطلوبة في PR:
- وصف التغيير بالإنجليزية/العربية.
- لقطات شاشة إن تغيّرت واجهة المستخدم.
- أي متطلبات إعداد جديدة.

## الملخص / ملاحظات أخيرة
- هذا المشروع مُهيأ للعمل عبر منصات متعددة ويستخدم Firebase — تأكد من إعداد ملفات القِيم Firebase الخاصة بمشروعك قبل التشغيل.
- راجع التحذيرات في التحليل الثابت واصلح التحذيرات التحذيرية قبل فتح PR.

---

إذا تحب أقدر:
- أضيف Badges (build, analyze, coverage) إلى README.
- أضيف أمثلة لملف `firestore.rules` موصى به.
- أجهّز ملف `CONTRIBUTING.md` و `CODE_OF_CONDUCT.md` وملف `CHANGELOG.md` جاهز.

قلّي أي إضافات تحبها أضيفها الآن، وسأعملها وأختبرها أيضاً.
