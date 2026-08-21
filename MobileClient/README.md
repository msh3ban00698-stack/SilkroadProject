# Silkroad Mobile Client

هذا مشروع Godot 4 مبدئي لاختبار المصادقة مع Gateway وAgent في SilkroadProject. واجهة الدخول تبني نفسها في `main.gd`، بينما `sro_protocol.gd` ينفذ إطار الحزم والمصافحة وطلبات `0x6102` و`0x6103`. ملف `blowfish.gd` هو port لخوارزمية `SCommon/Security/Blowfish.cs`.

افتح المشروع في Godot 4.3 أو أحدث، ثم شغّل `main.tscn`. أدخل عنوان Gateway والمنفذ كما هما في `_ServerConfig`، ثم أدخل الحساب والـ locale وShard ID. القيمة الافتراضية للمنفذ هي `15779` لتسهيل التجربة، لكنها ليست قيمة مفروضة من هذا المستودع.

يجب أن يكون الهاتف قادرًا على الوصول إلى عنوان الخادم عبر TCP؛ العنوان `127.0.0.1` يعمل فقط عند تشغيل Gateway على نفس الجهاز الذي يشغل العميل. عند نجاح Gateway يعرض العميل Session وAgent endpoint، ثم يواصل المصادقة مع Agent تلقائيًا. اختيار الشخصية ودخول العالم غير مشمولين في المرحلة الأولى.

## بناء Android

يُبنى APK من GitHub Actions بواسطة `.github/workflows/android-build.yml` عند رفع أي تعديل تحت `MobileClient/` أو عند التشغيل اليدوي. بعد اكتمال المهمة، حمّل Artifact باسم `SilkroadMobile-debug-apk` من صفحة Actions.

## Phase 2: Character and starter world

بعد المصادقة مع Agent، يطلب العميل قائمة الشخصيات عبر `0x7007`، ويعرض شاشة اختيار وإنشاء ثلاثية الأبعاد. يمكن اختيار العرق والسلاح والملابس والمقياس، بينما تتحقق قاعدة بيانات Agent من معرفات `RefObjID` و`RefItemID`. معرفات العرض الافتراضية موجودة في أعلى `character_select.gd` ويجب مواءمتها مع بيانات shard إذا اختلفت قاعدة البيانات.

عند اختيار شخصية، يرسل العميل `0x7001` ثم يستقبل تحميل الشخصية والإحصاءات، وبعد الضغط على الدخول يرسل `0x3012`. عالم البداية الإجرائي موجود في `starter_world.gd` ويحتوي على بوابة، مبانٍ آسيوية، سوق، أشجار، فوانيس، قناة وجسر. اللاعب `MobilePlayer` يستخدم `VirtualJoystick` للتحكم اللمسي وكاميرا `SpringArm3D` للتتبع، بينما `MobileHUD` يعرض HP/MP وMinimap وأزرار الهجوم والجرعة والمهارة.

اختبار التشغيل headless ينشئ العالم واللاعب والـHUD بنجاح. لا يحتوي المشروع على أصول Silkroad الأصلية؛ يعتمد المسار الافتراضي على أصول Kenney CC0 المحلية، مع fallback إجرائي مملوك للمشروع عند تعذر استيراد GLB.

## Phase 3: Combat, monsters, and loot

يظهر في عالم البداية وحشان Mangyang procedural عند عدم وصول Spawn من Agent، بينما الكيانات الشبكية التي تصل عبر `0x3015` أو `0x3019` تُدار في نفس المسار. انقر على الوحش لتحديده؛ ستظهر حلقة ذهبية وشريط HP في أعلى الشاشة. زر `ATTACK` يرسل `0x7074` مع معرف الهدف، وتعرض النتيجة أرقام ضرر طائرة ووميض ضربة. زر `PICKUP` يلتقط أقرب غنيمة ضمن خمسة أمتار، والنقر على الغنيمة نفسها يرسل طلب الالتقاط أيضًا. زر `BAG` يفتح واجهة الحقيبة التي تعرض العناصر بعد رد نجاح `0xB099`.

