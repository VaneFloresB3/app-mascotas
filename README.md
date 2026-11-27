# KoinuCare

Aplicación Android para registrar mascotas y dar seguimiento a su día a día y a su salud: registros diarios, vacunas, citas veterinarias, medicinas, peso, celo con calendario y avisos.

Todos los datos se guardan en el teléfono (SQLite). La app no usa Firebase ni envía información a servidores.

## Funciones

### Mascotas
- Registro de perros y gatos con nombre, especie, raza, sexo, fecha de nacimiento y esterilización.
- Foto opcional por mascota. Se copia a una carpeta privada de la app, se gira según su orientación, se reduce a 512 px y se guarda como JPG.
- Mascotas fallecidas: se marcan con la fecha de fallecimiento. Salen de la portada, dejan de generar avisos y aparecen en la sección **Recuerdos**.

### Portada
- Fichas de las mascotas activas.
- Sección **Hoy**: recordatorios de hoy y mañana (vacunas, citas, medicinas y celos estimados). Cada fila abre el registro exacto. Se actualiza al volver a la app y a medianoche, y funciona aunque no se hayan dado permisos de notificación.

### Ficha de cada mascota
Navegación inferior con cuatro secciones:
- **Inicio:** foto, edad, último peso y datos generales. Botón para editar.
- **Celo:** solo para hembras no esterilizadas (ver más abajo).
- **Carnet médico:** registros de salud con foto de la etiqueta (opcional), y la sección de peso con gráfica.
- **Diario:** orinal, comidas, agua, paseos, juego, baño y cepillado.

### Carnet médico
- Tipos: vacuna, desparasitante, medicina, cita veterinaria y síntoma.
- Próxima fecha con recordatorio el día anterior.
- Foto de la etiqueta de la vacuna o medicina, guardada a 1280 px para que se pueda leer el texto. Se ve una miniatura en la lista y al tocarla se abre completa.

### Celo (solo hembras no esterilizadas)
- Registro de inicio y fin, intensidad, color de flujo y contacto con machos.
- Calendario mensual con sangrado, ventana fértil estimada (en perras), próximo celo estimado y ventana de seguridad.
- Estimación adaptativa: el punto de partida depende del tamaño (según el último peso). Con dos o más celos registrados se usa el promedio de los intervalos reales.
- Etapas aproximadas en perras: proestro, estro y diestro, con un consejo para cada etapa.
- Aviso preventivo 14 días antes del celo estimado y aviso el día estimado.
- Aviso: las fechas son estimaciones y no son un método anticonceptivo.

### Peso
- Registro con fecha y gráfica de evolución.

### Ajustes
- Hora de los recordatorios diarios.
- Borrar todos los datos.

## Stack
- Flutter (Dart 3.5+), Android
- Riverpod para el estado
- drift (SQLite) para los datos locales
- flutter_local_notifications y timezone para los avisos
- table_calendar y fl_chart para calendario y gráficas
- image_picker e image para las fotos
- flutter_launcher_icons para el ícono

## Estructura principal
- `lib/data/`: base de datos, conexión, almacenamiento de fotos, pesos y ajustes.
- `lib/domain/`: lógica pura (predicción de celo, etapas, recordatorios, agenda) con pruebas.
- `lib/features/`: pantallas por módulo (pets, agenda, celo, eventos, peso).
- `lib/notifications/`: programación de avisos.
- `test/`: pruebas unitarias de la lógica de dominio.

## Compilar y descargar el APK
El APK se genera con GitHub Actions (`.github/workflows/build-apk.yml`) cada vez que se hace push a `flutter-base`, y también se puede lanzar a mano desde la pestaña Actions.

Cada compilación:
1. Pone el nombre y el identificador de la app (`com.koinucare.app`).
2. Genera el ícono a partir de `assets/icon/koinucare.png`.
3. Ejecuta las pruebas. Si fallan, no se publica el APK.
4. Firma el APK con una llave de release fija.
5. Publica `KoinuCare.apk` en **Releases**.

### Firma de release
La firma es siempre la misma, así que una versión nueva se instala encima de la anterior sin borrar datos. Para que funcione, el repositorio necesita estos secretos:
- `KEYSTORE_BASE64`: la llave `koinucare-release.jks` en base64.
- `KEYSTORE_PASSWORD`, `KEY_PASSWORD` y `KEY_ALIAS`.

**Guarda la llave y sus claves en un lugar seguro.** Si se pierden, no se podrán publicar actualizaciones que se instalen sobre la app actual. Nunca subas el archivo `.jks` ni las contraseñas al repositorio.

Hasta que la app se firmó con esta llave por primera vez, hay que desinstalar la versión anterior una sola vez.

## Desarrollo local
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter run
```
`database.g.dart` se genera con build_runner y no se guarda en el repositorio.

## Ramas
- `flutter-base`: desarrollo.
- `main`: versión estable. Se mezcla desde `flutter-base` cuando las pruebas pasan.

## Documentación
- [Módulo de celo](docs/modulo-celo.md)

## Historial de cambios

### Versión actual (flutter-base)
- Nombre KoinuCare, ícono propio y APK publicado en Releases.
- Firma de release fija para actualizar sin desinstalar.
- Foto por mascota, copiada y reducida de forma privada.
- Sección Hoy en la portada.
- Mascotas fallecidas y sección Recuerdos.
- Predicción de celo adaptativa con ventana de seguridad.
- Etapas aproximadas del celo en perras.
- Navegación inferior por mascota: Inicio, Celo, Carnet médico y Diario.
- Fotos de etiquetas en el carnet médico.
- Edad y último peso en Inicio.
- Corrección del arranque de la app, que quedaba bloqueada en el ícono al abrir.

### Primera versión
- Registros diarios, salud, peso, celo con calendario y avisos.
- Pantalla de ajustes con hora de recordatorios y borrado de datos.
