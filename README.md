# Dotfiles

Configuração pessoal para Bash 3.2 ou superior no Linux e macOS.
As funções seguem namespaces como `docker-`, `git-`, `fr-` e `show-`, em ordem alfabética.
Nomes antigos continuam disponíveis como aliases.

Use GNU Make para consultar a ajuda, simular ou instalar a partir de qualquer diretório:

```bash
make -C /path/dotfiles.git help
make -C /path/dotfiles.git dry-run
make -C /path/dotfiles.git install
make -C /path/dotfiles.git status       # links ok, quebrados ou arquivos reais
make -C /path/dotfiles.git uninstall    # remove só links deste repo (DRY_RUN=1 simula)
make -C /path/dotfiles.git check        # bash -n, ShellCheck, testes e busca de segredos
make -C /path/dotfiles.git install-hooks # pre-commit que roda "make check"
```

`make` sem argumentos exibe a ajuda. `make install` substitui arquivos e links em `HOME`,
mas recusa diretórios reais existentes. Exibe cada comando executado, os caminhos ignorados
e os arquivos locais preservados.
`dot.config` não faz parte da instalação. No macOS, `~/.lldb` é clonado quando não existe.

Preferências, aliases e hosts pessoais ficam em `dot.bash_profile` e `dot.bash_alias`.
`~/.bash_alias_work`, quando presente, é carregado por último e não é versionado.

Recarregue com `source ~/.bashrc` e consulte a ajuda:

```bash
dotfiles-help                  # Visão geral curta
dotfiles-help docker           # Busca por nome
dotfiles-help functions        # Funções com descrições
dotfiles-help aliases          # Aliases da sessão
dotfiles-help vars             # Variáveis e valores atuais
dotfiles-help all              # Catálogo completo
docker-run-bash-in --help      # Ajuda e sintaxe do helper
tar-extract -h                 # Forma curta de ajuda
```

A ajuda lê tags junto das definições, sem executar o código documentado:

```bash
# @help Abre Bash em um container em execução.
# @syntax docker-run-bash-in <container>
docker-run-bash-in() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" docker || return
    # ...
}

# @var EDITOR
# @help Editor padrão.
export EDITOR="${EDITOR:-vim}"
```

O nome da função vem da declaração. `@var` identifica a variável, inclusive quando ela
é configurada em uma declaração com várias atribuições ou recebida do ambiente.
Use uma linha por tag; separe blocos de documentação com uma linha vazia.
`@syntax` aparece nas buscas e em `all`. Os aliases exibem seus comandos atuais.
As tags também podem ser usadas nos arquivos locais e em `~/.bash_alias_work`.
Os helpers aceitam `-h` e `--help` antes de verificar dependências ou executar ações.
`dotfiles-help --exact <nome>` consulta somente o nome informado.

As funções usam nomes de finalidade, como `date-months-between`, `tar-extract`,
`ffmpeg-reduce` e `network-public-ip`. Os nomes `my-*` permanecem como aliases.
`mysql-connect` usa `MYSQL_HOST` e `MYSQL_USER` da configuração local;
`iperf3-test` usa `IPERF3_HOST` ou, sem configuração, `localhost`.

O `PATH` recebido é preservado; diretórios existentes são acrescentados sem duplicação.
Homebrew e integrações Docker/iTerm são opcionais. Completions externas são carregadas
com Bash 4.4 ou superior; os helpers também funcionam com o Bash 3.2 do macOS.
`EDITOR` e `EDITOR_OPTS` aceitam argumentos simples separados por espaços, sem sintaxe de shell.

Helpers específicos de plataforma exigem suas ferramentas: apt/dpkg/Snap no Linux,
Homebrew/Xcode/pyenv no macOS. Outros usam Docker, Git, OpenSSL, rsync, iperf3, ffmpeg,
exiftool, sipcalc ou ferramentas de captura, conforme descrito em `dotfiles-help`.
Uma dependência obrigatória ausente gera uma mensagem com o nome do comando e retorna 127.
Helpers que apenas exibem comandos não exigem os programas exibidos.
Comandos de limpeza, rebase e alterações de sistema executam as ações indicadas na ajuda.
`show-disk-speed` usa um arquivo temporário de 8096 MiB.

No macOS, `xquartz desativar` encerra o XQuartz e bloqueia sua inicialização automática
na conta, inclusive após novo login. `xquartz ativar` libera a inicialização e abre o
aplicativo; `xquartz status` consulta os serviços desabilitados e os processos do XQuartz.
O padrão é `XQUARTZ_ENABLED=0`: cada terminal aplica a desativação. Para habilitar o
XQuartz ao abrir o terminal, defina `export XQUARTZ_ENABLED=1` em `~/.bash_profile`.

## Shell

- Histórico: `HISTCONTROL=ignoreboth:erasedups`, `histappend` e `history -a` a cada prompt,
  então terminais diferentes compartilham o histórico.
- Prompt: mostra ` (branch)` em repositórios Git e `:( <código>` quando o último comando falha.
- SSH: `ssh-list` (alias `sshl`) lista os hosts de `~/.ssh/config`, dos `Include` e de
  `MYSERVERS`; o mesmo conjunto completa `ssh`, `scp`, `sftp` e `ssh-copy-id`.
  `~/.ssh/config.local` (criado pelo `make install` a partir de `local/ssh_config.local.example`,
  nunca versionado) é incluído primeiro e sobrescreve o restante.
- fzf (0.48+): `Ctrl-R` histórico, `Ctrl-T` arquivos e `Ctrl-G` cd (o Alt-C não existe no
  macOS). Com `fd` usa o `.gitignore`; com `bat` mostra preview. Variáveis `FZF_*` já
  definidas são mantidas.
- `make check` roda `tests/secrets.sh`, que acusa IP público, `.pem`, chave privada e <!-- secrets-ok -->
  `password=`/`token=`. Falso positivo: acrescente `# secrets-ok` na linha.
- `have <comando>` testa se um comando existe; os aliases opcionais o usam como guarda.

## Dependências opcionais

| Ferramenta   | O que ativa                                                      |
| ------------ | ---------------------------------------------------------------- |
| `eza`        | `ls`, `la`, `l` e `v` coloridos, com Git                         |
| `grc`        | Cores em `ps`, `df`, `ping`, `ip`, `make` etc. (só em terminal)  |
| `procs`      | `ps` sem argumentos no macOS                                     |
| `fzf`        | Ctrl-R, Ctrl-T e Ctrl-G (cd) interativos                         |
| `fd`, `bat`  | Listagem que respeita `.gitignore` e preview no fzf              |
| `shellcheck` | Análise estática no `make check`                                 |
| `bash-completion` | Completions externas (Bash 4.4 ou superior)                 |

Execute a validação com GNU Make, Bash, Git e ferramentas básicas do sistema
(`make check` cobre `bash -n`, ShellCheck e os testes, quando existirem):

```bash
/bin/bash tests/bash.sh
/opt/homebrew/bin/bash tests/bash.sh
shellcheck -s bash -S warning dot.bash* local/*.example tests/bash.sh
make --no-print-directory -n install | shellcheck -s bash -S warning -
```

Os testes usam um `HOME` temporário, um repositório Git descartável e simulações dos
comandos externos que alteram sistemas ou serviços.

O workflow [Bash](.github/workflows/bash.yml) executa testes e ShellCheck em pushes e pull
requests, com jobs para Linux e macOS. No macOS, testa o Bash do sistema e o do Homebrew.
Também é possível iniciá-lo manualmente pelo GitHub Actions.
