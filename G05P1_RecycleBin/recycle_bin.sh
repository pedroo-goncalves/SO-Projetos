#!/bin/bash

#################################################
# Script Header Comment
# Authors: Pedro Gonçalves 126463 & David Monteiro 125793
# Date: 31/10/2025
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
# Description: Initializes the recycle bin if it doesn't exist and creates its structure if any parts are missing.
# Parameters: None
# Returns: 0 on success, 1 on failure
#################################################

initialize_recyclebin() {
    
	# Check if the recycle bin directory exists
	# If it doesn't exist, we need to create its structure
    if [ ! -d "$RECYCLE_BIN_DIR" ]; then
        echo ""
        echo -e "${YELLOW}O recycle bin não existe atualmente.${NC}"

		# Create files folder
        mkdir -p "$FILES_DIR" || { echo "${RED}Ocorreu um erro ao inicializar o Recycle Bin.${NC}"; return 1; }

		# Create the metadata file if missing
    	if [ ! -f "$METADATA_FILE" ]; then
        	echo "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER" > "$METADATA_FILE"
    	fi

		# Create the config file if missing
    	if [ ! -f "$CONFIG_FILE" ]; then
        	echo "MAX_SIZE_MB=1024" > "$CONFIG_FILE"
        	echo "RETENTION_DAYS=30" >> "$CONFIG_FILE"
    	fi

		# Ensure log file exists
    	if [ ! -f "$LOG_FILE" ]; then
        	touch "$LOG_FILE"
    	fi
    
		# Display creation message and help message
		echo ""
    	echo -e "${GREEN}O Recycle Bin foi inicializado com sucesso no diretório: $RECYCLE_BIN_DIR ${NC}"
    	echo ""
    	echo -e "${RED}Bem vindo ao recycle bin, introduza o comando: './recycle_bin.sh help' para obter ajuda!${NC}"

    	# Initialize log file
    	echo "$(date '+%Y-%m-%d %H:%M:%S') - Recycle bin inicializado." >> "$LOG_FILE"
    fi
    

	

	# Ensure log file exists
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
    fi
    
    # Initialize log file
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Recycle bin inicializado." >> "$LOG_FILE"
}

#################################################
# Function: generate_unique_id
# Description: Generates unique ID for deleted files
# Parameters: None
# Returns: Prints unique ID to stdout
#################################################

generate_unique_id() {

	# Get current timestamp in seconds
    local timestamp=$(date +%s)

	# Generate a random 6-character alphanumeric string
    local random=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)

	# Combine both to form a unique ID
    echo "${timestamp}_${random}"
    
}

#################################################
# Function: delete_file
# Description: Moves file/directory to recycle bin
# Parameters: $@ - paths to one or more files/directories
# Returns: 0 on success, 1 on failure
#################################################

