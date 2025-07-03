#!/bin/bash
# filtrar_wordlist.sh – v2.6
# Uso: ./filtrar_wordlist.sh [-v|-s]

########################################
# CONFIGURAÇÃO DE CORES (ANSI)
########################################
# Cores para saída:
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
MAGENTA="\033[35m"
CYAN="\033[36m"
GRAY="\033[90m"
RESET="\033[0m"

########################################
# FLAGS
########################################
VERBOSE=false
SILENT=false
while getopts "vs" OPT; do
    case $OPT in
        v) VERBOSE=true ;;  # modo verbose
        s) SILENT=true ;;   # modo silent
        *) ;;
    esac
done
shift $((OPTIND-1))

# Não permitir ambas as flags simultâneas
if $VERBOSE && $SILENT; then
    echo -e "${RED}Erro:${RESET} Não use -v e -s juntos."
    exit 1
fi

########################################
# FUNÇÃO DE BANNER ESTILO HTTPX (SLANT)
########################################
show_banner() {
    if command -v figlet &>/dev/null; then
        if command -v lolcat &>/dev/null; then
            figlet -f slant "GrepGustavin" | lolcat
        else
            printf "%b" "$RED"; figlet -f slant "GrepGustavin"; printf "%b" "$RESET"
        fi
    else
        echo -e "${MAGENTA}===== GrepGustavin =====${RESET}"
    fi
    echo -e "${CYAN}v2.6${RESET}\n"
    echo -e "${GRAY}Use with caution. You are responsible for your actions."
    echo -e "Developers assume no liability and are not responsible for any misuse or damage.${RESET}\n"
}

########################################
# LEITURA DE ENTRADAS
########################################
read -e -p "Digite o caminho completo da wordlist: " WORDLIST
if [ ! -f "$WORDLIST" ]; then
    echo -e "${RED}Erro:${RESET} Arquivo '$WORDLIST' não encontrado!"
    exit 1
fi

read -p "Digite o(s) termo(s) separados por vírgula (ex: netflix,youtube): " TERMO_INPUT
# Quebra em array e remove espaços
IFS=',' read -ra TERMS_ARRAY <<< "$TERMO_INPUT"
for i in "${!TERMS_ARRAY[@]}"; do
    TERMS_ARRAY[$i]="$(echo "${TERMS_ARRAY[$i]}" | xargs)"
done
# Expressão regex para grep
REGEX_PATTERN="$(IFS='|'; echo "${TERMS_ARRAY[*]}")"
# Nome base para arquivo de saída
JOIN_TERMS="$(IFS=_; echo "${TERMS_ARRAY[*]}")"

DIR_SAIDA=$(dirname "$WORDLIST")
BASE_OUTPUT="${DIR_SAIDA}/resultado_${JOIN_TERMS}"
# Garante nome único de saída sem sobrescrever
OUTFILE="${BASE_OUTPUT}.txt"
count=1
while [ -e "$OUTFILE" ]; do
    OUTFILE="${BASE_OUTPUT}_${count}.txt"
    count=$((count+1))
done

########################################
# MODO SILENT (-s)
########################################
if $SILENT; then
    show_banner
    echo -e "${CYAN}Executando busca silenciosa…${RESET}"
    # Busca com destaque ANSI das cores no arquivo
    grep -i -E --color=always "$REGEX_PATTERN" "$WORDLIST" > "$OUTFILE"
    if [ -s "$OUTFILE" ]; then
        cnt=$(wc -l < "$OUTFILE")
        echo -e "${GREEN}✔️  ${cnt} linha(s) salva(s) em:${RESET} $OUTFILE"
    else
        echo -e "${YELLOW}⚠️  Nenhum resultado encontrado para '$TERMO_INPUT'.${RESET}"
        rm -f "$OUTFILE"
    fi
    exit 0
fi

########################################
# MODO VERBOSE (-v)
########################################
if $VERBOSE; then
    show_banner
    echo -e "${CYAN}↪ Resultados:${RESET}"
    # Define cor do match via GREP_COLORS
    export GREP_COLORS="mt=1;33"
    # Imprime cada linha em magenta e deixa grep colorir o termo em amarelo
    grep --color=always -n -i -E "$REGEX_PATTERN" "$WORDLIST" \
        | while IFS= read -r line; do
            echo -e "${MAGENTA}${line}${RESET}"
        done
    echo
fi

########################################
# MODO PADRÃO (sem flags)
########################################
# Exibe banner no padrão
if ! $VERBOSE && ! $SILENT; then
    show_banner
fi
# Grava arquivo com cores ANSI
export GREP_COLORS="mt=1;33"
grep --color=always -i -E "$REGEX_PATTERN" "$WORDLIST" > "$OUTFILE"
if [ -s "$OUTFILE" ]; then
    cnt=$(wc -l < "$OUTFILE")
    echo -e "${GREEN}✔️  ${cnt} linha(s) salva(s) em:${RESET} $OUTFILE"
else
    echo -e "${YELLOW}⚠️  Nenhum resultado encontrado para '$TERMO_INPUT'.${RESET}"
    rm -f "$OUTFILE"
fi
