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

## 5. Deuda abierta — esto SÍ va a doler en la app nº2

Honestamente, la fábrica está más afinada, pero no está limpia:

| Qué | Impacto en la próxima app | Estado |
|---|---|---|
| **Test de capturas inestable** | Falla ~2 de cada 5 arranques en frío, en la aserción de la pestaña *Shopping List*. **Bloquea el job `release`**, no solo el reporte | Sin diagnosticar (decisión tuya de no seguir investigando). Cuenta con reintentar el run |
| **Certificados de firma se agotan** | Cada runner efímero crea un certificado de desarrollo nuevo. El límite de Apple se alcanza y hay que revocarlos a mano | Sin arreglar. Se resuelve con un certificado guardado en secrets en vez de firma cloud-managed |
| **Limpieza de `reviewSubmission` no funciona** | Apple devuelve `403` al `DELETE`. Hoy hay **4 submissions abiertas** acumuladas en PriceJar | Hay que cambiarlo a `PATCH {canceled: true}` |
| **Sondas de diagnóstico con URL mal** | Clasificación por edad y App Privacy salen `?` en vez de `!!`/`ok` | `ageRatingDeclaration` cuelga de `appInfos`, no de `appStoreVersions`; `appDataUsages` no es relación de `apps` |
| **PR #30 sin mergear** | **La trampa 13 sigue viva en `main`**. La app nº2 volvería a mandar las capturas de iPad al set de iPhone | Mergear antes de empezar |
| **El gate no ve el IAP de consola** | `iap_configured` pasa en verde aunque el producto no exista en App Store Connect. La app llega a revisión con el botón de compra muerto | Sin arreglar. Se detectaría con `GET /v1/apps/{id}/inAppPurchases` — verificar el nombre del endpoint antes de usarlo |
| **`apps-ios/price-jar/ipad-out/`** | 5 PNG crudos commiteados por error; basura de trabajo | Borrar |
| **Registro con un solo tamaño de iPad** | Solo `2064x2752`. Apple documenta también `2048x2732`, pero no está probado: el único intento estuvo contaminado por la trampa 13 | Dejarlo así hasta comprobarlo |

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
