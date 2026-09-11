# PriceJar 1.0.0 — retrospectiva del primer recorrido completo del carril iOS

> **Para qué sirve este documento.** PriceJar fue la primera app que pasó por el carril iOS de
> punta a punta: investigación de mercado → spec → generación → build firmado → TestFlight →
> ficha en 9 idiomas → capturas → envío a revisión. Salieron 13 fallos reales. Todos están
> arreglados, pero **la mitad no eran arreglables antes de tener a Apple delante**: eran
> suposiciones que solo se rompen contra la API real.
>
> Esto no es un registro histórico. Es la lista de lo que la app nº2 **no** debería volver a
> pagar, y de lo que todavía va a doler.
>
> Fecha del recorrido: 2026-09-08 / 09. Commits de referencia: `b448f8f`..`c29b037`.

---

## 1. El recorrido limpio para la app nº2

Este es el orden real, ya con todo lo aprendido. Los pasos marcados **[humano]** no se pueden
automatizar: son formularios de consola de Apple o decisiones tuyas.

| # | Paso | Quién | Notas |
|---|---|---|---|
| 1 | Investigación de mercado (`10-research-ios`) | Opus | Enfocada a App Store, nunca un port de una app Huawei |
| 2 | **Aprobar la propuesta** | **[humano]** | Puerta 1 |
| 3 | Spec (`20-spec-ios`) | Opus | Aquí se decide `devices: [iPhone]` o `[iPhone, iPad]` — ver trampa #7 |
| 4 | **Registrar el Bundle ID** en developer.apple.com | **[humano]** | Sin esto la firma en CI falla |
| 5 | **Crear la app** en App Store Connect, pegar `asc_app_id` en el registro | **[humano]** | El Bundle ID solo aparece tras el paso 4 |
| 6 | **AdMob**: crear app + unidades, pegar los 3 IDs | **[humano]** | Con IDs de test el gate `--strict` bloquea el envío |
| 7 | Generación (`30-generate-ios`) | Sonnet | |
| 8 | Build + tests + capturas (`factory-ios-build`) | CI | Cuenta con **1–2 reintentos** por el test inestable |
| 9 | Ficha y capturas (`factory-ios-store`, `what=all`) | CI | |
| 10 | **Los 6 pasos de consola** (5 formularios + el IAP) | **[humano]** | Ver §2 — es donde más vueltas se perdieron |
| 11 | Subida + envío (`factory-ios-publish`, `submit_for_review=true`) | CI | |

**Puertas humanas reales: 4** (aprobar propuesta, crear app+Bundle ID, AdMob, formularios de
consola). El resto es automático.

---

## 2. Los seis pasos de consola — hazlos ANTES de lanzar el envío

Los cinco primeros son formularios: Apple rechaza el envío entero si falta cualquiera, y **no
dice cuál falta** por la API. En este recorrido eso costó cuatro intentos de envío. Rellénalos
todos de una vez, en el paso 10:

1. **Pricing and Availability** — precio y territorios.
2. **Clasificación por edad** (App Information) — cuestionario.
3. **Privacidad de la app** — cuestionario de recopilación de datos, y hay que **publicarlo**.
4. **Información de contacto de revisión** — nombre, apellido, email y teléfono. Los cuatro.
5. **Derechos sobre el contenido** — la pregunta de si usas contenido de terceros.

`asc_publish.py` sondea Pricing, contacto y export compliance y te dice cuáles fallan. Los otros
dos (clasificación por edad y privacidad) los reporta como `?` — **mis URLs de sonda están mal**
y devuelven 404; ver deuda abierta §5.

### 6. La compra integrada, si la app la tiene

Este no bloquea el envío, y por eso es más peligroso que los otros cinco: **el envío sale
adelante sin él y el problema aparece en la revisión**.

Si el spec declara `remove_ads_iap`, hay que crear el producto en **Monetization → In-App
Purchases**:

