# Mi inventario

Aplicación móvil desarrollada con Flutter y Dart para organizar artículos y llevar un registro de su stock. Los datos se guardan localmente con SQLite.

## Funciones

- Crear y editar artículos con nombre, descripción, foto y código de identificación.
- Buscar artículos y encontrarlos escaneando códigos de barras o QR.
- Registrar entradas, salidas y ajustes de cantidad, con notas e historial.
- Filtrar por artículos sin stock, stock bajo o un rango de cantidades.
- Archivar y restaurar artículos.
- Consultar un resumen semanal de movimientos.
- Personalizar el nombre del inventario, el color principal y el tema claro u oscuro.

## Tecnologías

Flutter, Dart, SQLite (`sqflite`), `ChangeNotifier` para el estado, `image_picker` para las fotos y `mobile_scanner` para el escaneo.

## Ejecutar el proyecto

Se necesita Flutter con una versión de Dart compatible con `^3.13.7`, el SDK de Android y un dispositivo o emulador Android.

Desde la carpeta del proyecto:

```bash
flutter pub get
flutter run
```

La cámara se utiliza para sacar fotos y escanear códigos; estas funciones requieren permiso del dispositivo.

## Verificaciones

```bash
flutter analyze
flutter test
```

Los tests cubren reglas de stock, operaciones del estado y algunos comportamientos de las pantallas. Las pruebas con una base de datos simulada no reemplazan las pruebas de persistencia real en SQLite.

## Estructura

- `lib/data/`: base de datos y almacenamiento de fotos.
- `lib/models/`: artículos, movimientos y ajustes.
- `lib/state/`: estado y operaciones del inventario.
- `lib/screens/`: pantallas y componentes específicos de cada pantalla.
- `lib/widgets/`: componentes de interfaz compartidos.
- `lib/utils/`: utilidades de fechas y texto.
- `test/`: pruebas automatizadas.

## Estado actual

No requiere una cuenta y no implementa sincronización entre dispositivos ni exportación de copias de seguridad. No conviene depender de esta versión como única copia de un inventario importante.
