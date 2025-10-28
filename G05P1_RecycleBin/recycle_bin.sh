#!/bin/bash

#################################################
# Script Header Comment
# Authors: Pedro Gonçalves 126463 & David Monteiro 125793
# Date: 31/10/25
# Description: This project aimed to develop a Recycle Bin system for the Linux environment using Bash Shell Scripting. The system essentially simulates the functionality of the Linux Trash Can through the implementation of various modular functions. In this way, the system is capable of deleting, restoring, and listing files; managing and storing metadata; logging all operations in a history file; among other additional features. The entire implementation was carried out in accordance with the requirements proposed for Trabalho Prático 1 – Linux Recycle Bin Simulation, within the scope of the "Sistemas Operativos" course.
# Version: 5.0
#################################################

# Global Configuration
RECYCLE_BIN_DIR="$HOME/Projeto01_SO_G05P1/recycle_bin"
FILES_DIR="$RECYCLE_BIN_DIR/files"
METADATA_FILE="$RECYCLE_BIN_DIR/metadata.db"
CONFIG_FILE="$RECYCLE_BIN_DIR/config"
LOG_FILE="$RECYCLE_BIN_DIR/recyclebin.log"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#################################################
# Function: initialize_recyclebin
# Description: initializes the recycle bin if it exists, and creates its structure if it doesn't exist.
# Parameters: None
# Returns: 0 if it works sucessfully or 1 if not.
#################################################

initialize_recyclebin() {
    
    if [ ! -d "$RECYCLE_BIN_DIR" ]; then
        echo ""
        echo -e "${YELLOW}A recycle bin não existe atualmente.${NC}"
        mkdir -p "$FILES_DIR" || { echo "${RED}Ocorreu um erro ao inicializar o Recycle Bin.${NC}"; return 1; }
	else
		echo ""
		echo -e "${RED}O Recycle Bin já existe.${NC}"
		return 1
    fi
    

    if [ ! -f "$METADATA_FILE" ]; then
        echo "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER" > "$METADATA_FILE"
    fi


    if [ ! -f "$CONFIG_FILE" ]; then
    	echo "$(date '+%Y-%m-%d %H:%M:%S') - Recycle bin inicializada." >> "$LOG_FILE"
        echo "MAX_SIZE_MB=1024" > "$CONFIG_FILE"
        echo "RETENTION_DAYS=30" >> "$CONFIG_FILE"
    fi


    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
    fi
    
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Recycle bin inicializada." >> "$LOG_FILE"
    
    echo ""
    echo -e "${GREEN}O Recycle Bin foi inicializado com sucesso no diretório: $RECYCLE_BIN_DIR ${NC}"
    echo ""
    echo -e "${RED}Bem vindo ao recycle bin, introduza o comando: './recycle_bin.sh help' para obter ajuda!${NC}"
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
        echo -e "${YELLOW}Deve ser introduzido o nome ou diretório de pelo menos um ficheiro.${NC}"
        return 1
    fi

    if [ ! -d "$RECYCLE_BIN_DIR" ]; then
		echo -e "${RED}Erro: A recycle bin deve ser inicializada antes.${NC}"
		return 1
    fi

    for file in "$@"; do
        if [ ! -e "$file" ]; then
            echo -e "${YELLOW}O ficheiro/diretório '$file' não existe e não pode ser apagado.${NC}"
            return 1
            echo ""
            continue  
        fi

        if [[ "$file" == "$RECYCLE_BIN_DIR"* ]]; then
            echo -e "${RED}Erro: Não podes eliminar a recycle bin.${NC}"
            return 1
            echo ""
            continue 
        fi

        local parent_dir
        parent_dir=$(dirname "$file")

        # verifica permissões no diretório e no ficheiro
        if [ ! -w "$parent_dir" ] || [ ! -x "$parent_dir" ] || [ ! -w "$file" ]; then
            echo -e "${RED}Erro: Sem permissões suficientes para apagar '$file'.${NC}"
            return 1
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
            return 1
            continue
            
        fi

        # apagar os diretorios de forma recursiva:
        
        if [ -d "$file" ]; then
            echo ""
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
            echo ""
            continue

        fi


        if ! mv "$file" "$dest_path"; then
            echo -e "${RED}Erro: Falha ao mover '$file'.${NC}"
            return
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

	if [ ! -d "$RECYCLE_BIN_DIR" ]; then
    
		echo -e "${RED}Erro: A recycle bin deve ser inicializada antes.${NC}"
        return 1
        
    fi
    echo ""
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

        printf "%-20s %-20s %-55s %-17s %10s %-12s %-12s %-20s\n" \
        "ID" "NOME" "CAMINHO ORIGINAL" "DATA" "TAM (B)" "   TIPO" "   PERMISSÕES" "  OWNER"
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
    echo ""
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Ficheiros da recycle bin foram listados no terminal." >> "$LOG_FILE"
    return 0
}