- Tipo **No consumible** (compra única y permanente; ni suscripción ni consumible).
- **Product ID** idéntico carácter por carácter a `iap.remove_ads_product_id` del registro.
  StoreKit busca por esa cadena exacta.
- Precio, y localizaciones (nombre y descripción visibles en la hoja de compra) al menos en el
  idioma principal.
- **Captura de revisión y notas**: Apple revisa el producto aparte de la app y exige una captura
  de la pantalla donde se ofrece la compra.
- En una primera publicación, el producto **se envía junto con la versión**.

Si el producto no existe, `Product.products(for:)` devuelve vacío, `product` queda `nil` y
`purchase()` marca `purchaseFailed` sin abrir siquiera la hoja de compra: el revisor toca el
botón y no ocurre nada. Eso es rechazo por directriz 2.1.

**El gate no detecta esto.** `iap_configured` comprueba que el `product_id` esté en el registro y
referenciado en Swift — nada más. Pasa en verde con el producto sin crear, que es exactamente lo
que ocurrió con PriceJar: el paso nunca se ejecutó en este recorrido y salió a la luz cuando el
usuario preguntó por él, con la app ya en revisión.

---

## 3. Las 13 trampas, y dónde quedaron cerradas

Ninguna de estas debería repetirse. La columna «cómo se veía» es lo importante: casi ninguna se
presentó como lo que era.

| # | Cómo se veía | Qué era en realidad | Arreglado en |
|---|---|---|---|
| 1 | `APP_IPHONE_69` aceptado por el gate, rechazado por Apple | Valor inventado; existía una copia del enum fuera del registro | `0b5c52c` |
| 2 | `409 whatsNew cannot be edited` en los 9 idiomas | Una primera versión no puede llevar «Novedades» | `adfb731`, `0aa9731` |
| 3 | `HTTP 400` al leer el estado de la versión | Usé tres nombres de campo distintos, ninguno verificado | `32e0f2e` |
| 4 | `-19232 bundle version already used` al reintentar | Reintentar no debería exigir subir el build number | `6a44a04` |
| 5 | `ITMS-90474` al subir el IPA | Faltaba `UIRequiresFullScreen` con soporte iPad | `e7ede49` |
| 6 | `409 Screenshot Set Already Exists!` | Creaba el set sin buscarlo antes | `888cb6f` |
| 7 | App iPhone-only publicada como universal | `TARGETED_DEVICE_FAMILY` nunca se fijaba | `e6d4738` |
| 8 | Test de capturas fallando solo en iPad | El iPad no tiene tab bar; las pestañas son botones normales | `cfd8168` |
| 9 | `409 Too many screenshots (10)` | Subir siempre añadía, nunca reemplazaba | `c509643` |
| 10 | `Unable to find a device matching the destination` | El nombre del iPad lleva paréntesis: `iPad Pro 13-inch (M5)` | `f8f8fc9` |
| 11 | `not in valid state` sin decir qué falta | Lista estática + submission huérfana bloqueando reintentos | `9dd439b` |
| 12 | Cinco capturas «subidas» que la consola mostraba en rojo | Se reportaba éxito con el 200 del PATCH, sin preguntar a Apple | `1c3a45d` |
| 13 | `IMAGE_INCORRECT_DIMENSIONS` en las capturas de iPad | **Apple ignora `filter[screenshotDisplayType]`**: las de iPad iban al set de iPhone | PR #30 |

### La trampa 13 merece su propio párrafo

Es la más cara del recorrido y la más engañosa. El error decía «dimensiones incorrectas», así que
gasté **dos intentos redimensionando imágenes que ya tenían el tamaño correcto**. La causa era
que `filter[screenshotDisplayType]` no filtra nada: Apple devuelve todos los sets y el código
tomaba el primero, el de iPhone. De ahí salían tres síntomas a la vez — las de iPad rechazadas,
las de iPhone **borradas** al «limpiar el set de iPad», y un log diciendo que todo había subido.