delete_file() {

	# Check if at least one (file/directory) was provided
    if [ $# -eq 0 ]; then
        echo -e "${YELLOW}Deve ser introduzido o nome ou diretório de pelo menos um ficheiro.${NC}"
        return 1
    fi

	# Checking multiple arguments
    for file in "$@"; do

		# Check if file/directory exists
        if [ ! -e "$file" ]; then
            echo -e "${YELLOW}O ficheiro/diretório '$file' não existe e não pode ser apagado.${NC}"
            return 1
            echo ""
            continue  
        fi

		# Prevent the deletion of recycle bin
        if [[ "$file" == "$RECYCLE_BIN_DIR"* ]]; then
            echo -e "${RED}Erro: Não podes eliminar o Recycle Bin.${NC}"
            return 1
            echo ""
            continue 
        fi

		# Get parent directory of target
        local parent_dir
        parent_dir=$(dirname "$file")

        # Check permissions on parent directory and file
        if [ ! -w "$parent_dir" ] || [ ! -x "$parent_dir" ] || [ ! -w "$file" ]; then
            echo -e "${RED}Erro: Sem permissões suficientes para apagar '$file'.${NC}"
            return 1
            echo ""     
            continue  
        fi

		# Function "generate_unique_id" call
        local id
        id=$(generate_unique_id)
        
		# Collect metadata about the file
        local original_name=$(basename "$file")
        local original_path=$(realpath "$file")
        local deletion_date=$(date "+%Y-%m-%d %H:%M:%S")
        local file_size=$(stat -c %s "$file")
        local permissions=$(stat -c %a "$file")
        local owner=$(stat -c %U:%G "$file")
        local dest_path="$FILES_DIR/$id"
        local file_type

		# Determine if its a file or directory
        if [ -d "$file" ]; then
            file_type="directory"  
        else
            file_type="file"  
        fi

        # Check available space
        available_kb=$(df --output=avail "$RECYCLE_BIN_DIR" | tail -n 1)
        file_kb=$((file_size / 1024))
        
        if [ "$file_kb" -gt "$available_kb" ]; then
            echo -e "${RED}Erro: Espaço insuficiente para mover '$file'.${NC}"
            return 1
            continue 
        fi

        # Recursive directory handling
        
		# If target is a directory, handle its contents
        if [ -d "$file" ]; then
            echo ""
            echo -e "${YELLOW}A apagar diretório de forma recursiva:${NC} $file"
            echo ""
            
			# Process each file/directory inside
            while IFS= read -r subitem; do
            
				# Function "generate_unique_id" call
                local sub_id=$(generate_unique_id)

				# Gather file info for metadata
                local sub_name=$(basename "$subitem")
                local sub_path=$(realpath "$subitem")
                local sub_date=$(date "+%Y-%m-%d %H:%M:%S")
                local sub_size=$(stat -c %s "$subitem")
                local sub_perms=$(stat -c %a "$subitem")
                local sub_owner=$(stat -c %U:%G "$subitem")

				# Identify type
                if [ -d "$subitem" ]; then
                    sub_type="directory"   
                else
                    sub_type="file" 
                fi

				# Move file or folder into the recycle bin
                sub_dest="$FILES_DIR/$sub_id"
                mv "$subitem" "$sub_dest"

				# Record metadata for such item
                echo "$sub_id,$sub_name,$sub_path,$sub_date,$sub_size,$sub_type,$sub_perms,$sub_owner" >> "$METADATA_FILE"

				# Log the deletion
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Apagado: $sub_path -> $sub_dest" >> "$LOG_FILE"
                
            done < <(find "$file" -depth)

			# Remove the original directory
            rm -rf "$file"
            echo -e "${GREEN}Diretório movido para o recycle bin:${NC} $original_name"
            echo ""
            continue

        fi

		# Now handle files
		# Try to move a single file into the recycle bin
        if ! mv "$file" "$dest_path"; then
            echo -e "${RED}Erro: Falha ao mover '$file'.${NC}"
            return
            echo ""
            continue
        fi

		# Save file information into metadata
        echo "$id,$original_name,$original_path,$deletion_date,$file_size,$file_type,$permissions,$owner" >> "$METADATA_FILE"
	
		# Record the operation in the log
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Apagado: $original_path -> $dest_path" >> "$LOG_FILE"

		# Show successful message
        echo -e "${GREEN}Movido com sucesso para o recycle bin:${NC} $original_name"

    done

    return 0
}

#################################################
# Function: format_size
# Description: Convert bytes into a human-readable format
# Parameters: $1 - size
# Returns: Prints human_readable size string to stdout
#################################################

format_size() {

	local size=$1
	local unit="B"

	# Conversion to the best unit by steps
	if [ "$size" -ge 1073741824 ]; then
		size=$((size / 1073741824))
		unit="GB"
	elif [ "$size" -ge 1048576 ]; then
		size=$((size / 1048576))
		unit="MB"
	elif [ "$size" -ge 1024 ]; then
		size=$((size / 1024))
		unit="KB"
	fi

	echo "$size $unit"
}

#################################################
# Function: list_recycled
# Description: Lists all items in recycle bin
# Parameters: $1 - [--detailed] (optional argument)
# Returns: 0 on success, 1 on failure
#################################################

list_recycled() {

    echo ""
    printf '%s\n' "-----------------------------=== Recycle Bin Contents ===--------------------------------"
    printf '%s\n' "-----------------------------------------------------------------------------------------"
    
	# Check for invalid number of arguments
    if [ "$#" -gt 1 ]; then
        echo -e "${RED}Erro: O comando foi introduzido incorretamente.${NC}"
        echo "Uso correto: ./recycle_bin.sh list --detailed"
        return 1
    fi
    
    # Default mode is non-detailed
    local mode="non_detailed"

    if [ -z "$1" ]; then
        mode="non_detailed" 
    elif [ "$1" = "--detailed" ]; then
        mode="detailed"  
    else
        echo -e "${RED}Erro: Argumento inválido: $1${NC}"
        echo "Uso correto: ./recycle_bin.sh list [--detailed]"
        return 1
    fi
    
    local total_files=0
    local total_size=0
    
	# Show simplified list
    if [ "$mode" = "non_detailed" ]; then
        local line=0
        printf "%-25s %-25s %-20s %-10s\n" "ID" "NOME" "DATA" "TAMANHO(B)"
        printf "%-25s %-25s %-20s %-10s\n" "-------------------------" "-------------------------" "--------------------" "----------------"
        
        while IFS=',' read -r id name path date size type perms owner; do
            
            ((line++))
            [ $line -eq 1 ] && continue
            printf "%-25s %-25s %-20s %-10s\n" "$id" "$name" "$date" "$size"
            
            ((total_files++))
            ((total_size+=size))
            
        done < "$METADATA_FILE"

    else
		
		# Show detailed table with contents
        line=0
        total_files=0
        total_size=0
        printf "%-20s %-20s %-55s %-17s %10s %-12s %-12s %-20s\n" \
        "ID" "NOME" "CAMINHO ORIGINAL" "DATA" "TAM(B)" "   TIPO" "   PERMISSÕES" "  OWNER"
        printf "%-20s %-20s %-55s %-20s %10s %-12s %-12s %-20s\n" \
        "--------------------" "--------------------" "-------------------------------------------------------" "--------------------" "----------" "------------" "------------" "--------------------"

        while IFS=',' read -r id name path date size type perms owner; do

            ((line++))
            [ $line -eq 1 ] && continue

            printf "%-20s %-20s %-55s %-20s %-10s %-12s %-12s %-20s\n" \
            "$id" "$name" "$path" "$date" "$size" "$type" "$perms" "$owner"

            ((total_files++))
            ((total_size+=size))

        done < "$METADATA_FILE"  
    fi

	# Convert total size to readable format
	local formatted_size
	formatted_size=$(format_size "$total_size")
    
	# Display totals and register operations in log file
    printf '%s\n' "-----------------------------------------------------------------------------------------"
    printf "Total de ficheiros: %d\n" "$total_files"
    printf "Tamanho total: %s %s\n" "$formatted_size"
    printf '%s\n' "-----------------------------------------------------------------------------------------"
    echo ""
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Ficheiros do recycle bin foram listados no terminal." >> "$LOG_FILE"
    return 0
}

#################################################
# Function: restore_file
# Description: Restores file from recycle bin
# Parameters: $1 - unique ID of file to restore
# Returns: 0 on success, 1 on failure
#################################################

restore_file() {

	# Ensure the user provides exactly one argument (in this case the ID or filename)
    if [ $# -ne 1 ]; then
        echo -e "${RED}Erro: O comando foi introduzido incorretamente.${NC}"
        echo "Uso correto: ./recycle_bin.sh restore <id/filename>"
        return 1
    fi
    
    local query="$1"
    
    # First try to match using ID ( which always appears at the start of the line )
    local metadata_line=$(tail -n +2 "$METADATA_FILE" | grep -F "$query," | head -n 1)


    
    # If there's no match by ID, try searching by filename instead
    if [ -z "$metadata_line" ]; then
        metadata_line=$(grep ",$query," "$METADATA_FILE") 
    fi
    
    # If not found, stop early and display error message
    if [ -z "$metadata_line" ]; then
        echo ""
        echo -e "${RED}Erro: Nenhum ficheiro ou ID '$query' encontrado no recycle bin.${NC}"
        echo ""
        return 1 
    fi
    
    # Split the metadata line into variables
    IFS=',' read -r id name path date size type perms owner <<< "$metadata_line"
    
    local file_path="$FILES_DIR/$id"
    
    local destination_dir
    destination_dir=$(dirname "$path")
    
	# Recreate original folder if it was deleted since removal
    if [ ! -d "$destination_dir" ]; then
        echo ""
        echo -e "${YELLOW}O diretório original não existe. A criar...${NC}" 
        mkdir -p "$destination_dir" || { 
            echo -e "${RED}Erro: Falha ao criar o diretório de destino.${NC}" 
            return 1   
        }   
    fi

	# Handle specific cases where another file already exists
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
				
				# Overwrite was chosen, so delete existing file before moving restore one
                echo ""
                echo -e "${YELLOW}A substituir o ficheiro existente...${NC}"
                rm -rf "$path" 
                ;;    
            [Rr]*)
				
				# Rename was chosen, so append timestamp to avoid overwriting
                echo ""
                echo -e "${YELLOW}A restaurar com nome alternativo...${NC}"
                timestamp=$(date +%Y%m%d_%H%M%S)
                path="${destination_dir}/${name%.*}_restored_${timestamp}.${name##*.}"
                ;;    
            [Cc]*)
            
				# Cancelled was chosen, stop restoring
                echo ""
                echo -e "${YELLOW}A cancelar a operação...${NC}"
                return 1
                ;;    
            *)
            	
				# Invalid Input
                echo ""
                echo -e "${YELLOW}Opção inválida. A cancelar operação...${NC}"
                return 1
                ;;
        esac
    fi
    
	# Check if there's enough disk space before restoring    
    available_kb=$(df --output=avail "$destination_dir" | tail -n 1)
    file_kb=$((size / 1024))

    if [ "$file_kb" -gt "$available_kb" ]; then
        echo ""
        echo -e "${RED}Erro: Espaço insuficiente para restaurar '$name'.${NC}"
        return 1
    fi

    # Move file back to its original location
    if ! mv "$file_path" "$path"; then 
        echo ""
        echo -e "${RED}Erro: Não foi possível restaurar o ficheiro.${NC}"
        return 1  
    fi
    
    # Restore original permissions from metadata
    if chmod "$perms" "$path"; then
        echo ""
        echo -e "${GREEN}Permissões restauradas:${NC} $perms" 
    else
        echo ""
        echo -e "${YELLOW}Aviso: Não foi possível restaurar as permissões.${NC}"
        echo ""   
    fi
    
    # Remove entry from metadata because it's not in the recycle bin anymore
    sed -i "/$id/d" "$METADATA_FILE"

	# Log the restore action
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Restaurado: $path (ID: $id)" >> "$LOG_FILE"
    
	# Display sucessful message
    echo ""
    echo -e "${GREEN}Ficheiro restaurado com sucesso:${NC} $path"
    echo ""
    return 0  
}

