# همراه همیشگی دانش‌آموز (Flutter)

اپ اندروید برای دانش‌آموزان + پنل مشاور؛ بک‌اند: Worker جوجو (`/api/...`).

## بیلد APK
1. پروژه را در یک ریپوی GitHub بگذار و push کن.
2. Actions ← Build APK ← Run workflow. خروجی: artifact با نام `study-companion-apk`.
3. بیلد از روی یک `flutter create` تازه (اندروید) + همین `lib/` و `pubspec.yaml` ساخته می‌شود و `tool/patch_android.py` مجوزها و سرویس پخش را اضافه می‌کند.

## آدرس سرور
در `lib/core/config.dart` مقدار `defaultBaseUrl` را بگذار، یا در صفحه‌ی ورود «تنظیم آدرس سرور».

## فرض‌هایی که باید با Worker واقعی چک شوند
- `POST /report`: فیلدهای `slept` و `distractions` به‌صورت `1/0` فرستاده می‌شوند (`slept=1` یعنی کافی خوابیده).
- `GET /admin/students` هم آرایه و هم `{students:[...]}` را می‌پذیرد؛ پاسخ ساخت دانش‌آموز: `password` در ریشه یا داخل `student`.
- `last_seen` و `live_since` هم epoch (ثانیه/میلی‌ثانیه) و هم ISO را می‌پذیرند.
- `started_at` / `ended_at` در `/focus/session` به‌صورت ISO-8601 UTC.

## ساخته نشده
- push واقعی (FCM)؛ یادآوری‌ها اعلان محلی‌اند (۷:۰۰ صبح و ۲۱:۳۰ شب).
- ویرایش عنوان رسانه از پنل ادمین (فقط آپلود/حذف).
