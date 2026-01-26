# دليل ترجمة وتحسين Pokemon Auto Chess للعربية والجوال

## نظرة عامة على المشروع

Pokemon Auto Chess هي لعبة مفتوحة المصدر مبنية على:
- **الخادم (Backend)**: Node.js + Colyseus (multiplayer framework) + MongoDB
- **العميل (Frontend)**: React + Phaser 3 (game engine)
- **نظام الترجمة**: i18next

---

## الجزء الأول: ترجمة اللعبة للعربية بالكامل

### 1. إضافة اللغة العربية للنظام

#### أ) تعديل ملف اللغات `app/types/enum/Language.ts`:

```typescript
export enum Language {
  en = "en",
  fr = "fr",
  pt = "pt",
  de = "de",
  es = "es",
  it = "it",
  ja = "ja",
  nl = "nl",
  bg = "bg",
  ko = "ko",
  pl = "pl",
  vi = "vi",
  th = "th",
  zh = "zh",
  ar = "ar"  // إضافة العربية
}
```

#### ب) تعديل إعدادات inlang `project.inlang/settings.json`:

```json
{
  "$schema": "https://inlang.com/schema/project-settings",
  "sourceLanguageTag": "en",
  "languageTags": [
    "en", "bg", "de", "es", "fr", "it", "ja", "ko", 
    "nl", "pl", "pt", "th", "vi", "zh", "ar"
  ],
  "modules": [
    "https://cdn.jsdelivr.net/npm/@inlang/plugin-i18next@latest/dist/index.js",
    "https://cdn.jsdelivr.net/npm/@inlang/message-lint-rule-empty-pattern@latest/dist/index.js",
    "https://cdn.jsdelivr.net/npm/@inlang/message-lint-rule-without-source@latest/dist/index.js",
    "https://cdn.jsdelivr.net/npm/@inlang/message-lint-rule-missing-translation@latest/dist/index.js"
  ],
  "plugin.inlang.i18next": {
    "pathPattern": "./app/public/dist/client/locales/{languageTag}/translation.json",
    "variableReferencePattern": ["{{", "}}"]
  }
}
```

### 2. إنشاء ملف الترجمة العربية

إنشاء مجلد وملف الترجمة:
```bash
mkdir -p app/public/dist/client/locales/ar
```

ملف الترجمة `app/public/dist/client/locales/ar/translation.json` يجب أن يحتوي على جميع النصوص المترجمة. الملف الإنجليزي يحتوي على حوالي **4595 سطر**.

### 3. هيكل ملف الترجمة

ملف الترجمة يحتوي على عدة أقسام رئيسية:

```json
{
  "rarity": {
    "COMMON": "شائع",
    "UNCOMMON": "غير شائع",
    "RARE": "نادر",
    "EPIC": "ملحمي",
    "ULTRA": "فائق",
    "UNIQUE": "فريد",
    "LEGENDARY": "أسطوري",
    "MYTHICAL": "خرافي",
    "HATCH": "فقس",
    "SPECIAL": "خاص"
  },
  "pool": {
    "regular": "عادي",
    "additional": "إضافي",
    "regional": "إقليمي",
    "special": "خاص"
  },
  "damage": {
    "SPECIAL": "ضرر خاص",
    "PHYSICAL": "ضرر جسدي",
    "TRUE": "ضرر حقيقي"
  },
  "ability": {
    "SOFT_BOILED": "بيضة مسلوقة",
    "PRECIPICE_BLADES": "شفرات الهاوية",
    // ... باقي القدرات
  },
  "item": {
    // ترجمة جميع الأغراض
  },
  "synergy": {
    // ترجمة جميع التآزرات
  },
  "status": {
    // ترجمة جميع الحالات
  },
  "weather": {
    // ترجمة أحوال الطقس
  },
  // ... وغيرها
}
```

### 4. أهم الأقسام التي تحتاج ترجمة

