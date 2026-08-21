# تحليل بروتوكول Silkroad Gateway وAgent

## الإطار العام

يستخدم `SCommon/Security/Security.cs` إطارًا يبدأ بـ `UInt16 packet_length` ثم `UInt16 opcode` ثم بايتي Security Bytes ثم جسم الحزمة. عند تفعيل Blowfish، تُضبط أعلى بتة في `packet_length` (`0x8000`) وتُشفّر البيانات من offset 2، أي opcode وSecurity Bytes والجسم، مع حشو صفري إلى مضاعف 8. الخادم يهيّئ Gateway وAgent باستخدام `SecurityFlags.Blowfish | SecurityFlags.SecurityBytes`.

## تسلسل Gateway

1. يتصل العميل عبر TCP إلى `GatewayServerIPAddress:GatewayServerPort`.
2. يرسل الخادم `0x5000` غير مشفّرة، وبايتها الأول يعلن Blowfish وSecurity Bytes، ثم مفتاح Blowfish بطول 8 بايت، و`seed_count` و`crc_seed` بطول 4 بايت لكل منهما.
3. يرسل العميل `0x9000`، ثم يرسل `0x2001` مشفّرة بجسم `WriteAscii("SR_Client")` متبوعًا بالبايت `0`.
4. يرد الخادم بـ `0x2001` وجسم `WriteAscii("GatewayServer")` ثم البايت `0`.
5. يرسل العميل طلب الدخول `0x6102` مشفّرًا وجسمه: `locale: UInt8`، ثم `id: ASCII`، ثم كلمة المرور بصيغة ASCII، ثم `server/shard: UInt16`. ترميز ASCII في `Packet.WriteAscii` هو `UInt16 byte_length` ثم البايتات الخام.
6. قبل بناء الحزمة، يحوّل Gateway كلمة المرور إلى MD5 lowercase hex؛ لذلك يرسل العميل كلمة المرور الخام في جسم `0x6102`، ولا يرسل MD5 بنفسه.
7. رد النجاح هو `0xA102`: `UInt8(1)` ثم `session_id: Int32` ثم عنوان Agent ASCII ثم منفذ Agent `UInt16`. حالات الرفض تبدأ بـ `UInt8(2)` ثم كود الحالة.

## تسلسل Agent بعد نجاح Gateway

1. يتصل العميل بعنوان Agent والمنفذ الواردين في `0xA102`.
2. يكرر مصافحة `0x5000`/`0x9000` والهوية `0x2001`، ويتوقع `WriteAscii("AgentServer")`.
3. يرسل `0x6103` مشفّرة وجسمها `session_id: Int32`، ثم `id: ASCII`، ثم كلمة المرور الخام: ASCII.
4. يرد Agent بـ `0xA103` وجسم نجاح `UInt8(1)`؛ عندها يكون اختبار المصادقة الأساسي قد نجح، مع بقاء تدفق اختيار الشخصية خارج نطاق المرحلة الأولى.

## حدود التنفيذ

يعتمد العميل على نسخة GDScript مولّدة من نفس ثوابت وخوارزمية `SCommon/Security/Blowfish.cs`، وعلى خوارزمية Security Bytes وCRC الموجودة في `Security.cs`. حقلا العنوان والمنفذ قابلان للتعديل في الواجهة لأنهما يأتيان من إعدادات SQL `_ServerConfig` وليس من ملفات المشروع المنشورة.
