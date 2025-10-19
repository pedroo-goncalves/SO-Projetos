#!/bin/bash

#################################################
# Script Header Comment
# Authors: Pedro Gonçalves 126463 & David Monteiro 125793
# Date: 29/10/25
# Description: Brief description
# Version: 1.0
#################################################

# Global Configuration
RECYCLE_BIN_DIR="$HOME/Projeto01_SO/recycle_bin" ####### COLOCAR AQUI UM PONTO (ANTES DE recycle_bin) QUANDO FOR PARA ENTREGAR!!
FILES_DIR="$RECYCLE_BIN_DIR/files"
METADATA_FILE="$RECYCLE_BIN_DIR/metadata.db"
CONFIG_FILE="$RECYCLE_BIN_DIR/config"

# Color codes for output (optional)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#################################################
# Function: initialize_recyclebin
# Description: initializes the recycle bin if it exists, and creates its structure if it doesn't exist.
# Returns: 0 if it works sucessfully or 1 if not.
#################################################

initialize_recyclebin() {
    
    if [ ! -d "$RECYCLE_BIN_DIR" ]; then
    
        echo "A recycle bin não existe atualmente."
        echo "A inicializar recycle bin..."
        mkdir -p "$FILES_DIR" || { echo "${RED}Ocorreu um erro ao inicializar a recycle bin."; return 1; }
        
    fi

    if [ ! -f "$METADATA_FILE" ]; then
    
        echo "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER" > "$METADATA_FILE"
        
    fi

    if [ ! -f "$CONFIG_FILE" ]; then
    
        echo "MAX_SIZE_MB=1024" > "$CONFIG_FILE"
        echo "RETENTION_DAYS=30" >> "$CONFIG_FILE"
        
    fi

    if [ ! -f "$LOG_FILE" ]; then
    
        touch "$LOG_FILE"
        
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') - Recycle bin inicializada." >> "$LOG_FILE"
    
    echo "A recycle bin foi inicializada com sucesso no diretório: $RECYCLE_BIN_DIR!"
    return 0
    
}

#################################################
# Function: generate_unique_id
# Description: Generates unique ID for deleted files
# Parameters: None
# Returns: Prints unique ID to stdout
#################################################

generate_unique_id() {

    local timestamp=$(date +%s)
    local random=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)
    echo "${timestamp}_${random}"
    
}

#################################################
# Function: delete_file
# Description: Moves file/directory to recycle bin
# Parameters: $1 - path to file/directory
# Returns: 0 on success, 1 on failure
#################################################

