<!-- cspell:disable -->
# Michi Link Móvil

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Analysis](https://img.shields.io/badge/Style-Very%20Good%20Analysis-blueviolet.svg)](https://pub.dev/packages/very_good_analysis)

Una aplicación móvil desarrollada en Flutter diseñada para la localización, rastreo y monitoreo de mascotas (específicamente gatos) mediante tecnología de radiofrecuencia de largo alcance **LoRa** y posicionamiento satelital **GPS**. Proporciona seguimiento cartográfico en tiempo real, perímetros virtuales de geocercas, telemetría avanzada del radioenlace (RSSI, SNR, tasa de pérdida de paquetes), monitoreo del estado y voltaje de batería, alertas de seguridad instantáneas y reproducción de rutas históricas.

---

## 🚀 Inicio Rápido

### Requisitos Previos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (versión `>= 3.47.0`)
- [Dart SDK](https://dart.dev/get-dart) (versión `>= 3.12.0 < 4.0.0`)
- Android Studio o Xcode configurado con simuladores, emuladores o dispositivos físicos de prueba.
- Claves de API válidas configuradas para **Google Maps** (Android e iOS) y un proyecto de **Firebase** aprovisionado.

### Pasos de Instalación

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/Piero16301/Michi_Link.git
   cd Michi_Link/michi_link_mobile
   ```

2. **Instalar dependencias:**
   ```bash
   flutter pub get
   ```

3. **Generar archivos de localización e internacionalización:**
   ```bash
   flutter gen-l10n
   ```

4. **Configurar credenciales y variables de entorno:**
   - **Android**: Asegurar que el archivo `android/app/google-services.json` esté presente y que la clave de Google Maps esté declarada en `android/app/src/main/AndroidManifest.xml`.
   - **iOS**: Asegurar que el archivo `ios/Runner/GoogleService-Info.plist` esté presente y que la clave de Google Maps esté configurada en `ios/Runner/AppDelegate.swift`.
   - La aplicación admite dos entornos: `Environment.mock` (telemetría y collares simulados localmente sin dependencias en la nube) y `Environment.prod` (transmisiones reactivas en vivo vía Cloud Firestore). Configurable en `lib/main.dart`.

5. **Ejecutar la aplicación:**
   ```bash
   flutter run
   ```

---

## 🛠️ Comandos Comunes

| Comando | Descripción |
| :--- | :--- |
| `flutter pub get` | Descarga e instala las dependencias del proyecto. |
| `flutter run` | Inicia la aplicación en el dispositivo conectado o simulador. |
| `flutter run -d chrome` | Ejecuta la aplicación en Google Chrome (modo de inspección web). |
| `flutter test` | Ejecuta la suite de pruebas unitarias y de widgets. |
| `flutter test --coverage` | Ejecuta las pruebas y genera el reporte LCOV en `coverage/lcov.info`. |
| `flutter analyze` | Ejecuta el análisis estático de código mediante `very_good_analysis` y `bloc_lint`. |
| `dart fix --apply` | Aplica automáticamente correcciones recomendadas por el linter en archivos Dart. |
| `flutter gen-l10n` | Regenera las clases tipadas de localización desde las plantillas `.arb`. |
| `dart run flutter_launcher_icons` | Genera los iconos adaptativos de la app para Android e iOS. |
| `flutter build apk --release` | Compila el instalador APK optimizado para producción en Android. |
| `flutter build appbundle --release` | Genera el Android App Bundle (AAB) para publicación en Google Play. |
| `flutter build ipa --release` | Genera el archivo de distribución para iOS (App Store / TestFlight). |

---

## 🧭 Características Principales

- **🛰️ Rastreo GPS en Tiempo Real y Telemetría LoRa**: Visualización continua de las coordenadas del felino, distancia geodésica a la estación base hogareña (`distanceHomeM`), potencia de señal de radio (`rssi`), relación señal/ruido (`snr`) y porcentaje de paquetes perdidos.
- **🛡️ Geocercas Virtuales Dinámicas**: Radio seguro de desplazamiento configurable (`maxDistanceM`). Notificaciones visuales y auditivas inmediatas al cruzar o reingresar al perímetro seguro.
- **🔋 Monitoreo de Batería y Sensores de Hardware**: Indicador de porcentaje y voltaje de la batería (`batteryV`), estado de fijación GNSS (`gpsFix`) y recuento de satélites enlazados (`sats`).
- **🗺️ Experiencia Cartográfica Fluida**: Integración con Google Maps incorporando avatares vectoriales por raza de gato convertidos a marcadores nativos, estilos claros y oscuros, y centrado dinámico.
- **📜 Rutas Históricas y Migajas de Pan**: Consulta de posiciones pasadas filtradas cronológicamente, visualizando el recorrido sobre el mapa mediante polilíneas.
- **🔔 Centro de Notificaciones y Registro de Alertas**: Clasificación de incidentes por severidad (`CRITICAL`, `WARNING`, `INFO`) ante salidas de geocerca, batería crítica o degradación del radioenlace.
- **🐈 Gestión de Múltiples Collares y Razas**: Compatibilidad con múltiples dispositivos simultáneos, nombres personalizados y avatares SVG para 10 razas de gatos distintas.
- **🎨 Sistema de Diseño Expresivo**: Construido con **Material 3 Expressive** (`expressive_kit`), generando dinámicamente paletas cromáticas tonales a partir de un color semilla configurable por el usuario.
- **🌐 Internacionalización (i18n / l10n)**: Soporte completo en español e inglés con cambio dinámico de idioma en tiempo de ejecución.

---

## 🏗️ Arquitectura y Estructura del Proyecto

El proyecto sigue una arquitectura **Feature-First** (por funcionalidades) con separación estricta de responsabilidades y flujo unidireccional de datos:

```text
lib/
├── app/                  # Núcleo y configuración global
│   ├── cubit/            # Estado global de la app (tema claro/oscuro, idioma, color semilla)
│   ├── global/           # Constantes, rutas (GoRouter), inyector (GetIt), enums y estilos
│   ├── models/           # Entidades de dominio inmutables (CollarModel, AlertRecord, etc.)
│   ├── repositories/     # Contratos e implementaciones de datos (Firestore, Hive, Mocks)
│   ├── services/         # Servicios de infraestructura (Crashlytics, Performance, Analytics, Storage)
│   └── view/             # Vistas de entrada de la app (AppPage, AppView)
├── collars/              # Módulo de emparejamiento y configuración de collares
├── history/              # Módulo de rutas históricas y migajas de pan (breadcrumbs)
├── home/                 # Dashboard principal (vista de mapa, panel de telemetría y geocerca)
├── l10n/                 # Plantillas de localización (.arb) y clases generadas
├── notifications/        # Módulo de historial de alertas y notificaciones push
├── settings/             # Módulo de personalización visual, temas y ajustes de usuario
├── bootstrap.dart        # Inicialización de observadores BLoC y captura global de excepciones
├── firebase_options.dart # Configuración auto-generada de Firebase por plataforma
└── main.dart             # Punto de entrada principal de la aplicación móvil
```

### Architecture Decision Records (ADRs)

Las decisiones arquitectónicas clave, alternativas consideradas y justificaciones técnicas para la aplicación móvil y el ecosistema completo se encuentran documentadas en el [README.md principal](../README.md#-architecture-decision-records-adrs):

- [**ADR-005: Arquitectura Móvil Feature-First con BLoC/Cubit y Service Locator (GetIt) en Flutter**](../README.md#adr-005-arquitectura-feature-first-con-bloccubit-y-getit-en-flutter) — Explica la separación de capas, el flujo unidireccional y la inyección con `GetIt` / `ServiceFactory`.
- [**ADR-004: Modelo Híbrido de Persistencia en Cloud Firestore con TTL de 15 Días**](../README.md#adr-004-modelo-híbrido-de-persistencia-en-firestore-con-ttl-de-15-días) — Detalla la estrategia reactiva en tiempo real con Firestore y la persistencia local fuera de línea con Hive.
- [**ADR-006: Geodesia WGS-84 en Servidor y Notificaciones Push Multilingües con FCM**](../README.md#adr-006-geodesia-wgs-84-en-servidor-y-notificaciones-push-multilingües-con-fcm) — Justifica el uso de `google_maps_flutter`, renderizado dinámico de marcadores y cálculo submétrico en backend.
- [**ADR-001: Radioenlace LoRa P2P vs. Red LoRaWAN Centralizada**](../README.md#adr-001-radioenlace-lora-p2p-vs-red-lorawan) — Fundamenta la selección del enlace de radiofrecuencia directo para la localización felina.

---

## 🧪 Pruebas y Calidad de Código

El proyecto mantiene altos estándares de calidad mediante herramientas automatizadas:

1. **Análisis Estático**:
   Aplica las reglas de [`very_good_analysis`](https://pub.dev/packages/very_good_analysis) y [`bloc_lint`](https://pub.dev/packages/bloc_lint):
   ```bash
   flutter analyze
   ```

2. **Pruebas Unitarias y de Widgets**:
   Construidas con `mocktail` y `bloc_test`:
   ```bash
   flutter test
   ```

3. **Reporte de Cobertura de Código**:
   Generación del informe de cobertura LCOV:
   ```bash
   flutter test --coverage
   genhtml coverage/lcov.info -o coverage/html
   open coverage/html/index.html
   ```

---

## 🤝 Contribución y Flujo de Trabajo

1. Crear una rama descriptiva (`feature/nombre-funcionalidad` o `fix/descripcion-arreglo`).
2. Respetar las convenciones de código y asegurar que `flutter analyze` finalice sin errores ni advertencias.
3. Escribir pruebas unitarias y de widgets para cualquier lógica agregada en `test/`.
4. Si se introduce una decisión arquitectónica mayor, documentarla mediante un nuevo ADR siguiendo el formato establecido.
5. Crear un Pull Request detallando los cambios y criterios de aceptación.

---

## 📄 Licencia

Este proyecto está bajo la licencia [MIT](LICENSE).
