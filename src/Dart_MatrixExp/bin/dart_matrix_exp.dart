// Importa la implementación bajo un alias para que el wrapper tenga un main mínimo.
import 'main.dart' as app;

// dart run busca por convención bin/dart_matrix_exp.dart según el nombre del paquete.
// Esta función delega la ejecución en el main que contiene la demostración real.
void main() => app.main();