# قائمة تجهيز إصدار AMAN

## البيئة

- تثبيت Flutter SDK متوافق مع Dart 3.3 أو أحدث.
- تثبيت Android SDK وAndroid Build Tools.
- إنشاء `.env` محليًا أو تمرير `SUPABASE_URL` و`SUPABASE_ANON_KEY` عبر `--dart-define`.
- عدم استخدام `SUPABASE_SERVICE_ROLE_KEY` داخل التطبيق.

## التحقق

- تشغيل `flutter pub get`.
- تشغيل `flutter analyze`.
- تشغيل `flutter test`.
- تشغيل `flutter build apk --debug`.
- اختبار التسجيل والدخول والخروج.
- اختبار عزل العميل عن بيانات عميل آخر.
- اختبار عمليات المدير والحماية من دور العميل.
- اختبار قبول ورفض طلب حماية.
- اختبار إكمال المهمة ومنع التكرار.
- اختبار الإشعارات وسجل العمليات وإدارة المستخدمين.

## الإصدار

- ضبط Android application ID النهائي.
- ضبط اسم التطبيق والأيقونة.
- تحديث رقم الإصدار في `aman_app/pubspec.yaml`.
- إنشاء APK Debug للتجارب.
- توفير Keystore منفصل خارج Git قبل بناء Release موقّع.
- اختبار التثبيت على هاتف فعلي مع بيئة Staging.
- حفظ checksum ونسخة سجل التغييرات خارج المستودع عند التسليم.
