# Silkroad Mobile Client

هذا مشروع Godot 4 مبدئي لاختبار المصادقة مع Gateway وAgent في SilkroadProject. واجهة الدخول تبني نفسها في `main.gd`، بينما `sro_protocol.gd` ينفذ إطار الحزم والمصافحة وطلبات `0x6102` و`0x6103`. ملف `blowfish.gd` هو port لخوارزمية `SCommon/Security/Blowfish.cs`.

افتح المشروع في Godot 4.3 أو أحدث، ثم شغّل `main.tscn`. أدخل عنوان Gateway والمنفذ كما هما في `_ServerConfig`، ثم أدخل الحساب والـ locale وShard ID. القيمة الافتراضية للمنفذ هي `15779` لتسهيل التجربة، لكنها ليست قيمة مفروضة من هذا المستودع.

يجب أن يكون الهاتف قادرًا على الوصول إلى عنوان الخادم عبر TCP؛ العنوان `127.0.0.1` يعمل فقط عند تشغيل Gateway على نفس الجهاز الذي يشغل العميل. عند نجاح Gateway يعرض العميل Session وAgent endpoint، ثم يواصل المصادقة مع Agent تلقائيًا. اختيار الشخصية ودخول العالم غير مشمولين في المرحلة الأولى.

## بناء Android

يُبنى APK من GitHub Actions بواسطة `.github/workflows/android-build.yml` عند رفع أي تعديل تحت `MobileClient/` أو عند التشغيل اليدوي. بعد اكتمال المهمة، حمّل Artifact باسم `SilkroadMobile-debug-apk` من صفحة Actions.
