# TA-ui (Tesis) — Frontend en Flutter

Frontend en Flutter del proyecto de tesis. Permite la interacción del usuario con la aplicación (interfaz, cámara y audio) y consume la API REST expuesta por el backend Flask.

> El backend se encuentra en un repositorio separado: **TA-backend**.

---

## Tecnologías
- Flutter (canal estable)
- Dart
- Firebase (Auth / Firestore) según configuración del proyecto
- Cámara y audio (según plataforma)

---

## Requisitos
- Flutter instalado (Dart 3.9+)
- Git
- Dispositivo o plataforma de ejecución:
  - Web: Google Chrome
  - Android: Emulador o dispositivo físico con depuración USB habilitada

---

## Instalación y ejecución

### Clonar el repositorio
git clone <URL_DEL_REPOSITORIO>
cd <CARPETA_DEL_REPOSITORIO>

Si el proyecto se encuentra dentro del directorio `ta_ui_new`, ingresar:
cd ta_ui_new

### Instalar dependencias
flutter pub get
flutter devices

### Ejecutar la aplicación apuntando al backend

Web (Chrome):
flutter run -d chrome --dart-define=API_URL=http://127.0.0.1:5000

Android (Emulador):
flutter run -d <ID_DISPOSITIVO> --dart-define=API_URL=http://10.0.2.2:5000

Android (Dispositivo físico):
flutter run -d <ID_DISPOSITIVO> --dart-define=API_URL=http://<IP_DEL_BACKEND>:5000

https://www.youtube.com/watch?v=nA3JtWMoyUs

---

## Configuración del backend
La aplicación requiere que la URL del backend se defina explícitamente mediante la variable de compilación `API_URL`.  
Esta URL debe apuntar a la instancia activa del backend Flask.

---

## Firebase
El proyecto incluye el archivo `lib/firebase_options.dart` generado previamente.  
Si se utiliza un proyecto Firebase distinto, se debe regenerar la configuración con:

flutterfire configure

---

## Estructura relevante
- lib/main.dart: punto de entrada de la aplicación
- lib/ui/: pantallas y componentes de interfaz
- lib/services/: consumo de API y servicios
- lib/firebase_options.dart: configuración de Firebase
- pubspec.yaml: dependencias y configuración del SDK

---

## Problemas comunes

### La aplicación no conecta con el backend
- Verificar que el backend esté ejecutándose en el puerto 5000.
- Confirmar que `API_URL` corresponde a la plataforma usada.
- En dispositivo físico, usar la IP real de la máquina donde corre el backend.

### Errores de dependencias
flutter clean
flutter pub get

### El dispositivo no aparece
flutter doctor -v