#################################################
# Function: empty_recyclebin
# Description: Permanently deletes all items with or without confirmation. It can permanently delete a single file by id with or without confirmation.
# Parameters: $@ - [file_id] and/or [--force] (optional arguments in any order)
# Returns: 0 on success, 1 on failure
#################################################

empty_recyclebin() {
    
    local force_mode=false
    local file_id=""
    
    # Check which mode was chosen ( confirmation or force)
	# Loop the arguments to allow the users to chose the order of such arguments
    for arg in "$@"; do
    	if [ "$arg" == "--force" ]; then
    		force_mode=true
    	else
    		file_id="$arg"
    	fi
    done
    		
    # If there's no specific ID, empty the whole recycle bin
    if [ -z "$file_id" ]; then
    
    	local count=$(($(wc -l < "$METADATA_FILE") - 1))
    	
		# Stop if it's already empty
    	if [ "$count" -eq 0 ]; then
    		echo -e "${YELLOW}O recycle bin já está vazio. ${NC}"
    		return 0
    	fi
    	
    	echo -e "${YELLOW}Existem $count ficheiros no recycle bin.${NC}"
    	
		# Confirm with the user before the deletion
    	if [ "$force_mode" = false ]; then
    	
    		read -p "Tem a certeza que quer apagar todos os ficheiros permanentemente? [Y/N]: " confirmation

    		# Continue only if user confirms with Y/y
    		if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
    			echo -e "${YELLOW}Operação cancelada.${NC}"
    			return 0
    		fi	
    	fi
    	
		# Remove all stored files and reset metadata
    	rm -rf "${FILES_DIR:?}/"*
    	echo "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER" > "$METADATA_FILE"
    	
		# Log the cleanup and display message
    	echo "$(date '+%Y-%m-%d %H:%M:%S') - Recycle bin esvaziado (${count} ficheiros removidos)." >> "$LOG_FILE"
    	echo -e "${GREEN}Recycle bin esvaziado com sucesso (${count} ficheiros removidos).${NC}"
    	return 0
    fi
    
    # Otherwise, only delete the file with the given ID 
    local metadata_line
    metadata_line=$(tail -n +2 "$METADATA_FILE" | grep -F "$file_id," | grep "^$file_id," | head -n 1)

    # If there's no match found, nothing is deleted 
    if [ -z "$metadata_line" ]; then
    	echo -e "${RED}Erro: ID '$file_id' não encontrado no recycle bin.${NC}"
    	return 1
    fi
    
    IFS=',' read -r id name path date size type perms owner <<< "$metadata_line"
    local file_path="$FILES_DIR/$id"
    
	# Handle missing file and clean metadata for consistency
    if [ ! -e "$file_path" ]; then
    	echo -e "${YELLOW}Aviso: O ficheiro associado ao ID '$id' já não existe. A remover entrada da metadata...${NC}"
        grep -v "^$id," "$METADATA_FILE" > "$METADATA_FILE.tmp" && mv "$METADATA_FILE.tmp" "$METADATA_FILE"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Foi apagada metadata de ficheiro não existente no bin (ID: $id, Nome: $name)" >> "$LOG_FILE"
        return 0
    fi
    
	# Confirm deletion unless force mode is triggered
    if [ "$force_mode" = false ]; then
    	read -p "Tem a certeza que quer apagar permanentemente o ficheiro '$name'? [Y/N]: " confirmation
    	if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
    		echo -e "${YELLOW}Operação cancelada.${NC}"
    		return 0
    	fi	
    fi
    
    # Permanently delete the file and update metadata
    rm -rf -- "$file_path"
    grep -v "^$id," "$METADATA_FILE" > "$METADATA_FILE.tmp" && mv "$METADATA_FILE.tmp" "$METADATA_FILE"
    
	# Log and display the confirmation of removal
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Ficheiro removido permanentemente: $name (ID: $id)" >> "$LOG_FILE"
    echo -e "${GREEN}Ficheiro '$name' (ID: $id) removido com sucesso.${NC}"
    return 0
}
#################################################
# Function: search_recycled
# Description: Searches for files in recycle bin
# Parameters: $1 - search pattern
#			  $2 - [case insensitive -i] (optional argument)
# Returns: 0 on success, 1 on failure
#################################################

