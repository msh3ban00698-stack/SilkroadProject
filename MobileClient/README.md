# Silkroad Mobile Client

هذا مشروع Godot 4 مبدئي لاختبار المصادقة مع Gateway وAgent في SilkroadProject. واجهة الدخول تبني نفسها في `main.gd`، بينما `sro_protocol.gd` ينفذ إطار الحزم والمصافحة وطلبات `0x6102` و`0x6103`. ملف `blowfish.gd` هو port لخوارزمية `SCommon/Security/Blowfish.cs`.

افتح المشروع في Godot 4.3 أو أحدث، ثم شغّل `main.tscn`. أدخل عنوان Gateway والمنفذ كما هما في `_ServerConfig`، ثم أدخل الحساب والـ locale وShard ID. القيمة الافتراضية للمنفذ هي `15779` لتسهيل التجربة، لكنها ليست قيمة مفروضة من هذا المستودع.

يجب أن يكون الهاتف قادرًا على الوصول إلى عنوان الخادم عبر TCP؛ العنوان `127.0.0.1` يعمل فقط عند تشغيل Gateway على نفس الجهاز الذي يشغل العميل. عند نجاح Gateway يعرض العميل Session وAgent endpoint، ثم يواصل المصادقة مع Agent تلقائيًا. اختيار الشخصية ودخول العالم غير مشمولين في المرحلة الأولى.

## بناء Android

يُبنى APK من GitHub Actions بواسطة `.github/workflows/android-build.yml` عند رفع أي تعديل تحت `MobileClient/` أو عند التشغيل اليدوي. بعد اكتمال المهمة، حمّل Artifact باسم `SilkroadMobile-debug-apk` من صفحة Actions.

## Phase 2: Character and starter world

بعد المصادقة مع Agent، يطلب العميل قائمة الشخصيات عبر `0x7007`، ويعرض شاشة اختيار وإنشاء ثلاثية الأبعاد. يمكن اختيار العرق والسلاح والملابس والمقياس، بينما تتحقق قاعدة بيانات Agent من معرفات `RefObjID` و`RefItemID`. معرفات العرض الافتراضية موجودة في أعلى `character_select.gd` ويجب مواءمتها مع بيانات shard إذا اختلفت قاعدة البيانات.

عند اختيار شخصية، يرسل العميل `0x7001` ثم يستقبل تحميل الشخصية والإحصاءات، وبعد الضغط على الدخول يرسل `0x3012`. عالم البداية الإجرائي موجود في `starter_world.gd` ويحتوي على بوابة، مبانٍ آسيوية، سوق، أشجار، فوانيس، قناة وجسر. اللاعب `MobilePlayer` يستخدم `VirtualJoystick` للتحكم اللمسي وكاميرا `SpringArm3D` للتتبع، بينما `MobileHUD` يعرض HP/MP وMinimap وأزرار الهجوم والجرعة والمهارة.

اختبار التشغيل headless ينشئ العالم واللاعب والـHUD بنجاح. لا تحتوي المرحلة على أصول Silkroad الأصلية أو اختيار الشخصية داخل العالم النهائي؛ الأصول الحالية procedural ومملوكة للمشروع لتفادي إعادة توزيع ملفات اللعبة الأصلية.

## Phase 3: Combat, monsters, and loot

يظهر في عالم البداية وحشان Mangyang procedural عند عدم وصول Spawn من Agent، بينما الكيانات الشبكية التي تصل عبر `0x3015` أو `0x3019` تُدار في نفس المسار. انقر على الوحش لتحديده؛ ستظهر حلقة ذهبية وشريط HP في أعلى الشاشة. زر `ATTACK` يرسل `0x7074` مع معرف الهدف، وتعرض النتيجة أرقام ضرر طائرة ووميض ضربة. زر `PICKUP` يلتقط أقرب غنيمة ضمن خمسة أمتار، والنقر على الغنيمة نفسها يرسل طلب الالتقاط أيضًا. زر `BAG` يفتح واجهة الحقيبة التي تعرض العناصر بعد رد نجاح `0xB099`.

الفرع الحالي يضيف معالجًا اختياريًا في `SR_GameServer/PacketProcessor.cs` للهجوم الأساسي والتقاط العناصر، مع تعريفات Opcode في `SCommon/Opcode.cs`. الهجوم يستخدم `TotalMinPhyAtk` للشخصية ويخفض HP الوحش ثم يرسل `0xB074`; الالتقاط يستخدم `_ADD_ITEM` أو تحديث الذهب ثم يرسل `0xB099`. يجب تشغيل نسخة Agent المبنية من هذا الفرع لاختبار المسارين الشبكيين؛ أما Mangyang المحلي فيختبر الواجهة والمؤثرات دون خادم.

## Phase 4: Visual luxury and server build

يستخدم `starter_world.gd` الآن `WorldEnvironment` بإعدادات HDR Filmic وBloom/Glow، مع DirectionalLight3D بظلال متعددة التقسيمات وsoft shadow blur، وإضاءة ذهبية محيطية حول منطقة اللعب. يضيف `combat_vfx.gd` مسار Slash Trail ذهبيًا عند زر الهجوم وتأثير موت سحريًا بحلقات متلاشية، بينما يعرض `floating_damage.gd` أرقامًا أكبر بخط واضح وoutline داكن وحركة صعودية مع Fade out.

أصبح `MobileHUD` بطابع Dark & Gold مع حدود ذهبية وحالات hover/pressed للأزرار وأشرطة HP/MP وهدف الوحش. يبني `.github/workflows/android-build.yml` APK كالعادة، بينما يبني `.github/workflows/windows-server-build.yml` مشروعي `GatewayServer` و`SR_GameServer` عبر MSBuild على `windows-latest` ويرفع مجلد binaries باسم `SilkroadServer-Compiled`. الـArtifact مخصص للتشغيل على Windows/VPS Windows؛ لا يحتوي إعدادات قاعدة البيانات أو ملفات العالم السرية، ويجب ضبطها قبل التشغيل.
