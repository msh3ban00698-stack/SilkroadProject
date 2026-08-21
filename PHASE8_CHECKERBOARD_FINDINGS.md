# Phase 8 Checkerboard Findings

- The red checkerboard occupies the near foreground in Xvfb captures.
- Replacing `road_cross` with a solid StandardMaterial3D did not remove it.
- Replacing `_road_shader()` with a solid StandardMaterial3D did not remove it.
- Hiding `Water` did not remove it.
- Hiding the Ground floor mesh did not remove it.
- Hiding every `MeshInstance3D` produced an all-black capture, so the previous capture still depended on 3D world geometry; this test did not reveal a surviving UI checkerboard.
- The code currently contains temporary isolation flags that must be reverted before final commit: `floor.visible = false` and `water.visible = false`.
- The most useful next step is to inspect runtime node/material state and temporarily hide the remaining `road` plus any generated models/VFX separately, then restore the intended PBR/Water materials before committing.


## Additional isolation

إخفاء `player.visual` فقط مع إبقاء `Player` و`CameraRig` فعالين أبقى checkerboard، مع اختفاء الوحوش أيضاً؛ لذلك النماذج ليست المصدر. إخفاء Player بالكامل ينتج شاشة سوداء لأن الكاميرا ابن له، وليس دليلاً على أن checkerboard UI. إخفاء جميع أسطح الأرض المعلنة ينتج شاشة سوداء أيضاً، ما يتوافق مع غياب أي geometry مرئية أمام الكاميرا. التشخيص العملي الآن هو أن checkerboard مرتبط بأحد أسطح العالم المرئية في اللقطة، لكن الأعلام المؤقتة يجب إزالتها وإعادة بناء السطح النهائي بشكل صريح قبل التسليم.


## Post-processing check

تعطيل `environment.glow_enabled` لم يغير checkerboard. النتيجة تستبعد Glow/Bloom كسبب مباشر. كما أن تحويل Ground وRoad وRoadCross إلى StandardMaterial3D بسيطة بلا texture أو clearcoat لم يغيره؛ لذلك يلزم فحص عقد المشهد المتبقية أو renderer نفسه قبل اعتماد workaround نهائي.


## Final renderer isolation

تحويل Ground وRoad وRoadCross وWater إلى `PlaneMesh` لم يزل checkerboard، ما يستبعد شكل BoxMesh كسبب مباشر. إزالة CollisionShape3D من Ground لم تُظهر checkerboard بل أدت إلى شاشة سوداء مع تسرب RID، لذلك أُعيدت عقدة التصادم فوراً. تبقى اللقطة المحلية في Xvfb غير موثوقة كمؤشر وحيد، بينما smoke tests الخاصة بالعالم والاختيار تنجح دون Parse/Runtime errors.
