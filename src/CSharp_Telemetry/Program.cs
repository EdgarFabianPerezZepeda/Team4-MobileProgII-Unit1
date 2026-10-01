// System aporta tipos generales como Console y ArgumentOutOfRangeException.
using System;
// Tasks aporta Task y Parallel para ejecutar y coordinar trabajo concurrente.
using System.Threading.Tasks;

// Agrupa los tipos relacionados con el motor de telemetría.
namespace Team4.TelemetryEngine
{
    // Guarda contadores independientes para una ejecución del motor reentrante.
    // No es seguro compartir la misma instancia entre hilos sin sincronización.
    public struct ExecutionContext
    {
        // Niveles recursivos que siguen activos en este momento.
        public int CurrentDepth { get; set; }
        // Mayor profundidad alcanzada durante esta ejecución.
        public int PeakDepth { get; set; }
        // Número de invocaciones recursivas iniciadas.
        public long TotalInvocations { get; set; }

        // Inicializa todos los contadores en cero al crear el contexto.
        public ExecutionContext()
        {
            CurrentDepth = 0;
            PeakDepth = 0;
            TotalInvocations = 0;
        }
    }

    // Esta implementación ilustra el riesgo de compartir telemetría estática.
    public static class UnsafeTelemetryEngine
    {
        // Estos campos pertenecen a la clase y, por ello, son compartidos por todos los hilos.
        private static int s_currentDepth = 0;
        private static int s_peakDepth = 0;
        private static long s_totalInvocations = 0;

        // Calcula n! recursivamente, registrando métricas en campos compartidos no sincronizados.
        public static long ComputeFactorialUnsafe(int n)
        {
            // ++ no es una operación atómica: dos hilos pueden perder actualizaciones.
            s_totalInvocations++;
            // La profundidad de varias recursiones concurrentes se mezcla en este contador.
            s_currentDepth++;
            // Conserva la mayor profundidad observada, que puede ser incorrecta por la carrera.
            if (s_currentDepth > s_peakDepth)
            {
                s_peakDepth = s_currentDepth;
            }

            // finally garantiza reducir la profundidad incluso al retornar o ante una excepción.
            try
            {
                // Caso base: factorial de cero y uno. Este método no rechaza n negativos.
                if (n <= 1) return 1;
                // Definición recursiva: n! = n * (n - 1)!.
                return n * ComputeFactorialUnsafe(n - 1);
            }
            finally
            {
                // Deshace el incremento al salir de este nivel recursivo.
                s_currentDepth--;
            }
        }

        // Devuelve una instantánea de los tres contadores compartidos.
        public static (int CurrentDepth, int PeakDepth, long TotalInvocations) GetState()
        {
            return (s_currentDepth, s_peakDepth, s_totalInvocations);
        }

        // Limpia las métricas antes de iniciar la demostración.
        public static void Reset()
        {
            s_currentDepth = 0;
            s_peakDepth = 0;
            s_totalInvocations = 0;
        }
    }

    // Usa un contexto recibido como argumento en vez de mantener telemetría estática.
    public static class ReentrantTelemetryEngine
    {
        // ref permite que esta llamada y toda su recursión muten el contexto del llamador.
        public static long ComputeFactorialReentrant(int n, ref ExecutionContext ctx)
        {
            // Cuenta la invocación actual en el contexto de esta operación.
            ctx.TotalInvocations++;
            // Registra la entrada a un nivel recursivo.
            ctx.CurrentDepth++;
            // Comprueba si este nivel supera el máximo anterior.
            if (ctx.CurrentDepth > ctx.PeakDepth)
            {
                ctx.PeakDepth = ctx.CurrentDepth;
            }

            // El finally restaura la profundidad tanto en el retorno normal como en un error.
            try
            {
                // A diferencia de la versión insegura, rechaza valores negativos explícitamente.
                if (n < 0)
                    throw new ArgumentOutOfRangeException(nameof(n), "El valor no puede ser negativo.");

                // Casos base: 0! y 1! valen 1.
                if (n <= 1) return 1;

                // Calcula n! y pasa el mismo contexto por referencia al siguiente nivel.
                return n * ComputeFactorialReentrant(n - 1, ref ctx);
            }
            finally
            {
                // Deja el contador en el nivel previo, incluso si se lanzó una excepción.
                ctx.CurrentDepth--;
            }
        }
    }

