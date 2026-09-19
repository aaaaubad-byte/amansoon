# AMAN Android App

هذا المجلد مخصص لتطبيق Flutter Android APK. لم تُحسم الهوية البصرية بعد؛ ستضاف بعد استلام الصورة المرجعية.

## نقطة البدء

- Flutter + Dart.
- Arabic RTL وMobile-First.
- Supabase Auth وPostgreSQL.
- العميل والمدير داخل تطبيق واحد مع صلاحيات مختلفة.

## الاتصال

يُمرر `SUPABASE_URL` و`SUPABASE_ANON_KEY` وقت البناء أو من ملف إعداد محلي غير مرفوع إلى Git. يمنع منعًا تامًا وضع `service_role` key داخل APK.

## أول تدفق

```text
تسجيل حساب حقيقي
→ إنشاء profile
→ تسجيل الدخول
→ تحديد الدور
→ فتح واجهة العميل أو المدير
```

يتطلب بناء APK وجود Flutter SDK وAndroid SDK في بيئة التنفيذ.