**Lección aplicable a cualquier `filter[...]` de la API de Apple: no confíes en que filtre.**
Trae las filas y compara en el cliente. En `submit_for_review` ya había pasado antes de otra
forma (un `filter[]` inválido tumba la petición entera con 400).

---

## 4. El patrón que se repitió cuatro veces: el mock era más amable que Apple

Cada vez que algo pasó las pruebas y falló contra Apple, el mock había fingido un
comportamiento que Apple no tiene:

| El mock hacía | Apple hace |
|---|---|
| Creación de sets idempotente | `409 Screenshot Set Already Exists!` |
| Aceptaba `DELETE /v1/reviewSubmissions/...` | `403 does not allow 'DELETE'` |
| Honraba `filter[screenshotDisplayType]` | Lo ignora y devuelve todo |
| Daba el asset por bueno tras el PATCH | Valida después, y puede rechazarlo |

**Regla para la app nº2:** cuando escribas un mock de la API de Apple, hazlo *hostil*. Si no
sabes cómo se comporta Apple en un caso, el mock debe fallar, no pasar. Un mock generoso no es
una prueba: es una suposición con traje de prueba.

Y la fixture importa tanto como el mock: la de capturas tenía **una sola imagen**, así que la
prueba no podía detectar el bug de «la segunda captura aborta el run» aunque el mock hubiera
sido correcto.

---

## 5. Deuda abierta — estado tras dos apps (2026-09-11)

