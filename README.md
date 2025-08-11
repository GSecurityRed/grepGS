# GrepGustavin

Ferramenta de grep para caça de credenciais/strings em dumps de texto — com deduplicação por senha, exportação em TXT/CSV/JSON e resumo ao final.
<br>


---
<img width="729" height="388" alt="image" src="https://github.com/user-attachments/assets/e3fb985a-ea60-4b12-9a08-292db5f73568" />





---

## Pré-requisitos

- Bash 4+, grep, awk, sed (pré-instalados na maioria dos Linux).

---

## Instalação

```bash
# Clone o repositório
git clone https://github.com/GSecurityRed/grepGS.sh

# Entre na pasta do projeto
cd grepGS.sh

# Dê permissão de execução
chmod +x grepGS.sh
```

---

## Uso

```bash
# 1) Termo direto na linha de comando
./grepGS.sh nome dumps.txt

# 2) Vários termos (AND)
./grepGS.sh nome nome2 dumps.txt

# 3) Deduplicar por senha (último campo após ':')
./grepGS.sh --unique nome dumps.txt

# 4) Exportar para CSV
./grepGS.sh nome dumps.txt --out resultados.csv

# 5) Exportar para JSON (NDJSON)
./grepGS.sh nome dumps.txt --out resultados.json

```

## Opções

```bash
Uso: ./grepGS.sh [opções] arquivo-alvo [termo ...]

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
  -h, --help               Mostra a ajuda
```

---

© [GSecurity]
