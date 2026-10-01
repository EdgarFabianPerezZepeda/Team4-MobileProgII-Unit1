// Importa log, usado para calcular la profundidad recursiva teórica en base 2.
import 'dart:math';

/// Representa una matriz cuadrada NxN con elementos enteros de precisión arbitraria.
/// Los campos son final, pero las listas expuestas en data todavía pueden modificarse.
class SquareMatrix {
  // Número de filas y columnas de la matriz.
  final int size;
  // Filas de la matriz. BigInt evita desbordamientos en los cálculos de este ejemplo.
  final List<List<BigInt>> data;

  // Guarda la dimensión y los datos recibidos y valida que formen una matriz cuadrada.
  SquareMatrix(this.size, this.data) {
    // Falla si la cantidad de filas o el tamaño de cualquier fila no coincide con size.
    if (data.length != size || data.any((row) => row.length != size)) {
      throw ArgumentError('Las dimensiones de la matriz deben coincidir con size x size.');
    }
  }

  /// Crea la matriz identidad de dimensión [size], con unos en la diagonal y ceros fuera.
  factory SquareMatrix.identity(int size) {
    // Genera una lista de filas; cada fila se genera independientemente.
    List<List<BigInt>> grid = List.generate(
      size,
      // Genera size elementos: uno si el índice de fila y columna coincide, cero si no.
      (i) => List.generate(size, (j) => i == j ? BigInt.one : BigInt.zero),
    );
    // Construye el objeto y reutiliza la validación del constructor principal.
    return SquareMatrix(size, grid);
  }

  /// Devuelve el producto de esta matriz por [other], sin alterar las matrices de entrada.
  SquareMatrix multiply(SquareMatrix other) {
    // El producto implementado requiere matrices cuadradas de la misma dimensión.
    if (this.size != other.size) {
      throw ArgumentError('Las matrices deben tener las mismas dimensiones.');
    }
    // Guarda la dimensión para controlar los tres ciclos del producto matricial.
    int n = this.size;
    // Reserva una matriz de resultado n x n e inicializa cada celda en cero.
    List<List<BigInt>> result = List.generate(
      n,
      (_) => List.filled(n, BigInt.zero),
    );

    // i selecciona la fila del resultado.
    for (int i = 0; i < n; i++) {
      // k recorre los elementos compartidos entre la fila de A y la columna de B.
      for (int k = 0; k < n; k++) {
        // j selecciona la columna del resultado.
        for (int j = 0; j < n; j++) {
          // Acumula A[i][k] * B[k][j] en la celda C[i][j].
          result[i][j] += this.data[i][k] * other.data[k][j];
        }
      }
    }
    // Devuelve una nueva matriz que contiene el producto.
    return SquareMatrix(n, result);
  }

  // Indica que esta clase personaliza la conversión heredada a texto.
  @override
  // Formatea cada fila con tabuladores entre columnas y saltos de línea entre filas.
  String toString() {
    return data.map((row) => row.map((e) => e.toString()).join('\t')).join('\n');
  }
}

/// Cuenta las llamadas recursivas activas y la profundidad máxima observada.
class MatrixTelemetry {
  // Profundidad actual: sube al entrar y baja al salir de una llamada.
  int currentDepth = 0;
  // Récord de profundidad alcanzada durante el cálculo.
  int peakDepth = 0;

  // Registra la entrada a una invocación de la potencia recursiva.
  void trackEnter() {
    // Añade el nivel actual de recursión.
    currentDepth++;
    // Actualiza el máximo solo si la profundidad acaba de superar el récord.
    if (currentDepth > peakDepth) {
      peakDepth = currentDepth;
    }
  }

  // Registra la salida de una invocación recursiva.
  void trackExit() {
    // Restaura la profundidad al nivel que contenía la llamada anterior.
    currentDepth--;
  }
}

/// Calcula M^k por exponenciación al cuadrado, con O(log k) niveles de recursión.
SquareMatrix matrixPowerRecursive(
  // Matriz base que se elevará a la potencia.
  SquareMatrix M,
  // Exponente entero no negativo.
  int k,
  // Objeto donde se registran las profundidades de esta operación.
  MatrixTelemetry telemetry,
) {
  // Cuenta también la invocación actual, incluidos los casos base.
  telemetry.trackEnter();

  // El finally garantiza equilibrar trackEnter aunque haya retorno o excepción.
  try {
    // Las potencias negativas no son compatibles con esta operación de matrices.
    if (k < 0) {
      throw ArgumentError('El exponente k debe ser no negativo.');
    }

    // Caso base: toda matriz elevada a cero devuelve la identidad del mismo tamaño.
    if (k == 0) {
      return SquareMatrix.identity(M.size);
    }
    // Caso base: elevar a uno devuelve la matriz original.
    if (k == 1) {
      return M;
    }

    // Para exponente par, calcula M^(k/2) y eleva el resultado intermedio al cuadrado.
    if (k % 2 == 0) {
      SquareMatrix halfPower = matrixPowerRecursive(M, k ~/ 2, telemetry);
      return halfPower.multiply(halfPower);
    } else {
      // Para exponente impar, obtiene primero M^floor(k/2).
      SquareMatrix halfPower = matrixPowerRecursive(M, (k - 1) ~/ 2, telemetry);
      // El cuadrado intermedio equivale a M^(k-1).
      SquareMatrix halfPowerSquared = halfPower.multiply(halfPower);
      // Multiplica una vez más por M para obtener M^k.
      return M.multiply(halfPowerSquared);
    }
  } finally {
    // Reduce la profundidad en cualquier ruta de salida, incluso si k era inválido.
    telemetry.trackExit();
  }
}

// Punto de entrada de la demostración de exponenciación de matrices.
void main() {
  // Identifica el ejercicio que se ejecuta.
  print('=== DEMOSTRACIÓN PROBLEMA 4.2 (DART) ===\n');

  // Matriz Fibonacci: sus potencias contienen términos consecutivos de la sucesión.
  final SquareMatrix F = SquareMatrix(2, [
    [BigInt.one, BigInt.one],
    [BigInt.one, BigInt.zero],
  ]);

  // Exponente que se utilizará para calcular F^60.
  const int exponent = 60;
  // Contenedor de métricas de la recursión de esta ejecución.
  final telemetry = MatrixTelemetry();

  // Presenta la matriz base y el exponente del cálculo.
  print('Matriz Base F:');
  print(F);
  print('\nCalculando F^$exponent...');

  // Calcula la potencia mediante el algoritmo recursivo anterior.
  final SquareMatrix resultMatrix = matrixPowerRecursive(F, exponent, telemetry);
  // En esta matriz, la celda [0][1] contiene el término F_60 de Fibonacci.
  final BigInt fibonacci60 = resultMatrix.data[0][1];

  // Imprime la matriz resultante, el término de Fibonacci y la telemetría.
  print('\n--- RESULTADOS Y TELEMETRÍA ---');
  print('Matriz Resultante F^60:');
  print(resultMatrix);
  print('\nResultado F_60 = (F^60)[0][1]: $fibonacci60');
  print('Profundidad Máxima de la Pila (Peak Recursion Depth): ${telemetry.peakDepth}');
  // Para k >= 1, la profundidad de este algoritmo es floor(log2(k)) + 1.
  print('Profundidad Recursiva Esperada floor(log2(60)) + 1: ${(log(exponent) / log(2)).floor() + 1}');
}

// Conclusión: F^60 = [[F_61, F_60], [F_60, F_59]]. El elemento [0][1] es
// F_60 = 1548008755920; la exponenciación al cuadrado lo calcula en 6 niveles recursivos.