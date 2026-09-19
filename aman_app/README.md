# AMAN Android App

تطبيق Flutter عربي وRTL للعميل والمدير، متصل بـ Supabase عبر المفتاح العام فقط.

## المتطلبات

- Flutter SDK حديث متوافق مع Dart 3.3 أو أحدث.
- Android SDK لبناء APK.
- مشروع Supabase تطويري يحتوي على جدول `profiles` والهجرات المطبقة.

## التشغيل

لا تضع المفاتيح في Git. مررها وقت التشغيل أو البناء:

```bash
flutter pub get
flutter run \\
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \\
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

ولبناء APK تجريبي:

```bash
flutter build apk --debug \\
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \\
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

يمنع منعًا تامًا وضع `service_role` key داخل APK أو ملفات المشروع.

## التدفق المنفذ

- تسجيل عميل جديد عبر Supabase Auth مع `full_name` و`phone` في metadata.
- تسجيل الدخول بالبريد وكلمة المرور.
- قراءة ملف المستخدم من `public.profiles` بعد تسجيل الدخول.
- توجيه أولي بحسب الدور `customer` أو `admin`.
- تسجيل الخروج.

## طبقة الشركات والأرقام

أضيف `CatalogRepository` للتعامل مع قاعدة البيانات الفعلية عبر RLS:

- قراءة شركات الاتصالات الفعالة والمرئية فقط.
- قراءة الباقات الفعالة والمرئية التابعة للشركة المحددة فقط.
- قراءة أرقام المستخدم الحالي فقط.
- إضافة رقم جديد باسم المستخدم الحالي؛ وتترك قاعدة البيانات منع التكرار والتحقق من الملكية.

لا تستخدم هذه الطبقة مفتاح `service_role` ولا تعتمد على معرف العميل القادم من الواجهة لتحديد المالك.

واجهة `أرقامي` تستخدم هذه الطبقة مباشرة، وتعرض حالة الرقم إن كان محميًا أو غير محمي. لا تعرض الواجهة نجاح الإضافة إلا بعد نجاح الإدخال في PostgreSQL.

إذا لم تُمرر متغيرات البيئة، يعرض التطبيق شاشة إعداد بدل إظهار نجاح وهمي أو محاولة اتصال غير مهيأة.