search_recycled() {

	# Pattern required to perform a search
	if [ -z "$1" ]; then
		echo -e "${YELLOW}Utilização: ./recycle_bin.sh search <padrão>${NC}"
		return 1
	fi

    local pattern="$1"
	local ignore_case=false

	# Allow case-insensitive mode if user passes -i
	if [ "$2" == "-i" ]; then
		ignore_case=true
	fi

	# Ensure metadata file exists
	if [ ! -f "$METADATA_FILE" ]; then
		echo -e "${RED}Erro: metadata.db não encontrado.${NC}"
		return 1
	fi

	# Header for results
	echo ""
	echo -e "${GREEN}Resultados da pesquisa para:${NC} '$pattern'"
	echo "---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
	printf "%-20s %-30s %-80s %-20s %10s %-10s\n" \
    "ID" "NOME" "CAMINHO ORIGINAL" "DATA" "TAM (B)" "TIPO"
	printf "%-20s %-30s %-80s %-20s %10s %-10s\n" \
    "--------------------" "------------------------------" "--------------------------------------------------------------------------------" "--------------------" "----------" "----------"
	echo "---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
	local found=false

	# Read metadata file ignoring header
	while IFS=',' read -r id name path date size type perms owner; do
		
		# Combine name and original path for searching
		local fulltext="$name $path"

		# Use grep -q -E for quiet extended-regex matching
		# Add flag -i when ignore_case is true
		if $ignore_case; then
			echo "$fulltext" | grep -iq -E -- "$pattern"
		else
			echo "$fulltext" | grep -q -E -- "$pattern"
		fi

		# If there's a match, print the formatted line and mark as found
		if [ $? -eq 0 ]; then
			printf "%-20.20s %-30.30s %-80.80s %-20.20s %10s %-10.10s\n" \ "$id" "$name" "$path" "$date" "$size" "$type"
			found=true
		fi

	done < <(tail -n +2 "$METADATA_FILE")

	# If no matches found, inform the user and log
	if [ "$found" = false ]; then
		echo -e "${YELLOW}Nenhum ficheiro encontrado com esse padrão '$pattern'.${NC}"
		echo "$(date '+%Y-%m-%d %H:%M:%S') - Pesquisa sem resultados para: '$pattern'" >> "$LOG_FILE"
	else
		echo "---------------------------------------------------------------------------------------------------------------"
		echo ""
		echo "$(date '+%Y-%m-%d %H:%M:%S') - Pesquisa realizada: '$pattern'" >> "$LOG_FILE"
	fi

	return 0
}
#################################################
# Function: show_statistics
# Description: Display statistics like number of files, total storage and average file size
# Parameters: None
# Returns: 0 on success, 1 on failure
#################################################

