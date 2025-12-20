#!/bin/bash

# Uso:
# ./run_batch_specific.sh [--app=APP] [--args=ARGS]

SIMULATOR_SCRIPT="./ci/blackbox.sh "

# Valores default
APP="nearn"
ARGS=""

# Lista de políticas
POLICY_LIST=(0 5 6)

declare -A COMBINATIONS
COMBINATIONS[0]="cores=2,warps=4,threads=8"
COMBINATIONS[1]="cores=4,warps=8,threads=16"
COMBINATIONS[2]="cores=8,warps=16,threads=32"

# Parsing dos argumentos
for ARG in "$@"; do
    case $ARG in
        --app=*) APP="${ARG#*=}" ;;
        --args=*) ARGS="${ARG#*=}" ;;
        *) echo "Parâmetro inválido: $ARG" && exit 1 ;;
    esac
done

# Criar diretório de resultados
RESULTS_DIR="results/${APP}"
mkdir -p "$RESULTS_DIR"

# Loop de combinações específicas
for POLICY in "${POLICY_LIST[@]}"; do
    for i in {0..2}; do
        # Obtém e separa a combinação em variáveis
        IFS=',' read -r -a PARAMS <<< "${COMBINATIONS[$i]}"
        
        CORES=$(echo "${PARAMS[0]}" | cut -d'=' -f2)
        WARPS=$(echo "${PARAMS[1]}" | cut -d'=' -f2)
        THREADS=$(echo "${PARAMS[2]}" | cut -d'=' -f2)

        # Nome do arquivo de log
        SAFE_ARGS=${ARGS:-"default"}
        RESULTS_FILE="${RESULTS_DIR}/results_cores${CORES}_warps${WARPS}_threads${THREADS}_policy${POLICY}_args${SAFE_ARGS}.txt"
        LOG_FILE="${RESULTS_DIR}/log_cores${CORES}_warps${WARPS}_threads${THREADS}_policy${POLICY}_args${SAFE_ARGS}.txt"

        echo "Rodando: app=$APP, cores=$CORES, warps=$WARPS, threads=$THREADS, policy=$POLICY, args=$SAFE_ARGS"

        # Executa e filtra a saída
        if [ -n "$ARGS" ]; then
            ./ci/blackbox.sh --perf=1 --debug=1 --app="$APP" --args="$ARGS" --cores="$CORES" --warps="$WARPS" --threads="$THREADS" --policy="$POLICY" --log="$LOG_FILE" > "$LOG_FILE" 2>&1
        else
            ./ci/blackbox.sh --perf=1 --debug=1 --app="$APP" --cores="$CORES" --warps="$WARPS" --threads="$THREADS" --policy="$POLICY" --log="$LOG_FILE" > "$LOG_FILE" 2>&1
        fi

        cat $LOG_FILE | grep '^PERF' > "$RESULTS_FILE"

        if [ $? -eq 0 ]; then
            echo "Finalizado com sucesso. Resultados: $RESULTS_FILE"
            rm "$LOG_FILE"
        else
            echo "Erro ao executar. Verifique: $LOG_FILE"
        fi
        echo
    done
done