    // Contiene el punto de entrada y las dos demostraciones que se ejecutan al iniciar el programa.
    internal class Program
    {
        // Main es el punto de entrada de la aplicación; args no se utiliza en este ejemplo.
        private static void Main(string[] args)
        {
            Console.WriteLine("=== DEMOSTRACIÓN PROBLEMA 4.1 (C#) ===");

            Console.WriteLine("\n--- Test 1: Inseguridad por Variables Estáticas Locales ---");
            // Inicia la prueba con los contadores compartidos en cero.
            UnsafeTelemetryEngine.Reset();

            // Programa dos factoriales de 5 en tareas que pueden solaparse.
            Task task1 = Task.Run(() => UnsafeTelemetryEngine.ComputeFactorialUnsafe(5));
            Task task2 = Task.Run(() => UnsafeTelemetryEngine.ComputeFactorialUnsafe(5));
            // Espera a las dos tareas antes de leer las métricas.
            Task.WaitAll(task1, task2);

            // Descompone la tupla de métricas en variables locales con nombres descriptivos.
            var (unsafeCurrent, unsafePeak, unsafeTotal) = UnsafeTelemetryEngine.GetState();
            // Muestra la profundidad restante; normalmente vuelve a cero al terminar las llamadas.
            Console.WriteLine($"[Inseguro] Dynamic Depth Residue: {unsafeCurrent}");
            // El valor depende del intercalado y no necesariamente evidencia una carrera en cada ejecución.
            Console.WriteLine($"[Inseguro] Peak Stack Depth (Corrupto por Race Condition): {unsafePeak}");
            // Dos factoriales de 5 deberían sumar 10 invocaciones, aunque el contador compartido puede perder incrementos.
            Console.WriteLine($"[Inseguro] Total Invocaciones: {unsafeTotal}");

            Console.WriteLine("\n--- Test 2: Contexto Explícito y Motor Reentrante ---");
            
            // Crea estados independientes para evitar que las dos operaciones compartan sus contadores.
            ExecutionContext ctxA = new ExecutionContext();
            ExecutionContext ctxB = new ExecutionContext();

            // Variables donde se guardarán los resultados de los factoriales.
            long resA = 0, resB = 0;

            // Ejecuta ambos cálculos en paralelo; cada lambda modifica solo su propio contexto.
            Parallel.Invoke(
                () => resA = ReentrantTelemetryEngine.ComputeFactorialReentrant(5, ref ctxA),
                () => resB = ReentrantTelemetryEngine.ComputeFactorialReentrant(10, ref ctxB)
            );

            // Muestra resultado, máximo, número de llamadas y profundidad final del primer cálculo.
            Console.WriteLine($"[Thread A] Fact(5) = {resA} | Peak Depth: {ctxA.PeakDepth} | Invocaciones: {ctxA.TotalInvocations} | Depth Final: {ctxA.CurrentDepth}");
            // Muestra los mismos datos del segundo cálculo. Thread A/B son etiquetas, no IDs reales de hilo.
            Console.WriteLine($"[Thread B] Fact(10) = {resB} | Peak Depth: {ctxB.PeakDepth} | Invocaciones: {ctxB.TotalInvocations} | Depth Final: {ctxB.CurrentDepth}");
        }
    }
}

// Conclusión: la versión estática comparte métricas y puede sufrir carreras; la versión reentrante
// aísla las métricas por operación. Los resultados demostrados son 5! = 120 y 10! = 3628800.
// El tipo long tiene rango finito, por lo que factoriales mayores que 20! no se representan correctamente.