show_statistics() {

	# Ensure metadata file exists and is readable
	if [ ! -r "$METADATA_FILE" ]; then
		echo -e "${RED}Erro: Ficheiro metadata.db não encontrado ou sem permissões"
	fi

	# Count total items, total size, number of files and directories
	local total_counter=$(awk -F, 'NR>1 {counter++} END {print counter+0}' "$METADATA_FILE")
	local total_size=$(awk -F, 'NR>1 {size+=$5} END {print size+0}' "$METADATA_FILE")
	local files_counter=$(awk -F, 'NR>1 && $6=="file" {counter++} END {print counter+0}' "$METADATA_FILE")
	local directories_counter=$(awk -F, 'NR>1 && $6=="directory" {counter++} END {print counter+0}' "$METADATA_FILE")
    	
	# If the recycle bin is empty stop early
    if [ "$total_counter" -eq 0 ]; then
    	echo -e "${YELLOW}O recycle bin está vazio. ${NC}"
    	return 0	
    fi

	# Find the oldest and most recent files by deletion date
	local oldest_line=$(tail -n +2 "$METADATA_FILE" | sort -t, -k4,4 | head -n1)
	local newest_line=$(tail -n +2 "$METADATA_FILE" | sort -t, -k4,4 | tail -n1)
	
	local oldest_date=$(printf '%s' "$oldest_line" | cut -d',' -f4)
	local oldest_name=$(printf '%s' "$oldest_line" | cut -d',' -f2)
	local oldest_id=$(printf '%s' "$oldest_line" | cut -d',' -f1)

	local newest_date=$(printf '%s' "$newest_line" | cut -d',' -f4)
	local newest_name=$(printf '%s' "$newest_line" | cut -d',' -f2)
	local newest_id=$(printf '%s' "$newest_line" | cut -d',' -f1)

	# Calculate average without dividing by zero
	if [ ! "$total_counter" -eq 0 ]; then
		local average_size=$(( "$total_size" / "$total_counter"))
	else
		local average_size=0
	fi
	
	# Read maximum allowed size form config and calculate usage percentage
	local MAX_SIZE_MB=$(grep "MAX_SIZE_MB" "$CONFIG_FILE" | cut -d'=' -f2)
	local max_bytes=$(( "$MAX_SIZE_MB" * 1024 * 1024))

	local quota_percent=$(awk -v used="$total_size" -v max="$max_bytes" 'BEGIN { printf "%.2f", (used/max)*100 }')


	# Function format_size call to convert all sizes
	local formatted_total_size
	formatted_total_size=$(format_size "$total_size")

	local formatted_average_size
	formatted_average_size=$(format_size "$average_size")

	# Output Results
	echo ""
	echo -e "${GREEN}=== Estatísticas do Recycle Bin ===${NC}"
	printf "%-15s : %-15s\n" "Total de itens" "$total_counter"
    printf "%-15s : %-15s\n" "Número de ficheiros" "$files_counter"
    printf "%-15s : %-15s\n" "Número de diretórios" "$directories_counter"
    printf "%-15s : %-15s\n" "Ficheiro mais antigo" "$oldest_name / $oldest_id / $oldest_date"
    printf "%-15s : %-15s\n" "Ficheiro mais recente" "$newest_name / $newest_id / $newest_date"
    printf "%-15s : %-15s\n" "Tamanho total" "$formatted_total_size"
    printf "%-15s : %-15s\n" "Tamanho médio" "$formatted_average_size"
    printf "%-15s : %-15s\n" "Quota usada" "$quota_percent %"
	echo -e "${GREEN}=============================================================={NC}"
	echo ""

	# Log operation
	echo "$(date '+%Y-%m-%d %H:%M:%S') - Estatísticas do recycle bin mostradas." >> "$LOG_FILE"
	return 0
}
#################################################
# Function: auto_cleanup
# Description: Automatically delete items older then RETENTION_DAYS
# Parameters: None
# Returns: 0 on success, 1 on failure
#################################################

