# Fábrica de apps → carril iOS (App Store): documento de traspaso

> **Para quién es esto.** Para una IA (u otra persona) que va a construir el carril iOS de una
> fábrica de apps que ya funciona de punta a punta en Huawei AppGallery. No asumas nada de la
> conversación anterior: todo lo necesario está aquí y en el repositorio.
>
> **Repositorio de referencia:** <https://github.com/oflorezawaken-dev/huawei-app-factory> (público).
> **Propietario:** el usuario que te da este documento. Trabaja desde Windows 11 con Claude Code
> bajo suscripción Pro; no quiere pagar tokens de API. Habla español; los identificadores técnicos van en inglés.
>
> **Regla número uno:** ningún secreto (certificados, claves `.p8`, contraseñas, tokens) se pide en el chat,
> se pega en archivos ni se imprime en logs. Solo se nombran por su nombre de secreto.

---

## 0. Cómo usar este documento

1. Lee las secciones 1 a 3 para entender qué es la fábrica y qué se demostró.
2. Lee la sección 4 antes de escribir código: son los recursos y decisiones que dependen del humano.
3. La sección 6 es el flujo paso a paso que debes reproducir para iOS. La 7 es tu compuerta de calidad.
4. La sección 10 es el plan de arranque ordenado: empieza por ahí cuando tengas el repositorio delante.
5. Las secciones 8 y 9 son lecciones aprendidas y riesgos. Léelas antes de tomar atajos: casi todo lo que ahí aparece nos costó una iteración real.
6. Cuando encuentres una afirmación sobre Apple (límites, tamaños, precios), **verifícala contra la documentación vigente** antes de apoyarte en ella. Este documento se escribió el 2026-09-07; Apple cambia esos valores con frecuencia.

---

## 1. Resumen ejecutivo

**Qué es la fábrica.** Un pipeline que convierte una idea aprobada en una app publicada, con una persona decidiendo en cuatro puntos y todo lo demás automatizado. Está dividida en dos capas que no se mezclan:

| Capa | Qué hace | Dónde corre | ¿Gasta tokens? |
|---|---|---|---|
| **Director de orquesta** (determinista) | Compilar, testear, firmar, compuerta de calidad, subir binarios y metadatos a la tienda, enviar a revisión | GitHub Actions + scripts Python de librería estándar | No |
| **Cerebro** (inteligente) | Investigar ideas, escribir la especificación, generar el código, arreglar builds, redactar ficha y política de privacidad, capturar pantallas | Claude Code en la máquina del usuario (suscripción Pro), guiado por prompts versionados en el repo | Sí, con la suscripción |

El estado vive en GitHub: una propuesta es un issue, la aprobación es una etiqueta, una app generada es un pull request, los identificadores de tienda están en un registro JSON. No hay servidor ni base de datos.

**Qué se demostró en AppGallery (2026-09-06 → 07).**

| App | Qué es | Resultado |
|---|---|---|
| ReceiptLens | Organizador de recibos, offline | Generada antes de la fábrica; sirvió para construir el pipeline. 1.0.0 en revisión en Huawei. 1.1.0 con anuncios reales construida y en espera. |
| PlantCue | Recordatorios de cuidado de plantas, offline | **Primera app producida por la fábrica de punta a punta:** idea → issue → aprobación humana → spec → código generado → PR → merge → build firmado → ficha en 9 idiomas, icono, 5 capturas reales, política de privacidad → subida → enviada a revisión. Intervención humana: 4 clics y ~15 minutos de consola. |

La fábrica también **detectó y corrigió dos bugs reales** probando las apps en emulador (un OCR que era un stub falso en ReceiptLens; un campo numérico que no se podía borrar en PlantCue) y **aprendió límites de la tienda** que ahora están codificados como validaciones.

**Qué cambia para iOS.** El director de orquesta se conserva casi entero: registro, compuertas humanas, prompts, compuerta de calidad, política de privacidad en GitHub Pages, flujo de PR. Cambia la capa de app y la integración con la tienda: Swift/SwiftUI en lugar de Kotlin/Compose, Xcode en lugar de Gradle, firma de Apple en lugar del keystore, App Store Connect y su API en lugar de AppGallery Connect, AdMob (u otra red) en lugar de Petal Ads, runners macOS en CI. La sección 5 tiene la tabla completa.

**Objetivo del usuario para iOS:** unas **dos apps al mes, de calidad**. Explícitamente **no** una app cada pocos días. Esto es una restricción de diseño, no una preferencia: la sección 9 explica por qué la cadencia alta destruye cuentas de desarrollador.

---

## 2. Principios invariantes (no negociar sin el humano)

1. **Cuatro compuertas humanas, y solo esas:** aprobar la idea, revisar/mergear el PR, configurar en la consola de la tienda lo que la tienda no permite por API, y enviar a revisión. Todo lo demás debe poder correr sin la persona.
2. **Monetización obligatoria y real.** En AppGallery la regla era "toda app lleva el SDK real de Petal Ads y muestra anuncios". En iOS la regla equivalente debe fijarla el humano (ver 4.6); la propuesta por defecto es **AdMob real + compra única opcional para quitar anuncios**. Nunca un SDK simulado por reflexión ni una integración "preparada pero apagada".
3. **Núcleo offline-first.** La función principal funciona sin red. Sin cuentas de usuario, sin backend propio, sin Firebase Analytics ni servicios que recojan datos sin declararlos. Solo la publicidad puede usar red.
4. **Verdad en los textos.** Ficha de tienda, política de privacidad y textos de la app describen lo que hace la build que se sube, no lo que hará algún día. Si el OCR no funciona, no se promete OCR.
5. **Cero secretos en el repositorio.** Certificados, perfiles, claves de API, IDs de anuncio de producción y contraseñas van en GitHub Secrets o variables, nunca en código ni en logs.
6. **Compuerta de calidad ejecutable.** Un script decide si una app puede construirse, subirse o enviarse. Los huecos conocidos se documentan en el registro y se reportan como EXCUSED, nunca se ocultan. Las apps nuevas deben pasar en modo estricto.
7. **Verificar, no asumir.** Compilar, correr tests, instalar en simulador y navegar la app antes de abrir un PR. El código generado miente con naturalidad: el OCR falso de ReceiptLens pasó 22 pasos sin que nadie lo notara hasta que la fábrica lo probó.
8. **Commits pequeños y explicados. Nunca force-push. Nunca borrar tests para poner el CI en verde.**

