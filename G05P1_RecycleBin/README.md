# Linux Recycle Bin System

## Authors

Pedro Miguel Morais Gonçalves
126463
&
David Saraiva Monteiro 
125793

## Description

Este projeto teve como objetivo o desenvolvimento de um sistema de Recycle Bin para o ambiente Linux utilizando o Bash Shell Scripting. Este sistema simula essencialmente a funcionalidade Trash Can do Linux através da implementação de diversas funções modelares. Deste modo, o sistema tem a capacidade de eliminar, restaurar e listar ficheiros; gerir e armazenar metadados; registar todas as operações no log(histórico); entre outras funções adicionais. Toda a implementação foi feita em conformidade com os enunciados propostos para o Trabalho Prático 1 - Linux Recycle Bin Simulation, no âmbito da disciplina de Sistemas Operativos.

## Installation

[1] - Fazer o download da pasta .zip enviada pelo elearning. Posteriormente deverá movê-la da secção "Downloads"/"Transferências" para a secção "HOME"/"Pasta Pessoal".

[2] - Extrair a pasta comprimida (Botão direito -> Extrair).

[3] - Abrir o terminal e aceder ao diretório correto (Quando o terminal é aberto já se encontra no diretório "/home/user/". Para tal deverá introduzir os seguintes comandos "cd Projeto01_SO" e "cd G05P1_RecycleBin". Em alternativa poderá mencionar o caminho completo "cd Projeto01_SO/G05P1_RecycleBin".

[4] - Conceder as permissões necessárias para o ficheiro principal, recorrendo ao comando: "chmod +x recycle_bin.sh"

[5] - Começar a utilizar o Recycle Bin executando os comandos pretendidos. Para obter informações acerca dos comandos, pode aceder à secção de ajuda introduzindo o seguinte comando "./recycle_bin.sh help" no terminal. Agora aparece um menu com as diversas opções disponíveis.

## Usage


## Features
[Mandatory Features]

[1] Initialize Recycle Bin
    -Function Name: initialize_recyclebin()

[2] Delete Files/Directories
    -Function Name: delete_file()
    -Auxiliary Function Name: generate_unique_id()

[3] List Recycle Bin Contents
    -Function Name: list_recycled()
    -Function Modes: Normal Mode & Detailed Mode (using --detailed flag)

[4] Restore Files
    -Function Name: restore_file()

[5] Search Files
    -Function Name: search_recycled()

[6] Empty Recycle Bin
    -Function Name: empty_recyclebin()
    -Function Modes: Empty All & Empty Specific
    -Force Mode: Skip confirmation using --force flag

[7] Help System
    -Function Name: display_help()

[Optional Features]

[8] Statistics Dashboard
    -Function Name: show_statistics()

[9] Auto-Cleanup
    -Function Name: auto_cleanup()

[10] Quota Management
    -Function Name: check_quota()

[11] File Preview
    -Function Name: preview_file()

## Configuration

A configuração é feita automaticamente através da criação do ficheiro "config" sempre que o Recycle Bin é inicializado (initialize_recyclebin()) isto é, sempre que é utilizado um comando que envolva o script recycle_bin.sh. Este ficheiro contém as informações de configuração obrigatórias fornecidas relativamente ao espaço de armazenamento (MAX_SIZE_MB=1024) e ao tempo de retenção dos ficheiros (RETENTION_DAYS=30). Isto significa que segundo as configurações predefinidas, o Recycle Bin poderá guardar até 1024mb de espaço para ficheiros no prazo de 30 dias. Após esses 30 dias, a função autocleanup() trata de esvaziar completamente o Recycle Bin.

## Examples
[Detailed usage examples with screenshots]

## Known Issues
[1] Problema na deteção de Ficheiros
    - Descrição do Problema: Quando um ficheiro é adicionado ao recycle_bin fora da linha de comandos, por métodos externos aos pedidos, o programa não deteta que o ficheiro se encontra dentro do recycle bin.

## References
[Resources used]
