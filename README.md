# Proyecto Flutter - Electiva Profesional I

**Estudiante:** John Stiven Gonzalez Rivera
**Código:** 230232038
**Asignatura:** Electiva Profesional I

Este repositorio contiene el desarrollo de los talleres de la asignatura,
organizados mediante un flujo de ramas tipo GitFlow:

- `main`: rama estable.
- `dev`: rama de desarrollo.
- `feature/taller1`: Taller 1 - Pantalla básica con StatefulWidget y setState().
- `feature/taller_segundo_plano`: Taller 3 - Asincronía con Future, Timer e Isolate.

---

## Taller 1 - StatefulWidget y setState()

**Rama:** `feature/taller1`

### Descripción

Pantalla básica (`HomePage`) construida con un `StatefulWidget`, que
evidencia el uso de `setState()` para actualizar la interfaz de forma
dinámica. Incluye:

- Un `AppBar` cuyo título cambia entre "Hola, Flutter" y "¡Título
  cambiado!" al presionar un botón, usando `setState()`.
- Un `SnackBar` que se muestra al presionar el botón, con el mensaje
  "Título actualizado".
- Un `Text` centrado con el nombre completo del estudiante.
- Un `Row` con dos imágenes: una cargada con `Image.network()` y otra con
  `Image.asset()`.
- Dos widgets adicionales: un `Stack` (texto superpuesto sobre una imagen)
  y un `ListView` (lista de 4 elementos con ícono y texto).

### Capturas

Ver carpeta `docs/` (estado inicial, título cambiado + SnackBar y widgets
adicionales).

### Explicación de StatefulWidget y setState()

`HomePage` extiende de `StatefulWidget` porque necesita mantener un estado
interno (el texto del título del `AppBar`) que puede cambiar durante el
ciclo de vida del widget. La clase asociada `_HomePageState` almacena la
variable `_appBarTitle`. Cuando el usuario presiona el botón, se llama a
`setState()` para modificar dicha variable, lo que le indica a Flutter que
debe reconstruir la interfaz para reflejar el nuevo valor. Sin
`setState()`, el cambio no se vería reflejado visualmente en pantalla.

---

## Taller 3 - Asincronía: Future, Timer e Isolate

**Rama:** `feature/taller_segundo_plano`

### Descripción

Aplicación que demuestra tres mecanismos de asincronía y trabajo en
segundo plano, evitando bloquear el hilo principal (UI thread):

1. **Future / async / await**: un servicio simulado que "consulta" datos
   usando `Future.delayed` (3 segundos), mostrando en pantalla los
   estados *Cargando...*, *Éxito* y *Error*, e imprimiendo en consola el
   orden de ejecución (antes, durante y después de la espera).
2. **Timer**: un cronómetro controlado con `Timer.periodic`, con botones
   Iniciar / Pausar / Reanudar / Reiniciar, que actualiza el tiempo cada
   100 ms y cancela el timer correctamente al pausar o salir de la vista.
3. **Isolate**: una tarea CPU-bound (suma de 1.500 millones de números)
   ejecutada en un `Isolate.spawn` independiente, comunicando el resultado
   mediante `SendPort` / `ReceivePort` y mostrándolo en la UI junto con el
   tiempo de ejecución.

### Estructura relevante

```
lib/
  main.dart   # HomePage con las 3 secciones: Future, Timer e Isolate
docs/
  taller3/    # Capturas de evidencia del Taller 3
```

### ¿Cuándo usar Future, async/await, Timer e Isolate?

**`Future`**: representa un valor que estará disponible en algún momento
futuro. Se usa para operaciones asíncronas de una sola vez que no bloquean
el hilo principal mientras se espera su resultado: peticiones HTTP,
lectura de archivos, consultas a bases de datos, acceso a APIs nativas,
etc. En este taller se simula con `Future.delayed`.

**`async` / `await`**: sintaxis que permite trabajar con `Future` de forma
secuencial y legible, como si el código fuera síncrono. Se usa siempre que
se necesite esperar el resultado de un `Future` antes de continuar, sin
congelar la interfaz mientras tanto.

