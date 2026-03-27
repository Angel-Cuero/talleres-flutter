# taller1

# 📱 Taller 1 - Flutter StatefulWidget y setState()

## 📌 Descripción
Este taller tiene como objetivo construir una aplicación básica en Flutter utilizando un **StatefulWidget**, evidenciando el uso de **setState()** para actualizar dinámicamente la interfaz de usuario.

Se desarrolla una pantalla principal que incluye un AppBar dinámico, imágenes, botones interactivos y widgets adicionales, aplicando buenas prácticas de diseño y organización.

---

## 🚀 Funcionalidades implementadas

- AppBar con título dinámico:
  - “Hola, Flutter”
  - “¡Título cambiado!”

- Texto centrado con el nombre completo del estudiante

- Imágenes en un Row:
  - Imagen desde internet (`Image.network`)
  - Imagen local (`Image.asset`)

- Botón con `setState()`:
  - Cambia el título del AppBar
  - Muestra un SnackBar con el mensaje: **“Título actualizado”**

- Widgets adicionales:
  - `Container` con estilos (bordes, márgenes, color)
  - `ListView` con lista de elementos (ícono + texto)

- Organización visual usando:
  - `Column`
  - `Padding`
  - `SizedBox`

---

## 🛠️ Estructura de ramas (GitFlow)

Este proyecto usa un único repositorio con la siguiente estructura de ramas:

- `main` → rama estable
- `dev` → rama de desarrollo
- `feature/taller1` → desarrollo del taller

Flujo de trabajo:
feature/taller1 → Pull Request → dev → merge → main

---

## ▶️ Cómo ejecutar el proyecto

1. Clonar el repositorio:

bash
git clone https://github.com/tu-usuario/tu-repositorio.git

2. Entrar al directorio del proyecto:

Bash
cd talleres-flutter

3.Instalar las dependencias de Flutter:

Bash
flutter pub get

4.Ejecutar la aplicación:

Bash
flutter run