| القسم | الوصف | عدد النصوص تقريباً |
|-------|-------|-------------------|
| `ability` | أسماء وأوصاف القدرات | ~300+ |
| `item` | الأغراض والأوصاف | ~150+ |
| `synergy` | أنواع التآزر | ~30+ |
| `pokemon` | أسماء البوكيمون | ~1000+ |
| `status` | حالات المعركة | ~50+ |
| `ui` | واجهة المستخدم | ~200+ |
| `tooltip` | التلميحات | ~100+ |

### 5. دعم RTL (من اليمين لليسار)

أضف دعم RTL في CSS. قم بتعديل `app/public/src/style/index.css`:

```css
/* دعم اللغة العربية RTL */
html[lang="ar"] {
  direction: rtl;
}

html[lang="ar"] body {
  font-family: 'Tajawal', 'Arial', sans-serif;
}

html[lang="ar"] #game-wrapper {
  left: auto;
  right: 60px;
}

html[lang="ar"] #game-wrapper .ps-sidebar-root {
  left: auto;
  right: calc(-1 * var(--sidebar-width));
}

/* تعديل العناصر للـ RTL */
html[lang="ar"] .my-container {
  text-align: right;
}

html[lang="ar"] .pokemon-portrait.additional:not(.regional)::after {
  right: auto;
  left: 0px;
}

html[lang="ar"] .pokemon-portrait.regional::after {
  right: auto;
  left: 0px;
}
```

### 6. إضافة خط عربي

في `app/public/src/style/fonts.css`:

```css
@import url('https://fonts.googleapis.com/css2?family=Tajawal:wght@400;500;700&display=swap');

html[lang="ar"] * {
  font-family: 'Tajawal', sans-serif !important;
}
```

### 7. استخدام الترجمة الآلية

المشروع يدعم الترجمة الآلية عبر Inlang:

```bash
npm run translate
```

هذا الأمر سيترجم النصوص المفقودة آلياً، لكن يُنصح بمراجعة الترجمة يدوياً.

---

## الجزء الثاني: تحسين اللعبة للجوال

### 1. التحديات الرئيسية

- **حجم الشاشة**: اللعبة مصممة لشاشة 1950x1000 بكسل
- **التحكم**: اللعبة تعتمد على الماوس (drag & drop)
- **الأداء**: اللعبة تستخدم Phaser مع العديد من الرسوم المتحركة

### 2. تعديل game-container.ts للجوال

```typescript
// في app/public/src/game/game-container.ts

initializeGame() {
  if (this.game != null) return
  const renderer = Number(preference("renderer") ?? Phaser.AUTO)
  
  // اكتشاف الجوال
  const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
  
  const config = {
    type: renderer,
    width: isMobile ? window.innerWidth : 1950,
    height: isMobile ? window.innerHeight : 1000,
    parent: this.div,
    pixelArt: true,
    scene: GameScene,
    scale: { 
      mode: Phaser.Scale.FIT,
      autoCenter: Phaser.Scale.CENTER_BOTH
    },
    dom: {
      createContainer: true
    },
    disableContextMenu: true,
    input: {
      touch: {
        capture: true
      }
    },
    plugins: {
      global: [
        {
          key: "rexMoveTo",
          plugin: MoveToPlugin,
          start: true
        }
      ]
    }
  }
  // ...
}

resize() {
  const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
  
  if (isMobile) {
    // للجوال: استخدم الشاشة الكاملة
    const screenWidth = window.innerWidth
    const screenHeight = window.innerHeight
    
    if (this.game) {
      this.game.scale.setGameSize(screenWidth, screenHeight)
    }
  } else {
    // الكود الحالي للديسكتوب
    const screenWidth = window.innerWidth - 60
    const screenHeight = window.innerHeight
    // ...
  }
}
```

### 3. إضافة CSS للجوال