auto_cleanup() {

	# Check config file existence and if is readable
	if [ ! -r "$CONFIG_FILE" ]; then
		echo -e "${RED}Erro: O ficheiro de configuração não foi encontrado ou não tem permissões.${NC}"
		return 1
	fi

	# Read retention period from config file
	local retention_days=$(grep "RETENTION_DAYS" "$CONFIG_FILE" | cut -d'=' -f2)

	# If not defined or invalid terminate the operation
	if [ -z "$retention_days" ] || ! [[ "$retention_days" =~ ^[0-9]+$ ]]; then
		echo -e "${RED}Erro: A variavél RETENTION_DAYS não foi definida corretamente em '$CONFIG_FILE'.${NC}"
		return 1
	fi

	# Display Auto-cleanup success message:
	echo -e "${GREEN}Limpeza Automática: A remover ficheiros mais antigos segundo o prazo estabelecido $retention_days dias...${NC}"

	# Calculate cutoff date
	local cutoff_date
	cutoff_date=$(date -d "-${retention_days} days" +"%Y-%m-%d")

	# Find IDs of files with deletion date older than cutoff
	local old_files
	old_files=$(awk -F, -v cutoff="$cutoff_date" 'NR>1 && $4 < cutoff {print $1}' "$METADATA_FILE")

	# If there are no files stop 
	if [ -z "$old_files" ]; then
		echo -e "${YELLOW}Nenhum ficheiro excedeu o período de retenção.${NC}"
		return 0
	fi

	local deleted_counter=0
	
	# Loop through each old file ID and remove it
	for id in $old_files; do
		local file_path="$FILES_DIR/$id"

		if [ -e "$file_path" ]; then
			rm -rf -- "$file_path"
			((deleted_counter++))
		fi

		# Remove metadata entry for each of those files
		grep -v "^$id," "$METADATA_FILE" > "$METADATA_FILE.tmp" && mv "$METADATA_FILE.tmp" "$METADATA_FILE"
	done

	# Log and summarize cleanup
	echo "$(date '+%Y-%m-%d %H:%M:%S') - Limpeza automática removeu $deleted_counter ficheiros mais antigos segundo o prazo estabelecido $retention_days dias">> "$LOG_FILE"
	echo -e "${GREEN}Limpeza automática concluída: $deleted_counter ficheiros removidos.${NC}"
	echo ""
	return 0
}

