# Linux Recycle Bin System

## Authors

Pedro Miguel Morais Gonçalves
126463
&
David Saraiva Monteiro 
125793

## Description
Neste projeto foi desenvolvido um sistema de Recycle Bin em Bash, que simula uma trash can do ambiente Linux,
permitindo eliminar, restaurar e gerir ficheiros. O sistema foi implementado em conformidade com o enunciado proposto,
por forma a garantir o armazenamento de metadados, registos de log e suporte a múltiplas operações.

## Installation
1 - Fazer download da pasta .zip enviado pelo elearning, e movê-la para "HOME".

2 - Extrair a pasta comprimida.

3 - Digitar no terminal "cd Projeto01_SO" e em seguida "cd G05P1_RecycleBin" 

4 - Conceder as permissões necessárias para o ficheiro principal, recorrendo ao comando: "chmod +x recycle_bin.sh"

5 - Executar os comandos pretendidos, para obter informações acerca dos comandos, basta digitar
"./recycle_bin.sh help" no terminal, e irão aparecer as diversas opções disponíveis.

## Usage
[How to use with examples]

## Features
- initialize_recyclebin()
- delete_file()
- list_recycled() (com --detailed)
- restore_file() (com id ou filename)
- empty_recyclebin() (com e sem --force com id e empty)
- display_help ()
- search_recycled ()

* preview_file ()

## Configuration
O ficheiro de configuração é criado automaticamente aquando da execução do comando init, tal como explicado na usage,
e contém apenas as informações que foram ditas obrigatórias no documento, no caso: MAX_SIZE_MB=1024 e RETENTION_DAYS=30
ou seja, a Recycle Bin poderá guardar até 1024mb de ficheiros, até 30 dias, após esses 30 dias, a função autocleanup()
irá esvaziar a Recycle Bin.

## Examples
[Detailed usage examples with screenshots]

## Known Issues
- Quando um ficheiro é adicionado à recycle_bin fora da linha de comandos, por métodos externos aos pedidos, 
o programa não deteta que o ficheiro se encontra dentro da recycle bin.

## References
[Resources used]
