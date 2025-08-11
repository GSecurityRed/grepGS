#!/bin/bash
# GrepGS v3.3

set -o pipefail
shopt -s nullglob

# =====================================
# Cores (opcional)
# =====================================
RED=$'\033[31m'
MAGENTA=$'\033[35m'
CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
GRAY=$'\033[90m'
RESET=$'\033[0m'

# =====================================
# Banner
# =====================================
show_banner() {
    if command -v figlet &>/dev/null; then
        if command -v lolcat &>/dev/null; then
            figlet -f slant "GrepGS" | lolcat >&2
        else
            { printf "%b" "$RED"; figlet -f slant "GrepGS"; printf "%b" "$RESET"; } >&2
        fi
    else
        echo -e "${MAGENTA}===== GrepGS =====${RESET}" >&2
    fi
    echo -e "${CYAN}v3.3${RESET}\n" >&2
    echo -e "${GRAY}Use with caution. You are responsible for your actions." >&2
    echo -e "Developers assume no liability and are not responsible for any misuse or damage.${RESET}\n" >&2
}

# =====================================
# Ajuda
# =====================================
usage() {
    show_banner
    cat >&2 <<EOF
Uso: $0 [opções] arquivo-alvo [termo ...]

Opções de busca:
  --invert-match           Inverte a correspondência (grep -v)
  --stdin                  Lê termos do STDIN (um por linha)
  --terms-file ARQ         Lê termos de um arquivo (pode repetir)
  --terms-files L1,L2,...  Vários arquivos de termos separados por vírgula

Unicidade:
  --unique                 Remove duplicatas por SENHA (último campo após ':'),
                           normaliza CRLF e preserva a ordem

Exportação:
  --out CAMINHO            Salva o resultado no arquivo informado
  --format FMT             Força formato: txt | csv | json
                           (se omitido, infere pela extensão de --out:
                            .txt -> txt, .csv -> csv, .json/.ndjson -> json)

Geral:
  -h, --help               Mostra esta ajuda

Exemplos:
  $0 termo arquivo.txt
  $0 --invert-match admin arquivo.txt
  cat termos.txt | $0 --stdin arquivo.txt --unique --out resultado.csv
  $0 --terms-file a.txt --terms-file b.txt alvo.txt --out saida.json
EOF
    exit 1
}

# =====================================
# Variáveis
# =====================================
INVERT_MATCH=false
STDIN_TERMS=false
TERMS_FILES=()   # múltiplas wordlists
UNIQUE=false
TARGET_FILE=""
TERMS=()
OUT_PATH=""
OUT_FMT=""       # txt|csv|json

# =====================================
# Parse argumentos
# =====================================
while [[ $# -gt 0 ]]; do
    case "$1" in
        --invert-match) INVERT_MATCH=true; shift ;;
        --stdin)        STDIN_TERMS=true; shift ;;
        --terms-file)
            [[ -z "$2" ]] && { echo "Erro: --terms-file requer caminho." >&2; usage; }
            TERMS_FILES+=("$2"); shift 2 ;;
        --terms-files)
            [[ -z "$2" ]] && { echo "Erro: --terms-files requer lista separada por vírgulas." >&2; usage; }
            IFS=',' read -r -a _tmp <<< "$2"
            TERMS_FILES+=("${_tmp[@]}"); shift 2 ;;
        --unique)       UNIQUE=true; shift ;;
        --out)
            [[ -z "$2" ]] && { echo "Erro: --out requer caminho de arquivo." >&2; usage; }
            OUT_PATH="$2"; shift 2 ;;
        --format)
            [[ -z "$2" ]] && { echo "Erro: --format requer um valor." >&2; usage; }
            OUT_FMT="${2,,}"; shift 2 ;;
        -h|--help) usage ;;
        --) shift; TERMS+=("$@"); break ;;
        -*)
            echo "Opção desconhecida: $1" >&2; usage ;;
        *)
            if [[ -z "$TARGET_FILE" && -f "$1" ]]; then
                TARGET_FILE="$1"
            else
                TERMS+=("$1")
            fi
            shift ;;
    esac
done

# =====================================
# Validações
# =====================================
if [[ -z "$TARGET_FILE" ]]; then
    echo "Erro: arquivo-alvo não especificado ou não existe." >&2
    usage
fi

# Infere formato pelo --out se necessário
infer_fmt_from_path() {
    local p="$1"
    case "${p##*.}" in
        csv|CSV) echo "csv" ;;
        json|JSON|ndjson|NDJSON) echo "json" ;;
        *) echo "txt" ;;
    esac
}
if [[ -n "$OUT_PATH" && -z "$OUT_FMT" ]]; then
    OUT_FMT="$(infer_fmt_from_path "$OUT_PATH")"
fi
[[ -n "$OUT_FMT" ]] || OUT_FMT="txt"

# =====================================
# Banner
# =====================================
show_banner

# =====================================
# Coleta de termos
# =====================================
if $STDIN_TERMS; then
    while IFS= read -r term; do
        [[ -n "$term" ]] && TERMS+=("$term")
    done
