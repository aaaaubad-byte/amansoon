# البنية التقنية المقترحة

## القرار المعماري

يبدأ المشروع كتطبيق **Modular Monolith**. يعني ذلك أن Backend واحدًا يحتوي وحدات أعمال مستقلة بحدود واضحة، مع قاعدة بيانات واحدة ومعاملات موحدة. هذا الخيار أسرع وأقل مخاطرة من Microservices في مرحلة التأسيس، مع إبقاء الوحدات قابلة للفصل مستقبلًا.

## الرسم العام

```text
Browser / PWA
    |
    v
Next.js Frontend
    |
    | REST + JSON
    v
NestJS Backend
    |
    +-- Auth & Authorization
    +-- Customer Domain
    +-- Protection Domain
    +-- Operations Domain
    +-- Notification Domain
    +-- Audit Domain
    |
    +-- Prisma
    v
PostgreSQL (source of truth)
    |
    +-- Redis/BullMQ for background work when enabled
    +-- S3-compatible storage for logos/documents
```

## Frontend

يستخدم Next.js وReact وTypeScript. تستخدم TanStack Query للبيانات القادمة من API، وReact Hook Form مع Zod للنماذج، وTailwind CSS مع مكونات متوافقة مع RTL.

تنظيم الواجهة حسب النطاق:

```text
frontend/src/
├── app/
│   ├── (public)/
│   ├── (customer)/
│   └── (admin)/
├── components/
├── features/
│   ├── auth/
│   ├── numbers/
│   ├── protection-requests/
│   ├── protections/
│   ├── operational-tasks/
│   └── notifications/
├── lib/
└── types/
```

لا يحتوي Frontend على أسرار أو اتصال مباشر بقاعدة البيانات. إخفاء زر أو مسار في الواجهة ليس طبقة صلاحيات؛ القرار النهائي في Backend.

## Backend

يستخدم NestJS مع وحدات مستقلة:

```text
backend/src/
├── common/
├── auth/
├── users/
├── customers/
├── telecom-companies/
├── customer-numbers/
├── packages/
├── payment-methods/
├── protection-requests/
├── protections/
├── task-settings/
├── operational-tasks/
├── notifications/
├── financial-records/
├── audit-log/
├── system-settings/
└── jobs/
```

كل وحدة تحتوي على Controller وService وDTOs وPolicies واختبارات. لا تضع منطق القبول أو إكمال المهمة داخل Controller؛ يجب أن يكون في Service مجال الأعمال، داخل Transaction.

## قاعدة البيانات

PostgreSQL هي مصدر الحقيقة. يستخدم Prisma للمخطط والهجرات والاستعلامات. يجب فرض القيود المهمة في قاعدة البيانات بالإضافة إلى التحقق في Backend.

البيانات التاريخية تحفظ في حقول Snapshot، منها قيمة ومدة الباقة في الطلب والحماية، ومبلغ المهمة وإعدادات دورتها في المهمة. بهذه الطريقة لا تتأثر السجلات السابقة بتعديلات المستقبل.

## الصلاحيات والعزل

يستخدم النظام دورين ابتدائيين: `CUSTOMER` و`ADMIN`. يبنى نظام الصلاحيات على Permissions قابلة للتوسع. كل استعلام للعميل يحدد المالك من الجلسة الحالية، ولا يثق بمعرف العميل القادم من المتصفح.

## المعاملات الحساسة

### قبول طلب

تحديث الطلب، إنشاء الحماية، تحديث الرقم، إنشاء أول مهمة، تسجيل العملية، وإنشاء الإشعار يجب أن تكون عملية مترابطة. إذا لم تكن الإشعارات مضمونة داخل نفس المعاملة، يمكن استخدام Outbox لاحقًا، لكن لا يجوز عرض نجاح قبل ضمان النتيجة الأساسية.

### إكمال مهمة

التحقق من الحالة، تحديث المهمة، تسجيل المدير والوقت، تسجيل السجل المالي، إنشاء المهمة التالية، وسجل التدقيق يجب أن تمنع التكرار عبر قيد فريد أو Idempotency Key.

## API

يبدأ المشروع بـ REST موثق عبر OpenAPI. أمثلة المسارات:

```text
POST /auth/register
POST /auth/login
GET  /customer/numbers
POST /customer/numbers
POST /customer/numbers/:id/protection-requests
GET  /customer/protection-requests
GET  /admin/protection-requests
POST /admin/protection-requests/:id/approve
POST /admin/protection-requests/:id/reject
GET  /admin/operational-tasks
POST /admin/operational-tasks/:id/complete
```

المسارات النهائية قابلة للتعديل عند تنفيذ Backend، لكن يجب الحفاظ على فصل مسارات العميل عن الإدارة والتحقق من الصلاحيات في كل عملية.

## الوظائف الخلفية

يمكن إضافة Redis وBullMQ بعد تأسيس المسارات الأساسية. تستخدم للجدولة والتنبيهات وتحديث الحالات، لكن PostgreSQL تبقى مصدر الحقيقة. لا يعتمد النظام على Mutable State أو ذاكرة العملية لمعرفة الحالة التجارية.

## الأمان

- كلمات المرور باستخدام Argon2 أو bcrypt.
- جلسات آمنة أو Access Token قصير وRefresh Token محمي.
- HTTPS في البيئات المنشورة.
- Rate limiting للمصادقة والعمليات الحساسة.
- تحقق من DTOs في Backend.
- عدم تسجيل الأسرار أو كلمات المرور في Logs.
- حماية بيانات الهاتف والبيانات المالية.
- Signed URLs للملفات.
- Audit Log للعمليات الإدارية.

## الاختبارات

تبدأ الاختبارات بقواعد المجال، ثم تكامل قاعدة البيانات، ثم سيناريوهات E2E. لا تعتبر مرحلة مكتملة إلا بعد نجاح اختباراتها وتحديث سجل التسليم.

## مراجع

[1]: https://docs.nestjs.com/modules "NestJS Modules"
[2]: https://www.prisma.io/docs/orm/prisma-client/queries/transactions "Prisma Transactions"
[3]: https://owasp.org/www-project-application-security-verification-standard/ "OWASP Application Security Verification Standard"
