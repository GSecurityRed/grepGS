# GrepGustavin

Uma ferramenta simples de linha de comando para filtrar grandes *wordlists* com múltiplos termos, destacando resultados em cores e gerando arquivos de saída únicos.
<br>


---
![image](https://github.com/user-attachments/assets/89a0b37e-6a5b-4e3c-aadc-c5f2ecb867e0)



---

## Pré-requisitos

- Bash (versão ≥ 4)
- `grep` (GNU grep, com suporte a --color)

---

## Instalação

```bash
# Clone o repositório
git clone https://github.com/GSecurityRed/Grep-Gustavin

# Entre na pasta do projeto
cd GrepGustavin

# Dê permissão de execução
chmod +x grep_gustavin.sh
```

---

## Uso

```bash
# Modo padrão (só gera arquivo resultado_<termos>.txt)
./grep_gustavin.sh /caminho/para/wordlist.txt

# Modo verbose (banner + output colorido)
./grep_gustavin.sh -v /caminho/para/wordlist.txt

# Modo silent (rápido, só resumo + arquivo colorido)
./grep_gustavin.sh -s /caminho/para/wordlist.txt
```

## Flags

| Flag | Descrição                                              |
|------|--------------------------------------------------------|
| `-v` | **Verbose**: Banner + resultados numerados + cores.    |
| `-s` | **Silent**: Busca rápida + gravação colorida + resumo. |

---

## Como funciona

1. Solicita caminho da *wordlist* e termos (separados por vírgula).
2. Gera expressão regex interna (`term1|term2|...`).
3. Encontra correspondências via `grep -E`.
4. Destaca termos em amarelo e pinta linha inteira em magenta (Terminal).
5. Grava arquivo de saída com cores ANSI.

---

© [GSecurity]