---

## 3. Lo que existe hoy en el repositorio (y qué reutilizar)

```text
huawei-app-factory/
├── factory/
│   ├── apps.json              Registro de apps + reglas por defecto (leer primero)
│   ├── factory.py             CLI local: list/check/build/store/publish + research/spec/generate/fix/listing/privacy
│   ├── prompts/               Instrucciones por paso para Claude Code headless
│   │   ├── 00-factory-rules.md   Reglas invariantes (adaptar a iOS, no reescribir)
│   │   ├── 10-research.md        Investigar y proponer una idea → issue con etiqueta `proposal`
│   │   ├── 20-spec.md            Escribir la spec desde la plantilla, registrar la app
│   │   ├── 30-generate.md        Generar la app desde el esqueleto, verificar, abrir PR
│   │   ├── 40-fix-build.md       Arreglar un build fallido con el cambio mínimo
│   │   ├── 50-listing.md         Ficha de tienda en todos los idiomas
│   │   └── 60-privacy.md         Página de política de privacidad honesta
│   └── tools/
│       ├── registry.py        Lector único del registro (list/get/env/changed/agc-lang)
│       ├── check_app.py       Compuerta de calidad (PASS / EXCUSED / FAIL, --strict)
│       ├── agc_publish.py     Subir APK/AAB a AppGallery Connect y enviar a revisión
│       ├── agc_update_listing.py   Ficha por idioma (app-language-info)
│       ├── agc_upload_assets.py    Icono y capturas (fileType 0 y 2)
│       └── agc_update_app_info.py  Campos de app-info (URL de privacidad, etc.)
├── .github/workflows/
│   ├── factory-build.yml      Detecta qué app cambió; verify (gate+tests+debug) y release (firmado) por app
│   ├── factory-store.yml      Ficha, icono, capturas, app-info para cualquier app del registro
│   └── factory-publish.yml    Descarga artifact firmado, verifica firma, sube, opcionalmente envía a revisión
├── apps/<slug>/               Proyecto Android + store/ (icon/icon-512.png, screenshots/<lang>/*.png, listing.json)
├── specifications/            APP_SPEC_TEMPLATE.json y una spec por app
├── proposals/                 Propuestas de investigación (una por app)
├── docs/
│   ├── APPGALLERY_PUBLISHING.md   API de Huawei, errores vistos y sus arreglos
│   ├── RELEASE_STATUS.md          Bitácora completa de todo lo hecho, con IDs de runs
│   ├── privacy/, plant-cue/privacy/   Políticas publicadas con GitHub Pages
│   └── IOS_FACTORY_HANDOFF.md     Este documento
└── README.md
```

**Reutilizar tal cual (son agnósticos de plataforma):** el concepto de registro y `registry.py`, la lógica de `check_app.py` (con reglas nuevas), los prompts 10, 20, 40, 50 y 60 con adaptaciones menores, la plantilla de spec, el flujo issue → etiqueta → PR → merge, GitHub Pages para privacidad, el CLI `factory.py`.

**Reemplazar:** todo lo que dice AGC/Huawei/Petal/Gradle/Android. El prompt 30 (generación) se reescribe para SwiftUI. Los tres workflows se clonan como `factory-ios-*.yml`.

**Decisión de estructura recomendada:** mantener un solo repositorio con un campo `platform` en cada entrada del registro (`android` | `ios`), carpetas `apps/<slug>/` (Android) y `apps-ios/<slug>/` (iOS), y workflows separados por plataforma. Así el conocimiento acumulado en `docs/` sigue siendo uno.

---

## 4. Recursos que el carril iOS necesita (qué debe conseguir el humano)

### 4.1 Cuenta y consolas de Apple