#################################################
# Function: restore_file
# Description: Restores file from recycle bin
# Parameters: $1 - unique ID of file to restore
# Returns: 0 on success, 1 on failure
#################################################

restore_file() {

	if [ ! -d "$RECYCLE_BIN_DIR" ]; then
        
        echo ""
		echo -e "${RED}Erro: A recycle bin deve ser inicializada antes.${NC}"
        return 1
        
    fi
    
    
    if [ $# -ne 1 ]; then
        
        echo -e "${RED}Erro: O comando foi digitado incorretamente.${NC}"
        echo "Uso correto: ./recycle_bin.sh restore <id/filename>"
        return 1
    fi
    
    
    local query="$1"
    
    # primeiro procura pelo id (tem o ^ no inicio), e era preciso saltar a primeira linha (-n + 2)
    linha_metadata=$(tail -n +2 "$METADATA_FILE" | grep -F "$query," | head -n 1)


    
    # se não encontrou, vai ver se encontra pelo nome (qualquer outra parte da linha que não o inicio, (query entre virgulas))
    if [ -z "$linha_metadata" ]; then
    
        linha_metadata=$(grep ",$query," "$METADATA_FILE")
        
    fi
    
    
    if [ -z "$linha_metadata" ]; then
        
        echo ""
        echo -e "${RED}Erro: Nenhum ficheiro ou ID '$query' encontrado na recycle bin.${NC}"
        echo ""
        return 1
        
    fi
    
    
    IFS=',' read -r id name path date size type perms owner <<< "$linha_metadata"
    
    local file_path="$FILES_DIR/$id"
    
    local diretorio_destino
    diretorio_destino=$(dirname "$path")
    
    if [ ! -d "$diretorio_destino" ]; then
        
        echo ""
        echo -e "${YELLOW}O diretório original não existe. A criar...${NC}" 
        mkdir -p "$diretorio_destino" || { 
        
            echo -e "${RED}Erro: Falha ao criar o diretório de destino.${NC}" 
            return 1
            
        }
        
    fi
    
    
    if [ -e "$path" ]; then
    
        echo ""
        echo -e "${YELLOW}Já existe um ficheiro no local:${NC} $path"
        echo ""
        echo "Como deseja proceder ? "
        echo ""
        echo "[O]verwrite (substituir o ficheiro existente pelo restaurado)"
        echo "[R]enomear (restaurar o ficheiro com um nome diferente)"
        echo "[C]ancelar (cancelar a operação)"
        
        read -rp "Opção: " escolha
        
        case "$escolha" in
        
            [Oo]*)
            
                echo ""
                echo -e "${YELLOW}A substituir o ficheiro existente...${NC}"
                rm -rf "$path" # aqui tive mesmo de usar -rf para apagar tudo o que está dentro para sobrepor
                ;;
                
            [Rr]*)
            
                echo ""
                echo -e "${YELLOW}A restaurar com nome alternativo...${NC}"
                timestamp=$(date +%Y%m%d_%H%M%S)
                path="${diretorio_destino}/${name%.*}_restaurado_${timestamp}.${name##*.}"
                ;;
                
            [Cc]*)
            
                echo ""
                echo -e "${YELLOW}A cancelar a operação...${NC}"
                return 1
                ;;
                    
            *)
            
                echo ""
                echo -e "${YELLOW}Opção inválida. A cancelar operação...${NC}"
                return 1
                ;;
        esac
    fi
    
    
    # verificar espaço disponível antes de restaurar
    
    available_kb=$(df --output=avail "$diretorio_destino" | tail -n 1)
    file_kb=$((size / 1024))

    if [ "$file_kb" -gt "$available_kb" ]; then
        
        echo ""
        echo -e "${RED}Erro: Espaço insuficiente para restaurar '$name'.${NC}"
        return 1
        
    fi

    
    if ! mv "$file_path" "$path"; then
        
        echo ""
        echo -e "${RED}Erro: Não foi possível restaurar o ficheiro.${NC}"
        return 1
        
    fi
    
    # restaura as permissões que estavam na metadata
    if chmod "$perms" "$path"; then
        
        echo ""
        echo -e "${GREEN}Permissões restauradas:${NC} $perms"
        
    else
    
        echo ""
        echo -e "${YELLOW}Aviso: Não foi possível restaurar as permissões.${NC}"
        echo ""
        
    fi
    
    # apaga a linha do ficheiro que foi recuperado da metadata
    sed -i "/$id/d" "$METADATA_FILE"

    echo "$(date '+%Y-%m-%d %H:%M:%S') - Restaurado: $path (ID: $id)" >> "$LOG_FILE"
    
    echo ""
    echo -e "${GREEN}Ficheiro restaurado com sucesso:${NC} $path"
    echo ""
    return 0
    
}