#################################################
# Function: check_quota
# Description: Check if recycle bin exceeds MAX_SIZE_MB
# Parameters: None
# Returns: 0 on success, 1 on failure
#################################################

check_quota() {

	# Check config file existence and if is readable
	if [ ! -r "$CONFIG_FILE" ]; then
		echo -e "${RED}Erro: O ficheiro de configuração não foi encontrado ou não tem permissões.${NC}"
		return 1
	fi

	# Read MAX_SIZE_MB from config file
	local max_size_mb=$(grep "MAX_SIZE_MB" "$CONFIG_FILE" | cut -d'=' -f2)

	# If not defined or invalid terminate the operation
	if [ -z "$max_size_mb" ] || ! [[ "$max_size_mb" =~ ^[0-9]+$ ]]; then
		echo -e "${RED}Erro: A variavél MAX_SIZE_MB não foi definida corretamente em '$CONFIG_FILE'.${NC}"
		return 1
	fi

	local max_bytes=$(( max_size_mb * 1024 * 1024 ))

	# Calculate total size of files in recycle bin
	local total_size
	total_size=$(awk -F, 'NR>1 {sum+=$5} END {print sum+0}' "$METADATA_FILE")

	local readable_size
	readable_size=$(format_size "$total_size")
	local readable_quota
	readable_quota=$(format_size "$max_bytes")

	# Compare total size with quota
	if [ "$total_size" -gt "$max_bytes" ]; then
		echo -e "${YELLOW}Aviso: O Recycle bin excedeu o limite de $readable_quota. Tamanho atual: $readable_size.${NC}"	
		# Log the operation for exceding quota
		echo "$(date '+%Y-%m-%d %H:%M:%S') A Quota foi excedida: $readable_size usado, limite $readable_quota."  >> "$LOG_FILE"

		# Trigger auto cleanup
		echo -e "${YELLOW}A executar limpeza automática...${NC}"
		auto_cleanup
	else
		echo -e "${GREEN}O Recycle bin está dentro do limite de $max_size_mb MB.${NC}"

		# Log the operation for a positive scenario
	echo "$(date '+%Y-%m-%d %H:%M:%S') Verificação da quota OK: $readable_size usado, limite $readable_quota" >> "$LOG_FILE"	
	fi
	return 0
}
#################################################
# Function: preview_file
# Description: Displays the first 10 lines of the selected file in the recycle bin.
# Parameters: $1 - file ID
# Returns: 0 on success, 1 on failure
#################################################

preview_file() {
    
	# Ensure exactly one argument is provided (file ID)
    if [ $# -ne 1 ]; then
        echo -e "${RED}Deve ser inserido o id ou o nome do ficheiro no recycle bin como argumento.${NC}"
        return 1 
    fi
    
    local file_id=$1

	# Retrive the metadata line for the given ID
    local metadata_line=$(grep -F "$file_id," "$METADATA_FILE" | head -n 1)
    
	# Stop if the ID was not found in metadata
    if [ -z "$metadata_line" ]; then
        echo -e "${RED}Erro: ID '$file_id' não encontrado no recycle bin.${NC}"
        return 1
    fi
    
    # Parse metadata into variables
    IFS=',' read -r id name path date size type perms owner <<< "$metadata_line"
    local file_path="$FILES_DIR/$id"
    
    # Stop if the path points to a directory which can not be previewed
    if [ -d "$file_path" ]; then
        echo -e "${YELLOW}'$name' é um diretório, não um ficheiro.${NC}"
        return 0
    fi

	# Stop if file does not exist in the recycle bin
    if [ ! -e "$file_path" ]; then
        echo -e "${RED}Erro: Ficheiro '$name' não encontrado no diretório do recycle bin.${NC}"
        return 1
    fi
    
    # Stop if file is empty
    if [ ! -s "$file_path" ]; then
        echo -e "${YELLOW}O ficheiro está vazio.${NC}"
        return 0 
    fi

    # Display header for preview
    echo -e "${GREEN}Pré-visualizar ficheiro:${NC} $name"
    echo "-----------------------------------------------"

	# Determine file type to handle text or binary
    file_type=$(file "$file_path")

	# Preview text files; otherwise show file type
    case "$file_type" in
        *text*)
            head -n 10 "$file_path" # Display first 10 lines
            ;; 
        *)
            echo "$file_type" # Show file type for non-text files
            ;;
    esac

    # Display footer and log the preview operation
    echo "-----------------------------------------------"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - O ficheiro de id $file_id foi pré-visualizado no terminal." >> "$LOG_FILE"
    return 0
}