| Qué | Estado |
|---|---|
| Test de capturas inestable | **Cerrado.** Era un bug de producto: ATT sin guard de test bloqueaba el cierre de una hoja. Arreglado en la app, el template y el prompt (#34, #48) |
| Certificados de firma se agotan | **Cerrado (#58).** No faltaba un certificado guardado: el archive se firmaba para *desarrollo* y cada runner efímero acuñaba uno. Se archiva sin firmar; el export sigue con firma cloud-managed de distribución. Queda **un paso manual único**: revocar los de desarrollo ya acumulados, que el arreglo no libera |
| Submissions colgadas | **Abierto, y peor de lo que creía.** Apple no permite `DELETE` (403) **ni** `PATCH canceled` en `READY_FOR_REVIEW` (409). Recuperación solo desde consola: *Eliminar de revisión* |
| Sondas de diagnóstico | Clasificación por edad **arreglada** (`appInfos`, #50). App Privacy **no está en la API** — confirmado en la spec; se reporta como consola-only |
| El gate no ve el IAP de consola | **Parcial.** El envío se niega si ningún IAP está en estado enviable (#47). El gate sigue sin verlo antes |
| `apps-ios/price-jar/ipad-out/` | Sigue ahí. Borrar |
| Registro con un solo tamaño de iPad | Sin cambios |
| **Envío automatizado a revisión** | **Con red, sin estrenar contra Apple.** Las formas se validan offline (#55), la versión y el IAP los crea la fábrica (#56), y el envío lee de vuelta build y contenido antes del PATCH final (#57). Nada de eso se ha ejercitado aún en un envío real: trátalo como supervisado la primera vez |

---

## 6. Lo que costó, para calibrar la próxima

- **13 fallos reales**, 12 cerrados y 1 en PR sin mergear.
- **4 intentos de envío a revisión** antes de que Apple lo aceptara.
- **6 ejecuciones** del workflow de capturas hasta dejarlas bien.
- La mayor parte del tiempo no se fue en escribir código, sino en **descubrir en qué mentía la
  API respecto a lo que yo había supuesto**.

La app nº2 debería ahorrarse los 13 fallos y las vueltas de los formularios de consola. Lo que
no se ahorra es el test inestable ni los certificados, y eso son las dos cosas que conviene
arreglar antes de empezar.

---

## 7. Segundo recorrido: ShiftSlip — el barrido que pediste

ShiftSlip fue de propuesta a IPA firmado **sin un solo fallo de la app**: las 13 trampas de PriceJar
no reaparecieron. Aun así el recorrido costó **~20 PRs de corrección** (#34–#54) y **cuatro
ejecuciones fallidas de envío**. Casi ninguno era un bug nuevo: eran **seis patrones**, repetidos.

### 7.1 Los seis patrones, con recuento

| # | Patrón | Veces | Ejemplos |
|---|---|---|---|
| A | **Forma de la API adivinada**, y el mock diciendo que sí | **8** | `appStoreVersionState`, `APP_IPHONE_69`, `DELETE reviewSubmissions` (403), `inAppPurchaseV2` (409), `ageRatingDeclaration` en versiones (404), `appDataUsages` (404), `PATCH canceled` (409), `filter[screenshotDisplayType]` ignorado |
| B | **Regla escrita en prosa, sin comprobación donde toca** | 5 | guard de ATT en un comentario; set de iPad "required whenever…"; regla 5 de ad IDs; IAP fuera del gate; ficha sin escanear |
| C | **Comprobar la intención, no el artefacto** | 4 | gate lee `project.yml` y el binario era universal; "uploaded" por un 200 y Apple lo rechazó después; `bootstatus` sale 0 con el simulador muerto; conclusión del run y no del job |
| D | **Local ≠ CI, en silencio** | 4 | XcodeGen 2.42 vs 2.46; orden de runtimes del simulador; `FACTORY_VARS` por paso; workflows sin verificar en PR |
| E | **El spec arrastraba un diseño rechazado** | 1 | ATT tras la primera acción → ShiftSlip nació con el rechazo de PriceJar |
| F | **Copiar entre apps dando por hecho que son iguales** | 1 | `tab("Settings")` de PriceJar en una app sin esa pestaña |

**El patrón A solo explica más de un tercio de todo el tiempo perdido**, y es el único que se
puede eliminar de raíz: Apple publica la especificación OpenAPI de la API completa.

### 7.1b Una corrección que estuve a punto de escribir, y no debí

Investigando el paso 4, dos verificadores afirmaron con alta confianza que la atribución
«XcodeGen 2.42 vs 2.46» era falsa y que había que corregirla en cinco sitios. Antes de tocar la
documentación lo medí con los dos binarios reales, resolviendo con `xcodebuild -showBuildSettings`
en vez de leer el `pbxproj` crudo:

| generador | `TARGETED_DEVICE_FAMILY` solo a nivel de proyecto | resuelve |
|---|---|---|
| **2.46.0** | `"1"` | **`1,2`** |
| 2.42.0 | `"1"` | `1` |

La atribución original era **correcta**; los verificadores leyeron entradas del `pbxproj` en vez de
los ajustes resueltos. La lección no es «no usar verificadores» — dos de ellos tumbaron una
recomendación que directamente no compilaba (`CODE_SIGN_IDENTITY: "Apple Distribution"` bajo firma
automática: *conflicting provisioning settings*) y otro destripó un script de importación de `.p12`
que fallaba en silencio. La lección es que **un agente seguro de sí mismo no es evidencia**, igual
que un 201 no lo era. Medirlo costó cinco minutos; escribir una falsedad en la fábrica habría
costado la próxima app.

### 7.2 Lo que la spec responde en una pasada, offline

Comprobado el 11-09 contra la spec 4.4.1 (966 rutas), sin una sola llamada a Apple:

- La relación del IAP en un envío es **`inAppPurchaseVersion`** — ni `inAppPurchase` ni
  `inAppPurchaseV2`; mi "probar los dos candidatos" habría fallado otra vez.
- `reviewSubmissions/{id}` admite solo **GET y PATCH**. No hay DELETE.
- `ageRatingDeclaration` cuelga de **`appInfos`**. `appDataUsages` **no existe**: App Privacy no
  está en la API.
- **`POST /v1/appStoreVersions`** existe: crear la versión no tiene por qué ser un paso humano.
- **El IAP completo es automatizable**: `/v2/inAppPurchases`, localizaciones, precio, captura de
  revisión (`inAppPurchaseAppStoreReviewScreenshots`), y `inAppPurchaseSubmissions`.
- **La lectura que faltaba existe**: `/v1/reviewSubmissions/{id}/items` y
  `/v1/appStoreVersions/{id}/build`. "¿Qué build lleva la versión?" y "¿va la compra dentro?" dejan
  de ser preguntas para el humano.

Límite honesto: la spec valida **forma**, no comportamiento. `filter[screenshotDisplayType]` está
en la spec y Apple lo ignora igual. El mock sigue teniendo que ser hostil.

### 7.3 Lo que cambia en la fábrica (en este orden)

1. **Hecho:** `test_asc_api_shapes.py` valida cada `api_call` de las herramientas contra la spec
   (ruta, verbo, filtros, relaciones). Lo primero que cazó fue `appDataUsages`; lo segundo, que
   una clave variable en las relaciones dejaba la comprobación en blanco. Cuatro de los ocho
   fallos del patrón A habrían muerto aquí.
2. **Hecho:** `asc_setup.py` crea la versión y el IAP completo — localizaciones desde el bloque
   `iap` de `listing.json`, disponibilidad en todos los territorios, precio desde `iap.price_usd`
   resuelto a un price point de USA, y la captura de revisión (`store/iap-review-screenshot.png`)
   esperando el `COMPLETE` de Apple. Idempotente: la segunda ejecución hace cero POSTs. Cada
   ruta salió de la spec y la comprueba `test_asc_api_shapes.py` (46 llamadas). El gate exige
   la copia y la captura (`iap_store_copy`) antes de que nada llegue a Apple. Es `what=setup` en
   `factory-ios-store.yml`, y parte de `all`.
3. **Hecho:** lectura de vuelta antes de enviar. `verify_attached_build` comprueba con
   `/v1/appStoreVersions/{id}/build` que la versión lleva el build de esta ejecución — una versión
   puede quedarse con uno anterior y Apple no protesta. `verify_submission_contents` pregunta a
   Apple, vía `/v1/reviewSubmissions/{id}/items?include=…`, qué contiene el envío antes del PATCH
   final, y **se niega a enviar** si falta la versión o alguna compra. Los 201 de los POST no eran
   prueba: el envío que llegó a revisión sin la compra los tuvo todos.
4. **Hecho, y no como estaba planeado (#58).** El límite de certificados **no** se arreglaba
   guardando un certificado en secrets: **el archive se firmaba para desarrollo**. Nada fija
   `CODE_SIGN_IDENTITY` y el valor por defecto de Xcode es `Apple Development` en *todas* las
   configuraciones — Release es solo un nombre. Con firma automática, cada runner efímero, con el
   llavero vacío, acuñaba un certificado de desarrollo nuevo; y los de desarrollo **no** pueden ser
   cloud-managed, así que no había reutilización posible. La firma del archive se descarta acto
   seguido — el export vuelve a firmar para `app-store-connect` — así que **archivar sin firmar**
   elimina la causa sin guardar ningún secreto. Medido: 0 líneas de provisioning, archive producido.
   De paso, la comprobación de firma del IPA solo exigía «que exista alguna firma», y un export con
   identidad de desarrollo la pasaba; ahora exige autoridad **Apple Distribution**. Y XcodeGen queda
   fijado en **2.46.0** por artifactbundle con SHA256 verificado.
5. Hasta que 2 y 3 existan, **el envío a revisión se hace desde la consola**. Es lo que
   funcionó en ambas apps; el automatizado lleva cuatro fallos seguidos y deja estado que Apple no
   permite deshacer.

### 7.4 Coste, para calibrar

- PriceJar: 1 rechazo (3 motivos), 5 builds, 4 intentos de envío.
- ShiftSlip: 0 fallos de app, 2 builds, **4 ejecuciones de envío fallidas**, envío final desde consola.
- Regla que sale de todo esto: **ninguna llamada nueva a la API de Apple sin pasar por la spec
  primero.** Cada nombre adivinado costó, de media, una ejecución real y a veces estado irreversible.