fi

# Carrega múltiplas wordlists
TERMS_FILES_READ=0
for tf in "${TERMS_FILES[@]}"; do
    if [[ ! -f "$tf" ]]; then
        echo "Aviso: wordlist não encontrada: $tf" >&2
        continue
    fi
    while IFS= read -r term; do
        [[ -n "$term" ]] && TERMS+=("$term")
    done < "$tf"
    ((TERMS_FILES_READ++))
done

if [[ ${#TERMS[@]} -eq 0 ]]; then
    echo "Nenhum termo fornecido!" >&2
    usage
fi

# Remove termos duplicados (exatamente iguais)
# e linhas em branco, preservando ordem
TERMS=($(printf "%s\n" "${TERMS[@]}" | awk 'NF && !seen[$0]++'))

# =====================================
# Execução do grep (AND entre termos)
# =====================================
FLAGS=()
$INVERT_MATCH && FLAGS+=("-v")
GREPOPTS=(--color=never)

RESULT=""
for term in "${TERMS[@]}"; do
    if [[ -z "$RESULT" ]]; then
        RESULT=$(grep "${FLAGS[@]}" -F "${GREPOPTS[@]}" -- "$term" "$TARGET_FILE" || true)
    else
        RESULT=$(printf "%s\n" "$RESULT" | grep "${FLAGS[@]}" -F "${GREPOPTS[@]}" -- "$term" || true)
    fi
done

COUNT_BEFORE=$(printf "%s\n" "$RESULT" | sed '/^$/d' | wc -l | tr -d ' ')

# =====================================
# Unicidade por SENHA (último campo após ':')
# =====================================
if $UNIQUE; then
    RESULT=$(printf "%s\n" "$RESULT" | tr -d '\r' | \
        awk -F':' '
            {
                key = ($0 ~ /:/ ? $NF : $0)
                sub(/^[[:space:]]+/, "", key)
                sub(/[[:space:]]+$/, "", key)
                if (!seen[key]++) print
            }
        ')
fi

COUNT_AFTER=$(printf "%s\n" "$RESULT" | sed '/^$/d' | wc -l | tr -d ' ')

# =====================================
# Exportação
# =====================================
write_txt()  { printf "%s\n" "$RESULT"; }

write_csv() {
    # Divide por ":" em colunas c1..cN e gera cabeçalho com N máximo
    awk -F':' '
        BEGIN{ OFS="," }
        {
            # guarda campos por linha
            n=split($0,a,":")
            max=(n>max?n:max)
            for(i=1;i<=n;i++){ row[NR,i]=a[i] }
            rows=NR
        }
        END{
            # header
            for(i=1;i<=max;i++){
                printf "c%d", i; if(i<max) printf OFS; else printf "\n"
            }
            # linhas
            for(r=1;r<=rows;r++){
                for(i=1;i<=max;i++){
                    val=row[r,i]
                    gsub(/\r/,"",val)
                    gsub(/"/,"\"\"",val)
                    printf "\"%s\"", val
                    if(i<max) printf OFS; else printf "\n"
                }
            }
        }' <<< "$RESULT"
}

write_json() {
    # NDJSON: {"c1":"...","c2":"...","raw":"..."}
    awk -F':' '
        function esc(s){ gsub(/\\/,"\\\\",s); gsub(/"/,"\\\"",s); gsub(/\r/,"",s); return s }
        {
            n=split($0,a,":")
            printf "{"
            for(i=1;i<=n;i++){
                printf "\"c%d\":\"%s\",", i, esc(a[i])
            }
            printf "\"raw\":\"%s\"", esc($0)
            printf "}\n"
        }' <<< "$RESULT"
}

# Decide onde escrever
if [[ -n "$OUT_PATH" ]]; then
    case "$OUT_FMT" in
        txt)  write_txt  > "$OUT_PATH" ;;
        csv)  write_csv  > "$OUT_PATH" ;;
        json) write_json > "$OUT_PATH" ;;
        *) echo "Formato não suportado: $OUT_FMT" >&2; exit 2 ;;
    esac
fi

# =====================================
# Saída principal (STDOUT)
# =====================================
write_txt

# =====================================
# Resumo (STDERR, colorido)
# =====================================
echo -e "${YELLOW}\n──────── Resumo ────────${RESET}" >&2
echo -e "${GREEN}Termos únicos:${RESET} ${#TERMS[@]}" >&2
echo -e "${GREEN}Wordlists lidas:${RESET} ${TERMS_FILES_READ}" >&2
echo -e "${GREEN}Linhas casadas:${RESET} ${COUNT_BEFORE}" >&2
if $UNIQUE; then
  echo -e "${GREEN}Após --unique:${RESET} ${COUNT_AFTER}" >&2
fi
if [[ -n "$OUT_PATH" ]]; then
  echo -e "${GREEN}Arquivo salvo:${RESET} ${OUT_PATH} (formato: ${OUT_FMT})" >&2
fi
echo -e "${YELLOW}────────────────────────${RESET}\n" >&2