| Recurso | Detalle | Coste / plazo |
|---|---|---|
| **Apple Developer Program** | Cuenta individual (nombre propio como vendedor) u organización (requiere número D-U-N-S y verificación; permite nombre de empresa). Para empezar, individual. | 99 USD/año; activación de 24 a 48 h, a veces verificación de identidad adicional |
| **App Store Connect** | Consola donde se crean las apps, metadatos, precios, privacidad, revisión. Equivalente a AppGallery Connect. | Incluida |
| **Certificates, Identifiers & Profiles** (developer.apple.com) | Registrar cada **Bundle ID** (equivalente al package name; ej. `com.huaweiappfactory.plantcue` → mejor un dominio propio del usuario, ej. `com.<dominio>.plantcue`), certificados de distribución, perfiles de aprovisionamiento. | Incluido |
| **Clave de App Store Connect API** | Users and Access → Integrations → App Store Connect API → generar clave con rol **App Manager** (o Admin). Entrega: **Issuer ID**, **Key ID** y un archivo **`.p8` que solo se descarga una vez**. Es lo que permite automatizar subida de builds, metadatos, capturas y envío a revisión. | Incluido. Guardar como secretos: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY_P8` (contenido base64) |
| **Acuerdos** | Aceptar el Paid Applications Agreement solo si habrá compras dentro de la app; los anuncios no lo requieren, pero la compra "quitar anuncios" sí. Datos bancarios y fiscales en App Store Connect. | Manual, una vez |

### 4.2 Máquina para compilar: la diferencia más grande con Android

Xcode solo corre en macOS. Hay dos caminos, no excluyentes:

- **GitHub Actions con runners macOS.** En un repositorio **público** los runners estándar de GitHub, incluidos los macOS, se usan sin coste (verificar la política vigente; en repos privados los minutos macOS cuestan 10 veces los de Linux). El repositorio de la fábrica ya es público precisamente por GitHub Pages. Este es el camino por defecto: el cerebro escribe Swift en Windows, el CI compila, testea, captura pantallas en simulador y sube.
- **Un Mac propio** (un Mac mini basta). Acelera muchísimo la iteración: compilar localmente tarda segundos frente a los 10–20 minutos de un runner en frío. No es imprescindible para arrancar, pero sin Mac cada error de compilación cuesta un ciclo de CI. Recomendación honesta: empezar solo con CI, y comprar un Mac usado si la latencia frena el ritmo de dos apps al mes.

Versión de Xcode: usar la última estable disponible en `macos-latest` (ver la imagen del runner) y **fijarla** en el workflow con `xcode-select` o `DEVELOPER_DIR` para builds reproducibles.

### 4.3 Firma de código (equivalente del keystore)

Apple firma con un **certificado de distribución** más un **perfil de aprovisionamiento** por Bundle ID. Opciones para CI:

1. **Firma gestionada en la nube con la clave de API** (recomendada): `xcodebuild -allowProvisioningUpdates -authenticationKeyPath key.p8 -authenticationKeyID ... -authenticationKeyIssuerID ...`. Xcode crea o descarga certificados y perfiles usando la clave de API. Menos piezas manuales.
2. **fastlane match**: guarda certificados y perfiles cifrados en un repositorio git privado. Robusto y muy usado, pero añade un repo y una contraseña de cifrado como secreto.
3. Exportar certificado `.p12` y perfil `.mobileprovision` a mano y meterlos como secretos base64. Funciona, pero caduca y se rompe silenciosamente.

Decisión sugerida: opción 1. Si falla por límites de certificados de la cuenta, pasar a match.

### 4.4 Monetización en iOS (Petal Ads no existe en iOS)

| Opción | Pros | Contras |
|---|---|---|
| **Google AdMob** (Google Mobile Ads SDK) | Red dominante, banners e interstitials iguales a los que ya usa la fábrica, cuenta gratuita | Requiere cuenta AdMob aprobada, IDs de unidad por app, **App Tracking Transparency** (pedir permiso de rastreo con `ATTrackingManager`), `SKAdNetworkItems` en Info.plist, **manifiesto de privacidad** (`PrivacyInfo.xcprivacy`) y declarar recogida de datos en App Store Connect. Los usuarios que niegan el rastreo bajan el ingreso por anuncio. Pagos a partir de 100 USD acumulados. |
| **Compra única "quitar anuncios"** (StoreKit 2) | Ingreso recurrente-ish, muy bien visto por Apple, no necesita red externa | Requiere el acuerdo de pagos y crear el producto en App Store Connect por app (paso humano) |
| **Solo IAP / suscripción, sin anuncios** | Cero SDKs externos, revisión más fácil | Las utilidades pequeñas convierten poco |

**Regla propuesta para el registro iOS:** `ads_required: true` con AdMob, más `remove_ads_iap: true`. El humano debe confirmar. La compuerta comprobará que el SDK esté realmente en el proyecto (dependencia SPM `GoogleMobileAds`), que existan ATT y SKAdNetwork en Info.plist, y que el manifiesto de privacidad exista.

### 4.5 Requisitos de la ficha en App Store Connect (verificar límites vigentes)

| Campo | Límite / requisito |
|---|---|
| Nombre | 30 caracteres, único en la tienda |
| Subtítulo | 30 caracteres |
| Texto promocional | 170 caracteres (editable sin nueva versión) |
| Descripción | 4000 caracteres |
| Palabras clave | 100 caracteres en total, separadas por comas |
| Novedades ("What's New") | 4000 caracteres, obligatorio a partir de la segunda versión |
| URL de soporte | Obligatoria (una página en GitHub Pages sirve) |
| URL de política de privacidad | Obligatoria (ya resuelto con GitHub Pages en `docs/<slug>/privacy/`) |
| Capturas | Al menos un juego para iPhone de 6,9" o 6,5" (Apple escala al resto). Tamaños típicos: 1320×2868 (6,9") y 1284×2778 o 1242×2688 (6,5"). PNG o JPG sin alfa. Entre 3 y 10. Si se marca soporte iPad, también capturas de iPad 13" (2064×2752). **Recomendación: apps solo iPhone al principio.** |
| Icono | 1024×1024 PNG **sin canal alfa ni transparencia**, esquinas rectas (Apple redondea). Se incluye en el asset catalog del proyecto, no se sube aparte. |
| Clasificación por edad | Cuestionario en la consola (equivalente al content rating de Huawei). Manual. |
| Privacidad de la app ("nutrition labels") | Declarar qué datos recoge la app y los SDKs. Con AdMob: identificadores de dispositivo, datos de uso para publicidad, "usados para rastrearte" si hay ATT aceptado. Manual la primera vez; **la API permite actualizarlo** después. |
| Cumplimiento de exportación | Pregunta sobre cifrado; para apps que solo usan HTTPS estándar se responde que usan cifrado exento; puede fijarse en Info.plist con `ITSAppUsesNonExemptEncryption = NO` para no responder en cada build. |
| Idiomas | Los 9 de la fábrica (en, es, pt, fr, de, it, tr, ar, zh) tienen localización de ficha en App Store Connect. Códigos de Apple: `en-US`, `es-ES`, `es-MX`, `pt-PT`, `pt-BR`, `fr-FR`, `de-DE`, `it`, `tr`, `ar-SA`, `zh-Hans`. **Nota:** difieren de los de Huawei (Huawei usa `ar` y `zh-CN`). El registro debe mapear por plataforma. |

### 4.6 Decisiones que solo el humano puede tomar antes de la primera app iOS

- Tipo de cuenta Apple (individual vs organización) y nombre de vendedor que verán los usuarios.
- Prefijo de Bundle ID (necesita un dominio o identificador propio; `com.huaweiappfactory` no debería usarse en Apple).
- Regla de monetización (4.4).
- Si habrá Mac propio o solo CI.
- Presupuesto y cadencia: dos apps al mes de calidad (ya fijado).

---

## 5. Arquitectura del carril iOS: mapa Android → iOS

| Componente | AppGallery (existe) | App Store (construir) |
|---|---|---|
| Registro | `factory/apps.json`, campos `package`, `agc_app_id`, `ads.banner_ad_id`… | Mismo archivo con `platform: "ios"`, `bundle_id`, `asc_app_id`, `sku`, `team_id` (variable, no secreto), `admob.app_id`, `admob.banner_unit_id`, `admob.interstitial_unit_id`, `iap.remove_ads_product_id` |
| Lenguaje y UI | Kotlin + Jetpack Compose + Material 3 | Swift 5.9+/6 + SwiftUI, iOS 17 mínimo (verificar cuota de dispositivos), arquitectura MVVM con `@Observable` |
| Persistencia | Room | SwiftData (iOS 17+) o Core Data; para lógica pura, structs + tests |
| Tareas en segundo plano / recordatorios | WorkManager + notificaciones | `UNUserNotificationCenter` con notificaciones locales programadas (mucho más fiable que en Android; no hay ANR ni whitelist de batería) |
| Imágenes | Coil + FileProvider + picker | `PhotosPicker` (SwiftUI) y `UIImagePickerController`/cámara; archivos en `Application Support` |
| Build | Gradle 9, JDK 17, `assembleRelease`/`bundleRelease` | `xcodebuild -scheme <App> -configuration Release archive` + `-exportArchive` con `ExportOptions.plist` (method `app-store-connect`) → `.ipa` |
| Proyecto | `settings.gradle.kts`, `build.gradle.kts`, catálogo de versiones | `.xcodeproj` generado con **XcodeGen** o **Tuist** desde un `project.yml` versionado (evita conflictos de merge en el `.pbxproj` y permite que el cerebro edite YAML en lugar de un archivo binario-ish). Recomendado: XcodeGen. |
| Dependencias | Maven (Huawei repo) | Swift Package Manager (AdMob se distribuye como paquete SPM) |
| Firma | Keystore + 4 secretos `RELEASE_*` | Clave API `.p8` + firma gestionada (4.3) |
| Tests unitarios | JUnit en `src/test` | XCTest en target de tests; `xcodebuild test -destination 'platform=iOS Simulator,name=iPhone 16'` |
| Capturas | Emulador Android + `adb` + `uiautomator dump` | Simulador: `xcrun simctl boot`, `xcrun simctl io <udid> screenshot`; para navegar la app, un **test de UI XCTest** que recorre las pantallas y captura con `XCTAttachment`, o `fastlane snapshot`. Preferir el test de UI: es reproducible y vive con la app. |
| Subida de binario | `agc_publish.py` (Publishing API, OBS) | `xcrun altool --upload-app --type ios -f App.ipa --apiKey <KEY_ID> --apiIssuer <ISSUER>` o `fastlane pilot upload`. Procesamiento de 5–30 min antes de poder asignarlo a una versión. |
| Metadatos y capturas | `agc_update_listing.py`, `agc_upload_assets.py` | **App Store Connect API** (REST, JWT ES256 firmado con la `.p8`) o **fastlane deliver** con carpeta `fastlane/metadata/<locale>/*.txt` y `fastlane/screenshots/<locale>/`. Recomendación: **fastlane deliver** para metadatos y capturas; es maduro y evita reimplementar. Para consultas de estado, la API REST directa. |
| Envío a revisión | `--submit` (app-submit) | `deliver --submit_for_review` o API (`reviewSubmissions`). Responder las preguntas de exportación/IDFA en `deliver` (`submission_information`). |
| Prueba previa | Instalar APK en dispositivo | **TestFlight** interno: cada build subido queda disponible para probadores internos sin revisión (hasta 100). Úsalo como compuerta de humo real en un iPhone del usuario. |
| Estado de revisión | Consola / email | API `appStoreVersions` → `appStoreState` (`WAITING_FOR_REVIEW`, `IN_REVIEW`, `PENDING_DEVELOPER_RELEASE`, `READY_FOR_SALE`, `REJECTED`). Sondeo diario en un cron que abre un issue al cambiar. |
| Política de privacidad | GitHub Pages `docs/<slug>/privacy/` | Igual. Añadir sección ATT/AdMob e IDFA. También una **página de soporte** (URL obligatoria). |
| Compuerta de calidad | `check_app.py` | `check_ios_app.py` (sección 7) |
| CI | `factory-build.yml` en `ubuntu-latest` | `factory-ios-build.yml` en `macos-latest` (o `macos-15`): tests + archive + export IPA como artifact |

### 5.1 Herramientas del director de orquesta a crear

| Archivo | Función |
|---|---|
| `factory/tools/asc_client.py` | Cliente mínimo de App Store Connect API: genera JWT (necesita `PyJWT` + `cryptography`, o firmar ES256 con `openssl` desde Python de librería estándar), `GET /v1/apps`, `GET /v1/apps/{id}/appStoreVersions`, `PATCH appStoreVersionLocalizations`, consulta de estado de build y de revisión |
| `factory/tools/asc_upload_build.sh` | Envoltorio de `xcrun altool --upload-app` con la clave API desde secretos |
| `factory/tools/asc_metadata.py` | Convierte `apps-ios/<slug>/store/listing.json` (mismo formato que Android, con códigos de Apple) a la estructura `fastlane/metadata/<locale>/` y llama a `fastlane deliver` |
| `factory/tools/check_ios_app.py` | Compuerta de calidad iOS |
| `.github/workflows/factory-ios-build.yml` | plan (qué app cambió) → verify (gate + `xcodebuild test` + build simulador) → release (archive + export IPA firmado; solo en `main`) |
| `.github/workflows/factory-ios-store.yml` | Metadatos, capturas, URL de privacidad y soporte, privacidad de la app (si la API lo permite para los campos elegidos) |
| `.github/workflows/factory-ios-publish.yml` | Descargar IPA del run de build, subir a App Store Connect, esperar procesamiento, asignar a la versión, opcionalmente enviar a revisión. Misma protección que en Android: **negarse a enviar a revisión si los IDs de AdMob son de prueba** (los IDs de prueba de Google empiezan por `ca-app-pub-3940256099942544`) |

---

## 6. Flujo completo de una app iOS, paso a paso

Notación: **HUMANO** = compuerta que solo la persona puede cruzar. *fábrica* = automatizado o ejecutado por el cerebro.

### Paso 1 — Investigar y proponer (*fábrica*, cron semanal o comando)
- Prompt `10-research.md` adaptado: categorías de utilidad offline aptas para iPhone; puntuar 5 candidatas (demanda, debilidad de competidores, esfuerzo, aptitud para anuncios + compra "quitar anuncios", riesgo de las guías de Apple).
- **Criterios de exclusión específicos de Apple:** nada que Apple considere "mínima funcionalidad" (guía 4.2: linternas, calculadoras triviales, apps de una sola pantalla), nada que duplique una app ya publicada por la misma cuenta (4.3), nada que requiera datos de salud sin justificar (HealthKit tiene reglas propias), nada de contenido generado por usuarios sin moderación.
- Salida: `proposals/<fecha>-<slug>.md` + issue con etiqueta `proposal`.

### Paso 2 — Aprobar (**HUMANO**, 1 clic)
- Etiqueta `approved` en el issue. Las etiquetas `proposal` y `approved` ya existen en el repo.

### Paso 3 — Especificación (*fábrica*)
- Prompt `20-spec.md`: `specifications/<slug>.json` con `platform: "ios"`, `bundle_id`, iOS mínimo, permisos (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSUserTrackingUsageDescription`…), monetización (AdMob + IAP), privacidad (qué se declara en las etiquetas de privacidad), criterios de aceptación testables.
- Entrada en `factory/apps.json` con `status: "planned"`, `asc_app_id: ""`, `admob: {…vacío}`.
- `apps-ios/<slug>/store/listing.json` con los 11 códigos de idioma de Apple (inglés escrito, resto `_todo`).

### Paso 4 — Generación (*fábrica*)
- Prompt `30-generate.md` reescrito para SwiftUI. Esqueleto: una **app plantilla iOS** que hay que crear una vez (paso 10.3): XcodeGen `project.yml`, target app + tests unitarios + tests de UI de capturas, asset catalog con icono 1024 sin alfa, `String Catalog` (`Localizable.xcstrings`) con los 9 idiomas, `PrivacyInfo.xcprivacy`, Info.plist con ATT/SKAdNetwork, integración real de AdMob con IDs desde `xcconfig` (no en código), compra "quitar anuncios" con StoreKit 2, capa de persistencia, navegación por pestañas, ajustes con privacidad/anuncios/acerca de.
- Implementar la spec pantalla a pantalla. Tests XCTest para la lógica pura.
- Verificar en CI (sin Mac local): push a rama `app/<slug>` → workflow `factory-ios-build.yml` en modo PR: gate + tests + build de simulador + **test de UI que genera capturas** como artifact. El cerebro descarga el artifact, mira las capturas (son la única forma de "ver" la app sin Mac) y corrige.
- Ficha en 9 idiomas (`50-listing.md`), política de privacidad y página de soporte (`60-privacy.md`).
- `check_ios_app.py <slug> --strict` debe pasar salvo `admob_unit_ids` (documentado como hueco hasta el paso 6).
- PR con cuerpo: funciones, exclusiones, resultados de tests, salida de la compuerta, caveats.

### Paso 5 — Revisar y mergear (**HUMANO**, minutos)
- Mirar las capturas del PR y el cuerpo. Merge → `factory-ios-build.yml` en `main` produce el **IPA firmado** como artifact.

### Paso 6 — Consola de Apple (**HUMANO**, ~20 minutos la primera vez, ~10 después)
1. developer.apple.com → Identifiers → registrar el **Bundle ID** exacto del registro (App IDs → explicit). Sin esto, la firma en CI falla.
2. App Store Connect → Apps → **+ New App**: plataforma iOS, nombre (30 car.), idioma principal, Bundle ID (aparece en la lista solo si el paso 1 se hizo), **SKU** (cualquier cadena única, ej. el slug), acceso completo.
3. En la app: **App Information** (categoría primaria/secundaria, clasificación por edad → cuestionario), **Pricing and Availability** (gratis, países; **sin Rusia/Bielorrusia** si hay dudas de liquidación; revisar la lista), **App Privacy** (cuestionario de datos; con AdMob declarar identificadores y datos de uso con fines publicitarios y rastreo).
4. **AdMob**: crear la app en AdMob (enlazarla con el bundle ID; AdMob puede pedir que la app esté ya en la tienda para "verificar", pero permite crear unidades antes), crear unidad **Banner** y unidad **Interstitial**. Copiar el **App ID de AdMob** (`ca-app-pub-XXXX~YYYY`) y los dos IDs de unidad.
5. Si hay compra "quitar anuncios": Monetization → In-App Purchases → crear producto no consumible con el `product_id` del registro; rellenar localizaciones y precio.
6. Copiar el **Apple ID de la app** (numérico, en App Information) → `asc_app_id` del registro.
7. Pegar en `factory/apps.json`: `asc_app_id`, `admob.app_id`, `admob.banner_unit_id`, `admob.interstitial_unit_id`, `iap.remove_ads_product_id`. Un push → rebuild con IDs reales (el CI exporta los IDs como variables de entorno que el `xcconfig` lee).

### Paso 7 — Metadatos y capturas (*fábrica*)
- `factory-ios-store.yml`: `fastlane deliver` sube ficha en todos los idiomas, capturas por dispositivo, URLs de soporte y privacidad, palabras clave, texto promocional; **sin** enviar a revisión (`skip_submission`).
- Verificar en la consola que la versión 1.0 muestre todo. La primera vez, el humano ojea la ficha.

### Paso 8 — Subir el build (*fábrica*)
- `factory-ios-publish.yml` con `submit_for_review=false`: descarga el IPA del run, `altool --upload-app`, espera a que App Store Connect procese el build (sondeo por API cada 60 s, hasta 30 min), lo asigna a la versión 1.0.
- El build aparece en **TestFlight → Internal Testing** automáticamente. **Prueba de humo en iPhone real (HUMANO, 5 min):** instalar desde TestFlight, abrir, comprobar que los anuncios de prueba o reales aparecen donde deben y que el flujo principal funciona. Esta compuerta sustituye a nuestro emulador Android y es más fiable.

### Paso 9 — Enviar a revisión (**HUMANO**, 1 clic o comando)
- `factory-ios-publish.yml` con `submit_for_review=true` y notas para el revisor. El workflow **se niega** si los IDs de AdMob son de prueba o si la compuerta estricta falla.
- Revisión típica de 24 a 48 h. Estados por API. Rechazos llegan al Resolution Center con el número de guía; el cerebro propone la corrección mínima (`40-fix-build.md` adaptado), el humano decide.

### Paso 10 — Después de publicar
- Sondeo diario de estado → issue automático al pasar a `READY_FOR_SALE` o `REJECTED`.
- Primera actualización a las 2–4 semanas con correcciones de reseñas: Apple valora la actividad. `SKStoreReviewController.requestReview()` tras un momento de éxito del usuario, nunca al abrir.

---

## 7. Compuerta de calidad iOS (`check_ios_app.py`)

Reglas mínimas, en el mismo esquema PASS / EXCUSED / FAIL con `known_gaps` y `--strict`:

| Regla | Comprueba |
|---|---|
| `ads_sdk` | Dependencia SPM `GoogleMobileAds` presente en `project.yml`/`Package.resolved`; `GADApplicationIdentifier` en Info.plist viene de `xcconfig`, no literal |
| `att_and_skadnetwork` | `NSUserTrackingUsageDescription` y `SKAdNetworkItems` en Info.plist; llamada a `ATTrackingManager.requestTrackingAuthorization` en el código |
| `privacy_manifest` | `PrivacyInfo.xcprivacy` presente con los tipos de datos y "required reason APIs" declarados |
| `admob_unit_ids` | IDs reales en el registro; los de prueba (`ca-app-pub-3940256099942544/*`) no pasan en estricto |
| `iap_configured` | Si `remove_ads_iap: true`, `product_id` presente y referenciado en el código |
| `no_stubs` | Sin `#if false`, `TODO`, `fatalError("unimplemented")`, pantallas placeholder, ni SDKs simulados |
| `forbidden_deps` | Sin Firebase Analytics/Crashlytics u otros SDKs de analítica no declarados; sin bibliotecas de rastreo |
| `identity` | `PRODUCT_BUNDLE_IDENTIFIER` igual al `bundle_id` del registro; `MARKETING_VERSION` y `CURRENT_PROJECT_VERSION` coherentes con el registro |
| `icon` | Icono 1024×1024 en el asset catalog, PNG sin alfa |
| `screenshots` | ≥3 y ≤10 PNG/JPG por juego requerido (6,9" o 6,5"), tamaño exacto de la tabla 4.5 |
| `listing` | Todos los idiomas del registro presentes; límites: nombre ≤30, subtítulo ≤30, promocional ≤170, descripción ≤4000, palabras clave ≤100, novedades ≤4000 |
| `privacy_page`, `support_page` | `docs/<slug>/privacy/index.html` y `docs/<slug>/support/index.html` existen |
| `spec` | Archivo de spec presente |
| `usage_descriptions` | Cada permiso usado tiene su `NS*UsageDescription` con texto real, no genérico (Apple rechaza textos vagos) |
| `tests` | Target de tests unitarios existe y el último run de CI lo ejecutó |

Ejecución: en el workflow de build (no estricto) y antes de publicar (estricto).

---

## 8. Lecciones aprendidas en AppGallery que aplican directamente a iOS

Cada una nos costó al menos una iteración real. No las redescubras.

1. **El código generado puede fingir integraciones.** ReceiptLens tenía un `HuaweiMlKitOcrService` que buscaba clases por reflexión y siempre caía a "no disponible", pero el resumen decía "OCR funcionó". Por eso existe la regla `no_stubs` y la exigencia de instalar y navegar la app. En Swift el equivalente son protocolos con implementaciones vacías, `#if canImport` que nunca se cumple, o `fatalError` detrás de un botón.
2. **Los IDs de anuncio de prueba se cuelan en builds de producción.** Solución que funcionó: el build usa IDs de prueba si faltan los reales pero **avisa**, y el workflow de publicación **se niega a enviar a revisión** con IDs de prueba; la carga sin envío se permite solo con una anulación explícita. Reproducir esto con AdMob.
3. **La tienda tiene límites que solo descubres al llamar a la API.** Huawei: descripción corta ≤80 caracteres, código de idioma árabe `ar` y no `ar-SA`. Apple: los de la tabla 4.5. Codifícalos en la compuerta y en la herramienta de subida **antes** de la primera llamada.
4. **La app no existe para la API hasta que el humano la crea en la consola**, y algunos pasos dependen del orden: en Huawei no había package name hasta subir el primer APK, y la consola de anuncios exigía el paquete antes de crear unidades. En Apple: el Bundle ID debe registrarse antes de firmar, la app debe existir antes de subir, y el build debe procesarse antes de asignarlo. Diseña los workflows para fallar con mensajes que digan exactamente qué paso humano falta.
5. **Países de distribución.** La consola de Huawei bloqueó apps con anuncios en Rusia y Bielorrusia por liquidación de divisa. Revisa la disponibilidad por país en App Store Connect con criterio y deja una lista por defecto en el registro.
6. **Las traducciones automáticas necesitan revisión nativa antes de un lanzamiento serio.** Está anotado en cada `listing.json`. No lo ocultes.
7. **Capturas reales o nada.** Ninguna tienda tolera capturas de UI inventada. En iOS, el test de UI que captura pantallas es la fuente de verdad y además detecta pantallas rotas.
8. **Automatizar la UI a ciegas falla.** En el emulador Android aprendimos: no usar "atrás" para cerrar el teclado (a veces cierra la pantalla), ocultar el teclado virtual durante la automatización, tomar coordenadas de un volcado de accesibilidad y no de una captura escalada, y esperar a que la pantalla se asiente antes de capturar. En iOS, usa XCTest con identificadores de accesibilidad (`accessibilityIdentifier`) en cada control desde el primer día; es infinitamente más fiable que coordenadas.
9. **Los dos primeros bugs de usuario los encontró la prueba en emulador, no el revisor.** Un campo numérico que no se podía borrar; un filtro que mostraba "sin resultados" con datos. Presupuesta esa prueba en cada app.
10. **Compuerta estricta para apps nuevas, huecos documentados para las heredadas.** El patrón `known_gaps` mantuvo el CI honesto y verde a la vez.
11. **Un cambio en el registro compartido recompila todas las apps.** Aceptable con 2 apps; con 10 conviene que el plan del build distinga cambios de registro por app.
12. **Las cuentas se protegen con volumen bajo y calidad alta.** La política anti-spam de las tiendas castiga a la cuenta entera, no a la app. Dos apps al mes, distintas entre sí, con actualizaciones, es una cadencia defendible. Una cada tres días no.

---

## 9. Riesgos y realidades de iOS que el humano debe conocer

- **Guía 4.3 (spam) y 4.2 (mínima funcionalidad).** Apple rechaza apps hechas con plantillas que no aportan algo propio y puede **cerrar la cuenta** por patrones de granja de apps, sin reinstalación. Cada app debe tener una identidad visual y un problema propios; el esqueleto compartido es interno, no visible.
- **ATT reduce el ingreso publicitario.** Una fracción alta de usuarios niega el rastreo; los anuncios se sirven igual pero pagan menos. La compra "quitar anuncios" compensa parte.
- **Revisión humana con criterio variable.** Rechazos por textos de permisos vagos, por metadatos que prometen más de lo que hay, o por capturas que no coinciden con la app son frecuentes y baratos de evitar con la compuerta.
- **Sin Mac, cada iteración cuesta un ciclo de CI.** Estimar 10–20 min por intento. Para dos apps al mes es asumible; un Mac mini de segunda mano lo elimina.
- **Costes fijos:** 99 USD/año Apple; runners macOS gratuitos solo en repositorio público (verificar); AdMob gratuito con umbral de pago de 100 USD; dominio propio para Bundle ID y páginas (opcional pero recomendable).
- **Fecha de datos de este documento: 2026-09-07.** Verificar límites, tamaños de captura, versión mínima de iOS recomendable y políticas antes de codificarlos.

---

## 10. Plan de arranque para la IA sucesora (ordenado)

Cada bloque termina en algo verificable. No pases al siguiente sin cumplir el criterio.

**10.1 Orientación (1 sesión corta).**
Leer `factory/README.md`, `factory/apps.json`, `factory/tools/check_app.py`, `.github/workflows/factory-*.yml`, `docs/RELEASE_STATUS.md`. Confirmar con `gh` que tienes acceso al repo y qué cuenta eres (`gh auth status`): el usuario tiene dos identidades de GitHub; la que administra el repo es `oflorezawaken-dev`, la que suele estar en `gh` es colaboradora sin permisos de administración. Cambios de configuración del repo los hace el humano.
*Criterio:* puedes explicar en cinco líneas cómo se publicó PlantCue.

**10.2 Pedir al humano lo de la sección 4** (sin valores secretos en el chat): confirmación de cuenta Apple activa, prefijo de Bundle ID, decisión de monetización, si habrá Mac, y que cree los secretos `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY_P8` en el entorno `appstore` del repo (crear el entorno). Documentar los nombres en `docs/APPSTORE_PUBLISHING.md`.
*Criterio:* `gh api repos/<repo>/environments/appstore/secrets` lista los tres nombres.

**10.3 Plantilla de app iOS** en `apps-ios/_template/` (o la primera app directamente, como se hizo con ReceiptLens): XcodeGen `project.yml`, SwiftUI, pestañas, SwiftData, String Catalog con 9 idiomas, `PrivacyInfo.xcprivacy`, Info.plist con ATT y SKAdNetwork, AdMob real leyendo IDs de `xcconfig`, StoreKit 2 para "quitar anuncios", ajustes con privacidad/anuncios/acerca de, test unitario de ejemplo, test de UI que captura las pantallas principales a `screenshots/`.
*Criterio:* `factory-ios-build.yml` en verde en `macos-latest`: `xcodebuild test` pasa y el artifact de capturas existe.

**10.4 Herramientas del director** (sección 5.1) y `check_ios_app.py` (sección 7), con dry-run que no llame a Apple.
*Criterio:* `python factory/tools/check_ios_app.py <slug> --strict` corre y reporta; `asc_client.py` obtiene un token y lista las apps de la cuenta.

**10.5 Workflows** `factory-ios-store.yml` y `factory-ios-publish.yml` con las mismas protecciones que los de Android (negarse a enviar con IDs de prueba; carga con anulación explícita; verificación de firma del IPA con `codesign -dv`).
*Criterio:* dry-run en CI de ambos sin error.

**10.6 Primera app real** siguiendo la sección 6 completa, con el humano en sus cuatro compuertas. Elegir una idea con demanda demostrada y baja fricción de revisión (utilidad offline, sin datos sensibles). PlantCue portada a iOS es una candidata razonable: spec, textos, política y capturas ya existen y la demanda se está validando en AppGallery.
*Criterio:* build en TestFlight instalado en el iPhone del usuario, ficha completa en App Store Connect, enviada a revisión con un clic del humano.

**10.7 Vigilancia y actualización.** Cron diario de estado de revisión → issue. Prompt de "responder a un rechazo" con el número de guía.
*Criterio:* un cambio de estado abre un issue solo.

**10.8 Segunda app** en el mismo mes, distinta en categoría y aspecto. Medir tiempo humano total; el objetivo es ≤1 hora por app fuera de la creación en consola.

---

## 11. Apéndices

### 11.1 Entrada de registro propuesta para una app iOS

```json
{
  "slug": "plant-cue-ios",
  "platform": "ios",
  "name": "PlantCue",
  "path": "apps-ios/plant-cue",
  "bundle_id": "com.TU_DOMINIO.plantcue",
  "asc_app_id": "",
  "sku": "plant-cue-ios",
  "team_id": "TEAM_ID_AQUI",
  "min_ios": "17.0",
  "spec": "specifications/plant-cue-ios.json",
  "store_dir": "apps-ios/plant-cue/store",
  "privacy_path": "docs/plant-cue/privacy",
  "support_path": "docs/plant-cue/support",
  "status": "planned",
  "current_version": { "marketing_version": "1.0.0", "build": 1, "status": "planned" },
  "admob": { "app_id": "", "banner_unit_id": "", "interstitial_unit_id": "" },
  "iap": { "remove_ads_product_id": "com.TU_DOMINIO.plantcue.removeads" },
  "known_gaps": {}
}
```

Y en `defaults`: `ios_locales` con el mapa de la fábrica → Apple (`en → en-US`, `es → es-ES`, `pt → pt-PT`, `fr → fr-FR`, `de → de-DE`, `it → it`, `tr → tr`, `ar → ar-SA`, `zh → zh-Hans`), `screenshot_devices` con los tamaños exigidos, `admob_test_ids_prefix: "ca-app-pub-3940256099942544"`.

### 11.2 Esqueleto de `factory-ios-build.yml`

```yaml
name: Factory iOS Build
on:
  push: { branches: [main], paths: ['apps-ios/**', 'factory/**', '.github/workflows/factory-ios-build.yml'] }
  pull_request: { paths: ['apps-ios/**', 'factory/**'] }
  workflow_dispatch: { inputs: { app: { description: 'slug (empty = all ios apps)', required: false, default: '' } } }
permissions: { contents: read }
jobs:
  plan:
    runs-on: ubuntu-latest
    outputs: { apps: ${{ steps.plan.outputs.apps }} }
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - id: plan
        run: |
          # igual que factory-build.yml, filtrando platform == ios y carpetas con project.yml
          echo "apps=$(python3 factory/tools/registry.py plan-ios "${{ github.event_name }}" "${{ github.event.before }}" "${{ github.sha }}" "${{ inputs.app }}")" >> "$GITHUB_OUTPUT"
  verify:
    needs: plan
    if: needs.plan.outputs.apps != '[]'
    runs-on: macos-latest
    strategy: { fail-fast: false, matrix: { app: "${{ fromJson(needs.plan.outputs.apps) }}" } }
    steps:
      - uses: actions/checkout@v4
      - run: python3 factory/tools/registry.py env "${{ matrix.app }}" >> "$GITHUB_ENV"
      - run: python3 factory/tools/check_ios_app.py "$APP_SLUG"
      - run: brew install xcodegen && cd "$APP_PATH" && xcodegen generate
      - run: cd "$APP_PATH" && xcodebuild test -scheme "$APP_SCHEME" -destination 'platform=iOS Simulator,name=iPhone 16' -resultBundlePath TestResults.xcresult
      - run: cd "$APP_PATH" && xcodebuild test -scheme "${APP_SCHEME}Screenshots" -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' || true
      - uses: actions/upload-artifact@v4
        with: { name: "${{ matrix.app }}-screenshots", path: "${{ env.APP_PATH }}/screenshots/**/*.png" }
  release:
    needs: [plan, verify]
    if: github.event_name != 'pull_request' && github.ref == 'refs/heads/main'
    runs-on: macos-latest
    environment: appstore
    strategy: { matrix: { app: "${{ fromJson(needs.plan.outputs.apps) }}" } }
    steps:
      - uses: actions/checkout@v4
      - run: python3 factory/tools/registry.py env "${{ matrix.app }}" >> "$GITHUB_ENV"
      - name: Materialize ASC API key
        env: { P8_B64: "${{ secrets.ASC_PRIVATE_KEY_P8 }}" }
        run: |
          mkdir -p "$RUNNER_TEMP/keys"; printf '%s' "$P8_B64" | base64 --decode > "$RUNNER_TEMP/keys/AuthKey.p8"; chmod 600 "$RUNNER_TEMP/keys/AuthKey.p8"
      - run: brew install xcodegen && cd "$APP_PATH" && xcodegen generate
      - name: Archive (cloud-managed signing)
        run: |
          cd "$APP_PATH"
          xcodebuild -scheme "$APP_SCHEME" -configuration Release -destination 'generic/platform=iOS' \
            -archivePath build/App.xcarchive archive \
            -allowProvisioningUpdates \
            -authenticationKeyPath "$RUNNER_TEMP/keys/AuthKey.p8" \
            -authenticationKeyID "${{ secrets.ASC_KEY_ID }}" \
            -authenticationKeyIssuerID "${{ secrets.ASC_ISSUER_ID }}" \
            ADMOB_APP_ID="$ADMOB_APP_ID" ADMOB_BANNER_UNIT_ID="$ADMOB_BANNER_UNIT_ID" ADMOB_INTERSTITIAL_UNIT_ID="$ADMOB_INTERSTITIAL_UNIT_ID"
      - name: Export IPA
        run: |
          cd "$APP_PATH"
          xcodebuild -exportArchive -archivePath build/App.xcarchive -exportPath build/ipa \
            -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates \
            -authenticationKeyPath "$RUNNER_TEMP/keys/AuthKey.p8" \
            -authenticationKeyID "${{ secrets.ASC_KEY_ID }}" -authenticationKeyIssuerID "${{ secrets.ASC_ISSUER_ID }}"
      - uses: actions/upload-artifact@v4
        with: { name: "${{ matrix.app }}-release-ipa", path: "${{ env.APP_PATH }}/build/ipa/*.ipa", if-no-files-found: error }
      - if: always()
        run: rm -rf "$RUNNER_TEMP/keys"
