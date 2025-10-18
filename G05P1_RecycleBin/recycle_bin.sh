#!/bin/bash
#################################################
# Script Header Comment
# Authors: Pedro Gonçalves 126463 & David Monteiro 125793
# Date: 
# Description: Brief description
# Version: 1.0
#################################################

# Global Variables (ALL CAPS)
RECYCLE_BIN_DIR="$HOME/.recycle_bin"
METADATA_FILE="$RECYCLE_BIN_DIR/metadata.db"

# Color Codes (optional but recommended)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function Definitions
# - Each function must have a header comment
# - Use descriptive function names
# - Validate all parameters
# - Return appropriate exit codes

#################################################
# Function: initialize_recyclebin
# Description: Initializes the recycle bin if it exists, and creates its structure if it doesn't exist.
# Returns: 0 if it works sucessfully or 1 if not.
#################################################

initialize_recyclebin() {

    local dir="$HOME/Projeto01_SO/recycle_bin" ####### COLOCAR AQUI UM PONTO (ANTES DE recycle_bin) QUANDO FOR PARA ENTREGAR!!
    local files_dir="$dir/files"
    local metadata="$dir/metadata.db"
    local config="$dir/config"
    local log_file="$dir/recyclebin.log"
    
    if [ ! -d "$dir" ]; then
    
        echo "A recycle bin não existe atualmente."
        echo "A inicializar recycle bin..."
        mkdir -p "$files_dir" || { echo "Erro ao inicializar o recicle bin."; return 1; }
        
    fi
    
    if [ ! -f "$metadata" ]; then
    
        echo "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER" > "$metadata"
        
    fi
    
    if [ ! -f "$config" ]; then
    
        echo "MAX_SIZE_MB=1024" > "$config" # aqui cria primeiro o ficheiro com o size
        echo "RETENTION_DAYS=30" >> "$config" # depois acrescenta ao mesmo ficheiro
        
    fi
    
    if [ ! -f "$log_file" ]; then
    
        touch "$log_file"
        
    fi
    
    echo "A recycle bin foi inicializada com sucesso no diretório: $dir!"
    return 0
}

# Main Program Logic
main() {
    case "$1" in
        init)
            initialize_recyclebin
            ;;
        *)
            echo "Uso: $0 {init}"
            echo "Exemplo: ./recycle_bin.sh init"
            ;;
    esac
}
# Script Entry Point
main "$@"
