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
LOG_FILE="$RECYCLE_BIN_DIR/log.txt"

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
        
        echo ""
        echo -e "${YELLOW}A recycle bin não existe atualmente.${NC}"
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
    
    echo ""
    echo -e "${GREEN}A recycle bin foi inicializada com sucesso no diretório: $RECYCLE_BIN_DIR ${NC}"
    echo ""
    echo -e "${RED}Bem vindo à recycle bin, digite o comando: './recycle_bin.sh help' para obter ajuda!${NC}"
    echo ""
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
        
            echo -e "${YELLOW}O ficheiro/diretório '$file' não existe e não pode ser apagado.${NC}"
            echo ""
            continue
            
        fi


        if [[ "$file" == "$RECYCLE_BIN_DIR"* ]]; then
        
            echo -e "${RED}Erro: Não podes eliminar a recycle bin.${NC}"
            echo ""
            continue
            
        fi


        local parent_dir
        parent_dir=$(dirname "$file")

        # verifica permissões no diretório e no ficheiro
        if [ ! -w "$parent_dir" ] || [ ! -x "$parent_dir" ] || [ ! -w "$file" ]; then
        
            echo -e "${RED}Erro: Sem permissões suficientes para apagar '$file'.${NC}"
            echo ""     
            continue
            
        fi


        local id
        id=$(generate_unique_id)
        
        local original_name=$(basename "$file")
        local original_path=$(realpath "$file")
        local deletion_date=$(date "+%Y-%m-%d %H:%M:%S")
        local file_size=$(stat -c %s "$file")
        local permissions=$(stat -c %a "$file")
        local owner=$(stat -c %U:%G "$file")
        local dest_path="$FILES_DIR/$id"
        local file_type


        if [ -d "$file" ]; then
        
            file_type="directory"
            
        else
        
            file_type="file"
            
        fi


        # verifica espaço disponível
        available_kb=$(df --output=avail "$RECYCLE_BIN_DIR" | tail -n 1)
        file_kb=$((file_size / 1024))
        
        if [ "$file_kb" -gt "$available_kb" ]; then
        
            echo -e "${RED}Erro: Espaço insuficiente para mover '$file'.${NC}"
            continue
            
        fi


        # apagar os diretorios de forma recursiva:
        
        if [ -d "$file" ]; then
        
            echo -e "${YELLOW}A apagar diretório de forma recursiva:${NC} $file"
            echo ""
            
            while IFS= read -r subitem; do
            
                local sub_id=$(generate_unique_id)
                local sub_name=$(basename "$subitem")
                local sub_path=$(realpath "$subitem")
                local sub_date=$(date "+%Y-%m-%d %H:%M:%S")
                local sub_size=$(stat -c %s "$subitem")
                local sub_perms=$(stat -c %a "$subitem")
                local sub_owner=$(stat -c %U:%G "$subitem")

                if [ -d "$subitem" ]; then
                
                    sub_type="directory"
                    
                else
                
                    sub_type="file"
                    
                fi

                sub_dest="$FILES_DIR/$sub_id"
                mv "$subitem" "$sub_dest"

                echo "$sub_id,$sub_name,$sub_path,$sub_date,$sub_size,$sub_type,$sub_perms,$sub_owner" >> "$METADATA_FILE"
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Apagado: $sub_path -> $sub_dest" >> "$LOG_FILE"
                
            done < <(find "$file" -depth)


            rm -rf "$file"
            echo -e "${GREEN}Diretório movido para a recycle bin:${NC} $original_name"
            continue

        fi


        if ! mv "$file" "$dest_path"; then
            echo -e "${RED}Erro: Falha ao mover '$file'.${NC}"
            echo ""
            continue
        fi


        echo "$id,$original_name,$original_path,$deletion_date,$file_size,$file_type,$permissions,$owner" >> "$METADATA_FILE"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Apagado: $original_path -> $dest_path" >> "$LOG_FILE"
        echo -e "${GREEN}Movido com sucesso para a recycle bin:${NC} $original_name"

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

    printf '%s\n' "-----------------------------=== Recycle Bin Contents ===--------------------------------"
    printf '%s\n' "-----------------------------------------------------------------------------------------"
    
    if [ "$#" -gt 1 ]; then
    
        echo -e "${RED}Erro: O comando foi digitado incorretamente.${NC}"
        echo "Uso correto: ./recycle_bin.sh list --detailed"
        return 1
    
    fi
    
    
    local modo="nao_detalhado"

    if [ -z "$1" ]; then
    
        modo="nao_detalhado"
        
    elif [ "$1" = "--detailed" ]; then
    
        modo="detalhado"
        
    else
    
        echo -e "${RED}Erro: Argumento inválido: $1${NC}"
        echo "Uso correto: ./recycle_bin.sh list [--detailed]"
        return 1
        
    fi
    
    
    local total_files=0
    local total_size=0
    
    if [ "$modo" = "nao_detalhado" ]; then
    
        linha=0
        
        printf "%-25s %-25s %-20s %-10s\n" "ID" "NOME" "DATA" "TAMANHO (Bytes)"
        printf "%-25s %-25s %-20s %-10s\n" "-------------------------" "-------------------------" "--------------------" "----------------"
        
        while IFS=',' read -r id name path date size type perms owner; do
            
            ((linha++))
            [ $linha -eq 1 ] && continue
            printf "%-25s %-25s %-20s %-10s\n" "$id" "$name" "$date" "$size"
            
            ((total_files++))
            ((total_size+=size))
            
        done < "$METADATA_FILE"

    else

        linha=0
        total_files=0
        total_size=0

        printf "%-20s %-20s %-55s %-20s %10s %-12s %-12s %-20s\n" \
        "ID" "NOME" "CAMINHO ORIGINAL" "DATA" "TAM (B)" "TIPO" "PERMISSÕES" "OWNER"
        printf "%-20s %-20s %-55s %-20s %10s %-12s %-12s %-20s\n" \
        "--------------------" "--------------------" "-------------------------------------------------------" "--------------------" "----------" "------------" "------------" "--------------------"

        while IFS=',' read -r id name path date size type perms owner; do

            ((linha++))
            [ $linha -eq 1 ] && continue

            printf "%-20s %-20s %-55s %-20s %-10s %-12s %-12s %-20s\n" \
            "$id" "$name" "$path" "$date" "$size" "$type" "$perms" "$owner"

            ((total_files++))
            ((total_size+=size))

        done < "$METADATA_FILE"
        
    fi

    
    #TODO adicionar ao README que foi usada ai para determinar a unidade de medida adequada.
    # este trecho de código, vai escolher a unidade de armazenamento mais adequada para o size total dos ficheiros que estiverem na recycle bin:
    #############################################################
    
    local human_readable_size=$total_size
    local unit="B"

    if [ $total_size -ge 1073741824 ]; then
    
        human_readable_size=$((total_size / 1073741824))
        unit="GB"
        
    elif [ $total_size -ge 1048576 ]; then
    
        human_readable_size=$((total_size / 1048576))
        unit="MB"
        
    elif [ $total_size -ge 1024 ]; then
    
        human_readable_size=$((total_size / 1024))
        unit="KB"
        
    fi
    
    ##############################################################
    
    printf '%s\n' "-----------------------------------------------------------------------------------------"
    printf "Total de ficheiros: %d\n" "$total_files"
    printf "Tamanho total: %s %s\n" "$human_readable_size" "$unit"
    printf '%s\n' "-----------------------------------------------------------------------------------------"
    
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

    echo ""
    echo -e "${GREEN}==================== Recycle Bin Help ======================${NC}"
    echo ""
    echo -e "${YELLOW}Uso:${NC}  ./recycle_bin.sh [opção] [argumentos]"
    echo ""
    echo -e "${YELLOW}Opções disponíveis:${NC}"
    echo -e "  ${GREEN}init${NC}                 Inicializa a recycle bin e cria a estrutura necessária"
    echo -e "  ${GREEN}delete <ficheiro>${NC}    Move um ou vários ficheiros/diretórios para a recycle bin"
    echo -e "  ${GREEN}list${NC}                 Lista o conteúdo da recycle bin "
    echo -e "  ${GREEN}list --detailed${NC}      Lista o conteúdo da recycle bin no modo detalhado"
    echo -e "  ${GREEN}preview <id>${NC}         Mostra as primeiras 10 linhas de um ficheiro pelo seu id ou o tipo do ficheiro se for binário"
    echo -e "  ${GREEN}restore <id>${NC}         Restaura um ficheiro eliminado para o local original"
    echo -e "  ${GREEN}search <padrão>${NC}      Procura ficheiros na recycle bin pelo nome"
    echo -e "  ${GREEN}empty${NC}                Esvazia permanentemente a recycle bin"
    echo -e "  ${GREEN}help${NC}                 Mostra esta mensagem de ajuda"
    echo ""
    echo -e "${YELLOW}Exemplos:${NC}"
    echo "  ./recycle_bin.sh init"
    echo "  ./recycle_bin.sh delete ~/teste_recyclebin/file1.txt"
    echo "  ./recycle_bin.sh list --detailed"
    echo "  ./recycle_bin.sh preview 176126081_glq9w9"
    echo "  ./recycle_bin.sh restore 176126081_glq9w9"
    echo "  ./recycle_bin.sh search .txt"
    echo "  ./recycle_bin.sh empty"
    echo ""
    echo -e "${GREEN}==========================================================${NC}"
    return 0
    
}