#################################################
# Function: empty_recyclebin
# Description: Permanently deletes all items
# Parameters: None
# Returns: 0 on success
#################################################

empty_recyclebin() {
    
	if [ ! -d "$RECYCLE_BIN_DIR" ]; then
    
		echo -e "${RED}Erro: A recycle bin deve ser inicializada antes.${NC}"
        return 1
        
    fi

    local force_mode=false
    local file_id=""
    
    #Verifica se foi utilizada a --force flag
    for arg in "$@"; do
    
    	if [ "$arg" == "--force" ]; then
    	
    		force_mode=true
    		
    	else
    	
    		file_id="$arg"
    		
    	fi
    	
    done
    		
    #Apagar tudo se não for especificado ID
    if [ -z "$file_id" ]; then
    
    	local count=$(($(wc -l < "$METADATA_FILE") - 1))
    	
    	if [ "$count" -eq 0 ]; then
    	
    		echo -e "${YELLOW}O recycle bin já está vazio. ${NC}"
    		return 0
    		
    	fi
    	
    	echo -e "${YELLOW}Existem $count ficheiros no recycle bin.${NC}"
    	
    	if [ "$force_mode" = false ]; then
    	
    		read -p "Tem a certeza que quer apagar todos os ficheiros permanentemente? [Y/N]: " confirmation
    		#REGEX
    		if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
    		
    			echo -e "${YELLOW}Operação cancelada.${NC}"
    			return 0
    			
    		fi	
    	fi
    	
    	rm -rf "${FILES_DIR:?}/"*
    	echo "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER" > "$METADATA_FILE"
    	
    	echo "$(date '+%Y-%m-%d %H:%M:%S') - Recycle bin esvaziado (${count} ficheiros removidos)." >> "$LOG_FILE"
    	echo -e "${GREEN}Recycle bin esvaziado com sucesso (${count} ficheiros removidos).${NC}"
    	return 0
    fi
    
    
    #Apagar ficheiro especificado por ID
    
    local linha_metadata
    linha_metadata=$(tail -n +2 "$METADATA_FILE" | grep -F "$file_id," | grep "^$file_id," | head -n 1)

    
    if [ -z "$linha_metadata" ]; then
    
    	echo -e "${RED}Erro: ID '$file_id' não encontrado no recycle bin.${NC}"
    	return 1
    	
    fi
    
    
    IFS=',' read -r id name path date size type perms owner <<< "$linha_metadata"
    local file_path="$FILES_DIR/$id"
    
    if [ ! -e "$file_path" ]; then
    
    	echo -e "${YELLOW}Aviso: O ficheiro associado ao ID '$id' já não existe. A remover entrada da metadata...${NC}"
        grep -v "^$id," "$METADATA_FILE" > "$METADATA_FILE.tmp" && mv "$METADATA_FILE.tmp" "$METADATA_FILE"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Foi apagada metadata de ficheiro não existente na bin (ID: $id, Nome: $name)" >> "$LOG_FILE"
        return 0
    	
    fi
    
    
    if [ "$force_mode" = false ]; then
    
    	read -p "Tem a certeza que quer apagar permanentemente o ficheiro '$name'? [Y/N]: " confirmation
    	#REGEX
    	if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
    	
    		echo -e "${YELLOW}Operação cancelada.${NC}"
    		return 0
    		
    	fi	
    	
    fi
    
    
    rm -rf -- "$file_path"
    
    grep -v "^$id," "$METADATA_FILE" > "$METADATA_FILE.tmp" && mv "$METADATA_FILE.tmp" "$METADATA_FILE"
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Ficheiro removido permanentemente: $name (ID: $id)" >> "$LOG_FILE"
    echo -e "${GREEN}Ficheiro '$name' (ID: $id) removido com sucesso.${NC}"
    return 0
    
}