الفرع الحالي يضيف معالجًا اختياريًا في `SR_GameServer/PacketProcessor.cs` للهجوم الأساسي والتقاط العناصر، مع تعريفات Opcode في `SCommon/Opcode.cs`. الهجوم يستخدم `TotalMinPhyAtk` للشخصية ويخفض HP الوحش ثم يرسل `0xB074`; الالتقاط يستخدم `_ADD_ITEM` أو تحديث الذهب ثم يرسل `0xB099`. يجب تشغيل نسخة Agent المبنية من هذا الفرع لاختبار المسارين الشبكيين؛ أما Mangyang المحلي فيختبر الواجهة والمؤثرات دون خادم.

## Phase 4: Visual luxury and server build

يستخدم `starter_world.gd` الآن `WorldEnvironment` بإعدادات HDR Filmic وBloom/Glow، مع DirectionalLight3D بظلال متعددة التقسيمات وsoft shadow blur، وإضاءة ذهبية محيطية حول منطقة اللعب. يضيف `combat_vfx.gd` مسار Slash Trail ذهبيًا عند زر الهجوم وتأثير موت سحريًا بحلقات متلاشية، بينما يعرض `floating_damage.gd` أرقامًا أكبر بخط واضح وoutline داكن وحركة صعودية مع Fade out.

أصبح `MobileHUD` بطابع Dark & Gold مع حدود ذهبية وحالات hover/pressed للأزرار وأشرطة HP/MP وهدف الوحش. يبني `.github/workflows/android-build.yml` APK كالعادة، بينما يبني `.github/workflows/windows-server-build.yml` مشروعي `GatewayServer` و`SR_GameServer` عبر MSBuild على `windows-latest` ويرفع مجلد binaries باسم `SilkroadServer-Compiled`. الـArtifact مخصص للتشغيل على Windows/VPS Windows؛ لا يحتوي إعدادات قاعدة البيانات أو ملفات العالم السرية، ويجب ضبطها قبل التشغيل.

## Phase 4: Full Offline Test Mode

تحتوي شاشة الدخول الآن على زر `PLAY OFFLINE (CHARACTER SELECT)`. هذا المسار لا ينشئ اتصال TCP ولا يحتاج Gateway أو Agent، لكنه لا يتجاوز اختيار الشخصية: يبدأ التطبيق من شاشة Character Selection، ويجب اختيار اسم وبناء قبل دخول العالم. البناءان المحليان هما `European Wizard` بعصا سحرية وهجمات بعيدة، و`Chinese Spear` برمح وهجمات جسدية قريبة.

بعد دخول العالم يعمل زر `ATTACK` بحساب ضرر محلي حسب البناء: الـWizard يطلق Arcane Bolt متوهجاً ويستخدم ضرراً سحرياً بعيداً، بينما الـSpear يشغّل حركة swing/stab وSlash VFX ولا يسبب الضرر إلا من مسافة قريبة. كلا البناءين يستخدمان Floating Damage وتأثير موت الوحش والغنائم وEXP وGold وإعادة الظهور. نماذج اللاعب والـpreview تعتمد HumanoidModel مع Skeleton3D وBoneAttachment3D ووضعيات idle/walk/attack، بينما يستخدم Mangyang visual نموذج Orc GLB مستورداً افتراضياً مع fallback غير مرئي للعرض فقط.

على الهاتف أو داخل المحرر اضغط زر Offline من شاشة الدخول، ثم أكمل Character Selection يدوياً. لا يوجد bypass تلقائي أو تشغيل مباشر للعالم من سطر الأوامر؛ اختبارات Godot الداخلية تستخدم سكربتات smoke مؤقتة خارج المنتج ولا تغير تدفق اللاعب النهائي. وضع Offline مخصص للتحقق المحلي ولا يمثل توازناً نهائياً أو اقتصاداً معتمداً من الخادم.

يظهر في HUD شريط `LV / EXP` وشارة `OFFLINE TEST` مع مظهر Dark & Gold، بينما تبقى واجهة اللعب الشبكي متاحة عبر زر الاتصال المعتاد.

## Build artifacts