#################################################
# Function: display_help
# Description: Shows usage information
# Parameters: None
# Returns: 0 on success
#################################################

display_help() {

    echo ""
    echo -e "${GREEN}==================== Recycle Bin Help ======================${NC}"
    echo ""
    echo -e "${YELLOW}Uso:${NC}  ./recycle_bin.sh [opção] [argumentos]"
    echo ""
    echo -e "${YELLOW}Opções disponíveis:${NC}"
    echo -e "  ${GREEN}delete <ficheiro>${NC}      		Move um ou vários ficheiros/diretórios para o recycle bin"
    echo -e "  ${GREEN}list${NC}                   		Lista o conteúdo do recycle bin "
    echo -e "  ${GREEN}list --detailed${NC}        		Lista o conteúdo do recycle bin no modo detalhado"
    echo -e "  ${GREEN}restore <id/filename>${NC}  		Restaura um ficheiro eliminado para o local original"
    echo -e "  ${GREEN}search <filename/path>${NC} 		Procura ficheiros no recycle bin pelo nome ou pelo caminho"
	echo -e "  ${GREEN}search <filename/path> -i${NC} 		Procura ficheiros no recycle bin pelo nome ou pelo caminho sem fazer distinção entre maiúsculas e minúsculas"
	echo -e "  ${GREEN}search <pattern>${NC} 			Procura ficheiros no recycle bin através de um padrão (tipo de ficheiro como por exemplo .txt)"
    echo -e "  ${GREEN}empty${NC}                  		Esvazia permanentemente todo o recycle bin após receber autorização"
	echo -e "  ${GREEN}empty --force${NC}          		Esvazia permanentemente todo o recycle bin sem pedir autorização"
	echo -e "  ${GREEN}empty <id>${NC}             		Elimina um ficheiro do recycle bin através do seu id e após receber autorização"
	echo -e "  ${GREEN}empty <id> --force${NC}     		Elimina um ficheiro do recycle bin através do seu id sem receber autorização"
	echo -e "  ${GREEN}statistics${NC}             		Mostra algumas estatísticas adicionais sobre o recycle bin"
	echo -e "  ${GREEN}cleanup${NC}                		Apaga automaticamente ficheiros/diretórios mais antigos que o período de retenção"
	echo -e "  ${GREEN}quota${NC}                  		Verifica se o recycle bin excedeu o tamanho máximo permitido"
	echo -e "  ${GREEN}preview <id>${NC}           		Mostra as primeiras 10 linhas de um ficheiro pelo seu id ou o tipo do ficheiro se for binário"
    echo -e "  ${GREEN}help${NC}                   		Mostra esta mensagem de ajuda"
    echo ""
    echo -e "${YELLOW}Exemplos:${NC}"
    echo "  ./recycle_bin.sh delete ~/teste_recyclebin/file1.txt"
	echo "  ./recycle_bin.sh list"
    echo "  ./recycle_bin.sh list --detailed"
	echo "  ./recycle_bin.sh restore 176126081_glq9w9"
    echo "  ./recycle_bin.sh search file1"
	echo "  ./recycle_bin.sh search FILE1 -i"
	echo "  ./recycle_bin.sh search .txt"
    echo "  ./recycle_bin.sh empty"
	echo "  ./recycle_bin.sh empty --force"
	echo "  ./recycle_bin.sh empty 176126081_glq9w9"
	echo "  ./recycle_bin.sh empty 176126081_glq9w9 --force"
	echo "  ./recycle_bin.sh statistics"
	echo "  ./recycle_bin.sh cleanup"
	echo "  ./recycle_bin.sh quota"
	echo "  ./recycle_bin.sh preview 176126081_glq9w9"
	echo "  ./recycle_bin.sh help"
    echo ""
    echo -e "${GREEN}==========================================================${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Ajuda foi mostrada no terminal." >> "$LOG_FILE"
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

	# If no argument is passed it just initializes the recycle bin
	if [ $# -eq 0 ]; then
		echo ""
		echo -e "${YELLOW}Recycle bin já inicializado${NC}"
		echo ""
		exit 0	
	fi

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
            echo "Opção Inválida. Utilize 'recycle_bin.sh help' para obter informações de utilização."
            exit 1
            ;;  
    esac
}

# Execute main function with all arguments
main "$@"