```css
/* app/public/src/style/mobile.css */

/* اكتشاف الجوال */
@media (max-width: 768px), (hover: none) and (pointer: coarse) {
  :root {
    --sidebar-width: 50px;
  }
  
  body {
    font-size: 12px;
    overflow: auto;
    -webkit-overflow-scrolling: touch;
  }
  
  #game-wrapper {
    left: 0;
    width: 100vw;
  }
  
  #game {
    width: 100vw;
    height: calc(100vh - 50px);
  }
  
  /* إخفاء الشريط الجانبي وإظهار قائمة مبسطة */
  #game-wrapper .ps-sidebar-root {
    display: none;
  }
  
  /* أزرار أكبر للمس */
  .bubbly {
    min-height: 44px;
    min-width: 44px;
    padding: 12px 16px;
  }
  
  /* تكبير عناصر البوكيمون */
  .pokemon-portrait {
    transform: scale(1.2);
  }
  
  /* تبسيط القوائم */
  .my-container {
    padding: 8px;
    border-radius: 8px;
  }
  
  /* إخفاء العناصر غير الضرورية */
  .desktop-only {
    display: none !important;
  }
}

/* دعم الوضع الأفقي */
@media (max-width: 768px) and (orientation: landscape) {
  #game {
    height: 100vh;
  }
  
  .ps-sidebar-root {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    height: 50px;
    width: 100%;
  }
}

/* دعم الوضع العمودي */
@media (max-width: 768px) and (orientation: portrait) {
  #game {
    height: calc(100vh - 60px);
  }
  
  /* رسالة تطلب التدوير */
  .rotate-device-message {
    display: flex;
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0,0,0,0.9);
    color: white;
    justify-content: center;
    align-items: center;
    z-index: 9999;
    text-align: center;
    padding: 20px;
  }
}

/* تحسين اللمس */
@media (hover: none) and (pointer: coarse) {
  * {
    -webkit-tap-highlight-color: transparent;
  }
  
  button, .clickable {
    cursor: default;
  }
  
  /* منطقة لمس أكبر */
  .touch-target {
    min-height: 48px;
    min-width: 48px;
  }
}
```

### 4. إضافة دعم اللمس للـ Drag & Drop

أنشئ ملف جديد `app/public/src/game/touch-handler.ts`:

```typescript
import Phaser from 'phaser'

export class TouchHandler {
  private scene: Phaser.Scene
  private draggedObject: Phaser.GameObjects.Sprite | null = null
  
  constructor(scene: Phaser.Scene) {
    this.scene = scene
    this.setupTouchEvents()
  }
  
  setupTouchEvents() {
    this.scene.input.on('pointerdown', this.onPointerDown, this)
    this.scene.input.on('pointermove', this.onPointerMove, this)
    this.scene.input.on('pointerup', this.onPointerUp, this)
  }
  
  onPointerDown(pointer: Phaser.Input.Pointer) {
    const gameObjects = this.scene.input.hitTestPointer(pointer)
    if (gameObjects.length > 0) {
      this.draggedObject = gameObjects[0] as Phaser.GameObjects.Sprite
      // إضافة تأثير بصري
      this.draggedObject.setScale(1.2)
    }
  }
  
  onPointerMove(pointer: Phaser.Input.Pointer) {
    if (this.draggedObject && pointer.isDown) {
      this.draggedObject.x = pointer.x
      this.draggedObject.y = pointer.y
    }
  }
  
  onPointerUp(pointer: Phaser.Input.Pointer) {
    if (this.draggedObject) {
      this.draggedObject.setScale(1)
      // إرسال حدث الإسقاط
      this.scene.events.emit('drop', this.draggedObject, pointer)
      this.draggedObject = null
    }
  }
}
```

### 5. إضافة زر ملء الشاشة للجوال

```typescript
// في app/public/src/pages/game.tsx
// أضف زر ملء الشاشة

const toggleFullscreen = () => {
  if (!document.fullscreenElement) {
    document.documentElement.requestFullscreen()
  } else {
    document.exitFullscreen()
  }
}

// في الـ JSX
{isMobile && (
  <button 
    className="fullscreen-btn"
    onClick={toggleFullscreen}
  >
    🔲
  </button>
)}
```