#################################################
# Function: search_recycled
# Description: Searches for files in recycle bin
# Parameters: $1 - search pattern
#			  $2 - case insensitive -i
# Returns: 0 on success
#################################################

search_recycled() {

    if [ ! -d "$RECYCLE_BIN_DIR" ]; then
    
		echo -e "${RED}Erro: A recycle bin deve ser inicializada antes.${NC}"
        return 1    
        
    fi


	if [ -z "$1" ]; then
	
		echo -e "${YELLOW}Utilização: ./recycle_bin.sh search <padrão>${NC}"
		return 1
		
	fi


    local pattern="$1"
	local grep_flags="-E"

	#Modo case insensitive -i
	if [ "$2" == "-i" ]; then
	
		grep_flags="-Ei"
		
	fi


	# Explicar os significados do REGEX
	# s/OLD/NEW/g

	local regex_pattern=$(echo "$pattern" | sed 's/\/./g')

	# tive de escrever isto para saltar o cabeçalho
	local matches=$( tail -n +2 "$METADATA_FILE" | grep ${grep_flags} -- "$regex_pattern")

	if [ -z "$matches" ]; then
	
		echo -e "${YELLOW}Nenhum ficheiro encontrado com esse padrão '$pattern'.${NC}"
		echo "$(date '+%Y-%m-%d %H:%M:%S') - Pesquisa sem resultados para: '$pattern'" >> "$LOG_FILE"
		return 0
		
	fi


	echo ""
	echo -e "${GREEN}Resultados da pesquisa para:${NC} '$pattern'"
	printf "%-20s %-20s %-55s %-20s %10s %-12s\n" "ID" "NOME" "CAMINHO ORIGINAL" "DATA" "TAM (B)" "TIPO"
	printf "%-20s %-25s %-55s %-20s %-10s %-12s\n" "--------------------" "-------------------------" "-------------------------------------------------------" "--------------------" "----------" "------------"
	

	while IFS=',' read -r id name path date size type perms owner; do
	
		printf "%-20s %-20s %-55s %-20s %-10s %-12s\n" "$id" "$name" "$path" "$date" "$size" "$type"
		
	done <<< "$matches"


	echo ""
	echo "$(date '+%Y-%m-%d %H:%M:%S') - Pesquisa realizada: '$pattern'" >> "$LOG_FILE"

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
    echo -e "  ${GREEN}init${NC}                   Inicializa a recycle bin e cria a estrutura necessária"
    echo -e "  ${GREEN}delete <ficheiro>${NC}      Move um ou vários ficheiros/diretórios para a recycle bin"
    echo -e "  ${GREEN}list${NC}                   Lista o conteúdo da recycle bin "
    echo -e "  ${GREEN}list --detailed${NC}        Lista o conteúdo da recycle bin no modo detalhado"
    echo -e "  ${GREEN}preview <id>${NC}           Mostra as primeiras 10 linhas de um ficheiro pelo seu id ou o tipo do ficheiro se for binário"
    echo -e "  ${GREEN}restore <id/filename>${NC}  Restaura um ficheiro eliminado para o local original"
    echo -e "  ${GREEN}search <filename/path>${NC} Procura ficheiros na recycle bin pelo nome ou pelo caminho"
    echo -e "  ${GREEN}empty${NC}                  Esvazia permanentemente a recycle bin após receber autorização"
	echo -e "  ${GREEN}empty --force${NC}          Esvazia permanentemente a recycle bin sem pedir autorização"
	echo -e "  ${GREEN}empty <id>${NC}             Apaga um ficheiro da recycle bin através do seu id e após receber autorização"
	echo -e "  ${GREEN}empty <id> --force${NC}     Apaga um ficheiro da recycle bin através do seu id sem receber autorização"
    echo -e "  ${GREEN}help${NC}                   Mostra esta mensagem de ajuda"
    echo ""
    echo -e "${YELLOW}Exemplos:${NC}"
    echo "  ./recycle_bin.sh init"
    echo "  ./recycle_bin.sh delete ~/teste_recyclebin/file1.txt"
    echo "  ./recycle_bin.sh list --detailed"
    echo "  ./recycle_bin.sh preview 176126081_glq9w9"
    echo "  ./recycle_bin.sh restore 176126081_glq9w9"
    echo "  ./recycle_bin.sh search .txt"
    echo "  ./recycle_bin.sh empty"
	echo "  ./recycle_bin.sh empty --force"
	echo "  ./recycle_bin.sh empty 176126081_glq9w9"
	echo "  ./recycle_bin.sh empty 176126081_glq9w9 --force"
    echo ""
    echo -e "${GREEN}==========================================================${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Ajuda foi mostrada no terminal." >> "$LOG_FILE"
    return 0
    
}