```

`ExportOptions.plist` mínimo: `method = app-store-connect`, `signingStyle = automatic`, `teamID = <TEAM_ID>`, `uploadSymbols = true`.

### 11.3 Comandos útiles

```bash
# Subir un IPA con la clave de API (el .p8 debe estar en ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8 o pasar --apiKey/--apiIssuer)
xcrun altool --upload-app --type ios -f App.ipa --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"

# Simulador: arrancar, instalar, capturar
xcrun simctl list devices available
xcrun simctl boot "iPhone 16 Pro Max"
xcrun simctl install booted build/Debug-iphonesimulator/App.app
xcrun simctl launch booted com.TU_DOMINIO.plantcue
xcrun simctl io booted screenshot shot.png

# Verificar firma del IPA
unzip -q App.ipa -d ipa && codesign -dv --verbose=4 ipa/Payload/*.app

# JWT para App Store Connect API (Python con PyJWT + cryptography)
# payload: {"iss": ISSUER_ID, "iat": now, "exp": now+1200, "aud": "appstoreconnect-v1"}; header: {"kid": KEY_ID, "alg": "ES256", "typ": "JWT"}
# GET https://api.appstoreconnect.apple.com/v1/apps  con  Authorization: Bearer <jwt>
```

### 11.4 Glosario rápido Android → iOS

| Android / Huawei | iOS / Apple |
|---|---|
| package name | Bundle ID |
| versionCode / versionName | CURRENT_PROJECT_VERSION (build) / MARKETING_VERSION |
| APK / AAB | IPA (exportado de un .xcarchive) |
| keystore | certificado de distribución + perfil de aprovisionamiento |
| AppGallery Connect | App Store Connect |
| Publishing API (client_id/secret) | App Store Connect API (Key ID + Issuer ID + .p8, JWT) |
| App ID de AGC | Apple ID de la app (numérico) + SKU |
| Petal Ads | AdMob (o alternativa) + ATT |
| content rating | Age rating |
| strings.xml por idioma | String Catalog (.xcstrings) |
| emulador + adb | simulador + xcrun simctl + XCTest UI |
| Gradle | xcodebuild (+ XcodeGen) |
| GitHub Actions ubuntu | GitHub Actions macOS |

### 11.5 Lo que este documento no incluye a propósito

Valores de secretos, IDs de anuncio de producción de Android (están en el repo público porque no son secretos, pero no se copian aquí), y detalles de la cuenta de Huawei que no afectan a iOS. Para el historial completo de lo hecho en AppGallery, leer `docs/RELEASE_STATUS.md`.

---

*Escrito el 2026-09-07 por la IA que construyó el carril AppGallery, a petición del propietario, para que otra IA construya el carril iOS sin repetir el camino.*