**`Timer`**: se usa para ejecutar código de forma repetida o diferida en
el tiempo: cronómetros, cuentas regresivas, actualizaciones periódicas de
UI, *polling*, etc. A diferencia de un `Future`, un `Timer` puede
repetirse (`Timer.periodic`) y debe cancelarse explícitamente
(`timer.cancel()`) cuando ya no se necesita, normalmente en `dispose()`,
para evitar fugas de memoria.

**`Isolate`**: Dart corre en un solo hilo por *isolate*, por lo que todo
el código normal (incluyendo Futures y Timers) comparte el mismo hilo que
dibuja la UI. Para tareas intensivas en CPU (cálculos pesados,
procesamiento de datos grandes, etc.) que congelarían la interfaz, se usa
`Isolate.spawn` para moverlas a un hilo completamente separado,
comunicándose con el hilo principal únicamente por mensajes.

**Regla práctica:** si la espera es por I/O (red, disco, temporizador) se
usa `Future`/`async`-`await` o `Timer`; si la espera es por cómputo puro
del procesador, se usa `Isolate`.

### Pantallas y flujos

La aplicación cuenta con una única pantalla (`HomePage`) dividida en tres
secciones dentro de un `SingleChildScrollView`:

```
HomePage
 ├── Sección 1: Future / async-await
 │     [Switch: Simular error] → [Botón: Consultar datos]
 │            │
 │            ▼
 │     Estado = Cargando...
 │            │ (Future.delayed 3s)
 │            ▼
 │     ┌───────────────┬───────────────┐
 │     │   Éxito        │    Error      │
 │     │ (si switch=off)│ (si switch=on)│
 │     └───────────────┴───────────────┘
 │
 ├── Sección 2: Timer - Cronómetro
 │     [Iniciar] → Timer.periodic(100ms) corriendo
 │            │
 │     [Pausar] → timer.cancel(), tiempo congelado
 │            │
 │     [Reanudar] → vuelve a iniciar desde el tiempo actual
 │            │
 │     [Reiniciar] → cancela y pone el tiempo en 00:00.0
 │
 └── Sección 3: Isolate - Tarea pesada
       [Botón: Ejecutar tarea pesada]
              │
              ▼
       Isolate.spawn(tareaPesadaIsolate, sendPort)
              │  (suma de 1.500 millones de números,
              │   corre en paralelo; el cronómetro de la
              │   sección 2 sigue avanzando sin interrupciones)
              ▼
       receivePort recibe el resultado
              │
              ▼
       UI muestra: Resultado + Tiempo de ejecución (ms)
```

### Capturas

Ver carpeta `docs/taller3/`:
- Estados del Future (Cargando, Éxito, Error) y consola.
- Cronómetro (corriendo, pausado, reanudado, reiniciado) y consola.
- Isolate (procesando con el cronómetro avanzando en paralelo, resultado)
  y consola.

---

## Requisitos previos (ambos talleres)

- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado y
  configurado (`flutter doctor` sin errores críticos).
- Android Studio con un emulador configurado (o un dispositivo físico
  conectado).

## Pasos para ejecutar el proyecto

1. Clonar el repositorio:

   ```bash
   git clone https://github.com/johngonzalez02/moviles-flutter.git
   cd moviles-flutter
   ```

2. Instalar las dependencias:

   ```bash
   flutter pub get
   ```

3. Verificar que haya un emulador Android abierto (o un dispositivo
   conectado):

   ```bash
   flutter devices
   ```

4. Ejecutar la aplicación:

   ```bash
   flutter run
   ```

5. Para el Taller 3, mantener la terminal visible mientras se prueba la
   app: los mensajes de `print()` del Future y del Isolate se muestran
   ahí, evidenciando el orden de ejecución y la comunicación entre el
   hilo principal y el Isolate.

## Flujo de trabajo con Git

1. Repositorio único y público en GitHub.
2. Cada taller se desarrolla en su propia rama `feature/...`, creada
   desde `dev`.
3. Commits realizados en la rama del taller correspondiente.
4. Pull Request de la rama del taller → `dev`, revisado e integrado.
5. Pull Request de `dev` → `main`, revisado e integrado.