#################################################
# Function: show_statistics
# Description: Display statistics like number of files, total storage and average file size
# Parameters: None
# Returns: 1 if not sucessful, 0 if sucessful
#################################################




#################################################
# Function: auto_cleanup
# Description: Automatically delete items older then RETENTION_DAYS
# Parameters: None
# Returns: 1 if not sucessful, 0 if sucessful
#################################################

#################################################
# Function: check_quota
# Description: Check if recycle bin exceeds MAX_SIZE_MB
# Parameters: None
# Returns: 1 if not sucessful, 0 if sucessful
#################################################

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
    local linha_metadata=$(grep -F "$file_id," "$METADATA_FILE" | head -n 1)
    
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
    echo "$(date '+%Y-%m-%d %H:%M:%S') - O ficheiro de id $file_id foi previewed no terminal." >> "$LOG_FILE"
    return 0
}

#################################################
# Function: main
# Description: Main program logic
# Parameters: Command line arguments
# Returns: Exit code
#################################################

main() {
	
	#Ordenar main pela ordem
	# Initialize recycle bin
	initialize_recyclebin
    # Parse command line arguments
    case "$1" in
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
			shift
            restore_file "$@"
            ;;
            
        search)
			shift
            search_recycled "$@"
            ;;
            
        empty)
			shift
            empty_recyclebin "$@"
            ;;
            
        help|--help|-h)
            display_help
            ;;

		statistics)
			show_statistics
			;;

		cleanup)
			auto_cleanup
			;;

		quota)
			check_quota
			;;
        "")
			echo ""
			;;
		*)
            echo "Invalid option. Use 'help' for usage information."
            exit 1
            ;;
            
    esac
}

# Execute main function with all arguments
main "$@"


