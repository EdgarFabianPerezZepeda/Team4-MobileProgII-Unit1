# Unit 1 Problem Set: Mobile Programming II

## Datos de la Asignación
* **Institución:** Universidad Politécnica del Estado de Nayarit (UPEN)
* **Asignatura:** Programación Móvil II
* **Profesor:** I.S.C. Luis Gerardo Aguirre Cervantes
* **Equipo:** Team 4
* **Fecha de Entrega / Presentación:** 30 de septiembre de 2026

---

## Integrantes del Equipo
* **Edgar Fabian Perez Zepeda**
* **Julio Cesar Inda Jimenez**
* **David de Jesus Gonzalez Ramirez**
* **Angel Gabriel Zuñiga Peralta**

---

## Descripción del Proyecto

Este repositorio contiene las soluciones para el **Problem Set de la Unidad 1** del Equipo 4, enfocado en **Scope de Estado** y **Recursión Logarítmica**:

1. **Problema 4.1 (C# .NET 10.0+):** *Reentrant Call-Stack Execution Telemetry Engine*
   * Demostración y contraste entre la fuga de estado en ejecuciones concurrentes al usar variables estáticas (`UnsafeTelemetryEngine`) y la recolección determinista de telemetría sin efectos secundarios mediante el paso explícito por referencia de un contexto aislado en la pila (`ReentrantTelemetryEngine` con `ref ExecutionContext`).
2. **Problema 4.2 (Dart 3.10+):** *Recursive Logarithmic Matrix Exponentiation*
   * Algoritmo de exponenciación binaria de matrices bajo el enfoque Divide y Vencerás ($\mathcal{O}(\log k)$). Calcula el $60^\circ$ número de Fibonacci ($F_{60} = 1,548,008,755,920$) utilizando `BigInt` y valida el límite teórico de profundidad del stack con `MatrixTelemetry`.

---

## Guía de Ejecución

### Prerrequisitos
* **.NET SDK 10.0** o superior instalado.
* **Dart SDK 3.10** o superior instalado.

---

### 1. Ejecutar el Proyecto en C# (Problema 4.1)

Navega a la carpeta del proyecto en C# y ejecuta la consola:

```bash
cd src/CSharp_Telemetry
dotnet run