### 6. تحسين الأداء للجوال

```typescript
// في app/public/src/preferences.ts
// أضف إعدادات الجوال

export const mobilePreferences = {
  reducedAnimations: true,
  lowResolutionSprites: true,
  disableWeatherEffects: false,
  simplifiedUI: true,
  batteryOptimization: true
}

// تطبيق الإعدادات
export function applyMobileOptimizations() {
  const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
  
  if (isMobile) {
    // تقليل جودة الرسومات
    Phaser.WEBGL_RENDERER // استخدم WebGL
    
    // تقليل معدل الإطارات إذا لزم الأمر
    // game.loop.targetFps = 30
  }
}
```

### 7. ملف manifest للتطبيق (PWA)

أنشئ `app/public/manifest.json`:

```json
{
  "name": "Pokemon Auto Chess",
  "short_name": "PAC",
  "description": "Pokemon Auto Chess - لعبة أوتوشيس بوكيمون",
  "start_url": "/",
  "display": "fullscreen",
  "orientation": "landscape",
  "background_color": "#68829E",
  "theme_color": "#505160",
  "icons": [
    {
      "src": "assets/icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "assets/icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

### 8. تعديل index.html للجوال

```html
<!-- في app/views/index.html -->
<head>
  <!-- ... existing code ... -->
  
  <!-- Mobile meta tags -->
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="theme-color" content="#505160">
  
  <!-- PWA manifest -->
  <link rel="manifest" href="/manifest.json">
  
  <!-- iOS icons -->
  <link rel="apple-touch-icon" href="assets/icons/icon-192.png">
</head>
```

---

## الجزء الثالث: خطوات التنفيذ

### خطة العمل المقترحة

#### المرحلة 1: الترجمة (الأولوية العالية)
1. نسخ ملف `en/translation.json` إلى `ar/translation.json`
2. ترجمة الأقسام الأساسية (UI، القوائم، الرسائل)
3. ترجمة أسماء البوكيمون والقدرات
4. إضافة دعم RTL
5. اختبار الترجمة

#### المرحلة 2: تحسين الجوال
1. إضافة CSS للجوال
2. تعديل game-container.ts
3. إضافة دعم اللمس
4. اختبار على أجهزة مختلفة
5. تحسين الأداء

#### المرحلة 3: النشر
1. إنشاء PWA
2. اختبار على iOS و Android
3. تحسين التحميل والأداء

---

## ملاحظات مهمة

1. **اللعبة مصممة أساساً للديسكتوب** - تحويلها للجوال يتطلب تعديلات جوهرية
2. **الترجمة تحتاج مراجعة بشرية** - الترجمة الآلية لن تكون دقيقة
3. **أسماء البوكيمون** - يُنصح بالاحتفاظ بالأسماء الإنجليزية أو استخدام الأسماء العربية الرسمية
4. **الأداء على الجوال** - قد تحتاج لتقليل جودة الرسومات
5. **اتجاه الشاشة** - اللعبة تعمل بشكل أفضل في الوضع الأفقي

---

## الموارد والروابط

- [مستودع المشروع](https://github.com/keldaanCommunity/pokemonAutoChess)
- [دليل النشر](https://github.com/keldaanCommunity/pokemonAutoChess/blob/master/deployment/README.md)
- [وثائق i18next](https://www.i18next.com/)
- [وثائق Phaser 3](https://phaser.io/phaser3)

---

## أوامر مفيدة

```bash
# تثبيت المشروع
npm install

# تحميل الموسيقى
npm run download-music

# تجهيز الأصول
npm run assetpack

# الترجمة الآلية
npm run translate

# تشغيل المشروع محلياً
npm run dev

# بناء المشروع للإنتاج
npm run build
```