يستخرج مسار Android ملف `SilkroadMobile-debug-apk`، ويستخرج مسار Windows مجلد `SilkroadServer-Compiled` الذي يحتوي على ملفات GatewayServer وSR_GameServer وDLLs المطلوبة. يستهدف Workflow الخادم .NET Framework 4.8 في بيئة CI الحديثة، مع بقاء ملفات المشاريع الأصلية مستهدفة للإصدار القديم عند الحاجة إلى توافق الخادم.

> لا يتضمن المشروع أصول Silkroad الأصلية. النماذج المرئية الافتراضية في Phase 7 هي أصول Kenney CC0 المحلية، وتبقى الأجزاء الإجرائية fallback متوافقاً مع Godot 4.3+.

أثناء البناء، يجب مراجعة سجل Actions؛ إذا فشل تجميع الخادم بسبب اعتماديات قديمة في المصدر، يظل مسار Android مستقلاً ويمكن تنزيل APK منه، بينما يحتاج Workflow الخادم إلى إصلاح المصدر أو توفير Targeting Pack مناسب قبل تشغيله على VPS.

## References

[1]: https://docs.godotengine.org/en/4.3/ "Godot Engine documentation"
[2]: https://docs.github.com/en/actions "GitHub Actions documentation"

## Phase 6: Active Skill Tree

يحتوي العالم الآن على زر `SKILL` في الـMobile HUD يفتح قائمة Skill Tree الخاصة بالبناء المختار. يعرض النظام نقاط المهارة وMana والرتبة ومتطلبات المستوى وCooldown، وتتم الترقية عبر زر `UPGRADE` والاستخدام عبر زر `USE`.

يمتلك `European Wizard` مهارات `Arcane Bolt` و`Frost Nova` و`Meteor Lance`، بينما يمتلك `Chinese Spear` مهارات `Piercing Thrust` و`Whirlwind Sweep` و`Dragon Impale`. كل مهارة لها ضرر ومعامل Mana وCooldown ولون VFX مختلف، وتستفيد من نقاط المهارة المكتسبة عند Level Up.

يستخدم الـWizard Arcane Bolt ومقذوفات وحلقات جليدية أو نيزكاً ساقطاً، بينما يستخدم الـSpear موجات طعن وحلقات دوران وتأثير Dragon Impale أمامي. يمنع النظام استخدام المهارة عند نقص Mana أو عدم تحقق المستوى أو أثناء Cooldown، ويحدّث شريط MP والقائمة بعد كل استخدام.


## Phase 7: Landscape visual overhaul and open-source assets

The Android client now uses a mandatory 1920×1080 Landscape viewport with `viewport` stretch mode and `expand` aspect. The runtime UI is anchored to full rect, top-left, top-right, bottom-left, bottom-right, or centered presets so login, character selection, HUD, minimap, joystick, skill panel, and inventory remain usable across expanded Android aspect ratios without portrait-only black bars.

The project includes a small local subset of **Kenney CC0** GLB assets under `assets/kenney/`: `character-human.glb` for Wizard and Spear characters, `character-orc.glb` for Mangyang visuals, `weapon-spear.glb` for Spear and Wizard staff styling, and `floor-detail.glb`, `rocks.glb`, and `wood-structure.glb` for world dressing. Each asset group includes its `License.txt`. The official sources are [Kenney Animated Characters Protagonists](https://kenney.nl/assets/animated-characters-protagonists) and [Kenney Mini Dungeon](https://kenney.nl/assets/mini-dungeon).

`asset_loader.gd` is the single integration point for these GLB scenes. `HumanoidModel` and `AnimalMobModel` prefer imported assets and retain procedural fallback code only for environments where an asset import is unavailable. The Wizard uses a downloaded weapon model with an Arcane Orb VFX, while the Spear uses the downloaded spear model. StarterWorld uses the imported props alongside the textured/procedural ground and procedural skybox.

The original procedural or rigged fallback remains in source to preserve compatibility with Godot 4.3+, but the default mobile path uses the imported GLB assets. A local Xvfb capture validated a 1920×1080 Landscape CharacterSelect and StarterWorld transition without the earlier portrait-only black bars.
