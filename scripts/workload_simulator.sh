#!/bin/bash

# 1. Definim els paranys (traps) per als senyals
trap 'echo -e "\n[SIGINT] Has fet Ctrl+C! Aturant procés de forma segura..."; kill $WORKER_PID 2>/dev/null; exit 0' SIGINT
trap 'echo -e "\n[SIGTERM] El sistema demana tancar (kill). Netejant..."; kill $WORKER_PID 2>/dev/null; exit 0' SIGTERM
trap 'echo -e "\n[SIGHUP] Terminal tancada o servei reiniciat. Recarregant configuració simulada..."' SIGHUP
trap 'echo -e "\n[SIGUSR1] ESTAT: Estic viu! PID: $$"' SIGUSR1
trap 'echo -e "\n[SIGUSR2] ESTAT: Estic viu! PID: $$"' SIGUSR2

echo "=== SIMULADOR DE CÀRREGA I SENYALS ==="
echo "El PID principal és: $$"
echo "Obre una altra terminal i prova aquestes comandes:"
echo "  1. kill -SIGHUP $$"
echo "  2. kill -SIGUSR1 $$"
echo "  3. kill -SIGUSR2 $$"
echo "  4. kill -SIGTERM $$"
echo "  5. killall workload_simulator.sh"
echo "  [PRIORITAT] renice -n 10 $$ (Fa que consumeixi menys CPU)"
echo "  [PAUSAR]    kill -SIGSTOP $$ (Congela el procés)"
echo "  [REPRENDRE] kill -SIGCONT $$ (Descongela el procés)"
echo "---------------------------------------"

# 2. Generem càrrega real a la CPU
echo "Iniciant procés pesat ('yes') en segon pla..."
yes > /dev/null &
WORKER_PID=$!

# 3. Bucle infinit d'espera
while true; do
    sleep 2
done