delete_file() {
    
    if [ $# -eq 0 ]; then
    
        echo -e "${YELLOW}Deve ser digitado o nome ou diretório de pelo menos um ficheiro.${NC}"
        return 1
        
    fi
    
    if [ ! -d "$RECYCLE_BIN_DIR" ]; then
    
        initialize_recyclebin
        
    fi
    
    for file in "$@"; do
    
        if [ ! -e "$file" ]; then
        
            echo -e "${YELLOW}O ficheiro/diretório: "$file" ; não existe e não pode ser apagado. ${NC}"
            continue
            
        fi
        
        if [[ "$file" == "$RECYCLE_BIN_DIR"* ]]; then
        
            echo -e "${RED}Erro: Não podes eliminar a recycle bin.${NC}"
            continue
            
        fi
        
        local parent_dir
        parent_dir=$(dirname "$file")
        
        # verifica se o utilizador tem permissões de escrita (para remover entradas) e execução (para aceder ao conteúdo)
        # no diretório pai, que são as permissões exigidas pelo Linux para apagar ou mover um ficheiro

        if [ ! -w "$parent_dir" ] || [ ! -x "$parent_dir" ]; then
        
            echo -e "${RED}Erro: Sem permissões no diretório que contém '$file'.${NC}"
            continue
            
        fi
        
        local id 
        id=$(generate_unique_id)
        
        local original_name
        original_name=$(basename "$file")
        
        local original_path
        original_path=$(realpath "$file")
        
        local deletion_date
        deletion_date=$(date "+%Y-%m-%d %H:%M:%S")
        
        local file_size
        file_size=$(stat -c %s "$file")
        
        local file_type
        if [ -d "$file" ]; then
        
            file_type="directory"
            
        else
        
            file_type="file"
            
        fi
        
        local permissions
        permissions=$(stat -c %a "$file")
        
        local owner
        owner=$(stat -c %U:%G "$file")
        
        local dest_path="$FILES_DIR/$id"
        
        available_kb=$(df --output=avail "$RECYCLE_BIN_DIR" | tail -n 1) # verifica o espaço que ainda existe em KB
        file_kb=$((file_size / 1024)) # transforma tudo de Bytes para KiloBytes

        if [ "$file_kb" -gt "$available_kb" ]; then
        
            echo -e "${RED}Erro: Espaço insuficiente para mover '$file'.${NC}"
            continue
            
        fi

        if [ "$file_type" = "directory" ]; then
        
            echo -e "${YELLOW}A mover diretório de forma recursiva:${NC} $file"
            
        fi

        mv "$file" "$dest_path" # move de forma recursiva, porque envia tudo o que estiver dentro do diretório para o recycle bin como sendo apenas um item com um id único
        move_status=$?

        if [ $move_status -ne 0 ]; then
        
            echo -e "${RED}Erro: Falha ao mover '$file'.${NC}"
            continue
            
        else
        
            echo -e "${GREEN}Ficheiro movido com sucesso:${NC} $file"
            
        fi
        
        echo "$id,$original_name,$original_path,$deletion_date,$file_size,$file_type,$permissions,$owner" >> "$METADATA_FILE"
        
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Deleted: $original_path -> $dest_path" >> "$LOG_FILE"
        
        echo -e "${GREEN}Movido para a recycle bin:${NC} $original_name"
    
    done     
    return 0
    
}

#################################################
# Function: list_recycled
# Description: Lists all items in recycle bin
# Parameters: None
# Returns: 0 on success
#################################################

list_recycled() {
    # TODO: Implement this function
    echo "=== Recycle Bin Contents ==="
    # Your code here
    # Hint: Read metadata file and format output
    # Hint: Use printf for formatted table
    # Hint: Skip header line
    return 0
}

#################################################
# Function: restore_file
# Description: Restores file from recycle bin
# Parameters: $1 - unique ID of file to restore
# Returns: 0 on success, 1 on failure
#################################################

restore_file() {
    # TODO: Implement this function
    local file_id="$1"

    if [ -z "$file_id" ]; then
        echo -e "${RED}Error: No file ID specified${NC}"
        return 1
    fi

    # Your code here
    # Hint: Search metadata for matching ID
    # Hint: Get original path from metadata
    # Hint: Check if original path exists
    # Hint: Move file back and restore permissions
    # Hint: Remove entry from metadata
    return 0
}

#################################################
# Function: empty_recyclebin
# Description: Permanently deletes all items
# Parameters: None
# Returns: 0 on success
#################################################

empty_recyclebin() {
    # TODO: Implement this function
    # Your code here
    # Hint: Ask for confirmation
    # Hint: Delete all files in FILES_DIR
    # Hint: Reset metadata file
    return 0
}

#################################################
# Function: search_recycled
# Description: Searches for files in recycle bin
# Parameters: $1 - search pattern
# Returns: 0 on success
#################################################

search_recycled() {
    # TODO: Implement this function
    local pattern="$1"
    # Your code here
    # Hint: Use grep to search metadata
    return 0
}

#################################################
# Function: display_help
# Description: Shows usage information
# Parameters: None
# Returns: 0
#################################################

display_help() {
    cat << EOF
Linux Recycle Bin - Usage Guide
SYNOPSIS:
$0 [OPTION] [ARGUMENTS]
OPTIONS:
  delete <file>       Move file/directory to recycle bin
  list                List all items in recycle bin
  restore <id>        Restore file by ID
  search <pattern>    Search for files by name
  empty               Empty recycle bin permanently
  help                Display this help message

EXAMPLES:
  $0 delete myfile.txt
  $0 list
  $0 restore 1696234567_abc123
  $0 search "*.pdf"
  $0 empty
EOF
    return 0
}

#################################################
# Function: main
# Description: Main program logic
# Parameters: Command line arguments
# Returns: Exit code
#################################################

main() {
    # Initialize recycle bin
    initialize_recyclebin

    # Parse command line arguments
    case "$1" in
        delete)
            shift
            delete_file "$@"
            ;;
        list)
            list_recycled
            ;;
        restore)
            restore_file "$2"
            ;;
        search)
            search_recycled "$2"
            ;;
        empty)
            empty_recyclebin
            ;;
        help|--help|-h)
            display_help
            ;;
        *)
            echo "Invalid option. Use 'help' for usage information."
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"