#################################################
# Function: preview_file
# Description: Displays the first 10 lines of the selected file in the recycle bin.
# Parameters: None
# Returns: 1 if not sucessful, 0 if sucessful
#################################################

preview_file(){

    if [ ! -d "$RECYCLE_BIN_DIR" ]; then
    
        echo -e "${RED}A recycle bin não existe atualmente e deve ser criada antes de poder dar preview.${NC}"
        return 1
        
    fi
    
    
    if [ $# -ne 1 ]; then
    
        echo -e "${RED}Deve ser inserido apenas o id do ficheiro na recycle bin como argumento.${NC}"
        return 1
        
    fi
    
    
    local file_id=$1
    local linha_metadata=$(grep "^$file_id," "$METADATA_FILE")
    
    if [ -z "$linha_metadata" ]; then
    
        echo -e "${RED}Erro: ID '$file_id' não encontrado na recycle bin.${NC}"
        return 1
        
    fi
    
    
    IFS=',' read -r id name path date size type perms owner <<< "$linha_metadata"
    local file_path="$FILES_DIR/$id"
    
    
    if [ -d "$file_path" ]; then
    
        echo -e "${YELLOW}'$name' é um diretório, não um ficheiro.${NC}"
        return 0
        
    fi

    
    if [ ! -e "$file_path" ]; then
    
        echo -e "${RED}Erro: Ficheiro '$name' não encontrado no diretório da recycle bin.${NC}"
        return 1
        
    fi
    
    
    if [ ! -s "$file_path" ]; then
    
        echo -e "${YELLOW}O ficheiro está vazio.${NC}"
        return 0
        
    fi

    
    echo -e "${GREEN}Pré-visualizar ficheiro:${NC} $name"
    echo "-----------------------------------------------"

    file_type=$(file "$file_path")

    case "$file_type" in
    
        *text*)
            head -n 10 "$file_path"
            ;;
            
        *)
            echo "$file_type"
            ;;
            
    esac


    echo "-----------------------------------------------"
    return 0
}

#################################################
# Function: main
# Description: Main program logic
# Parameters: Command line arguments
# Returns: Exit code
#################################################

main() {

    # Parse command line arguments
    case "$1" in
        init)
            initialize_recyclebin
            ;;
            
        delete)
            shift
            delete_file "$@"
            ;;
            
        list)
            shift
            list_recycled "$@"
            ;;
            
        preview)
            shift
            preview_file "$@"
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


