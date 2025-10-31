#!/bin/bash
# ===========================================================
# Test Suite for Linux Recycle Bin System
# Authors: Pedro Miguel Morais Gonçalves (126463) & David Saraiva Monteiro (125793)
# ===========================================================

SCRIPT="./recycle_bin.sh"
TEST_DIR="test_data"
PASS=0
FAIL=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ===========================================================
# Helper Functions
# ===========================================================

setup() {
    rm -rf "$HOME/Projeto01_SO_G05P1/recycle_bin"
    mkdir -p "$TEST_DIR"
}

teardown() {
    rm -rf "$TEST_DIR"
    rm -rf "$HOME/Projeto01_SO_G05P1/recycle_bin"
}

assert_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $1"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC}: $1"
        ((FAIL++))
    fi
}

assert_fail() {
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $1"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC}: $1"
        ((FAIL++))
    fi
}

get_id_by_name() {
  local name="$1"
  local meta="$HOME/Projeto01_SO_G05P1/recycle_bin/metadata.db"
  awk -F',' -v n="$name" 'NR>1 && $2==n {print $1; exit}' "$meta"
}


# ===========================================================   
# Test Cases
# ===========================================================

test_init() {
    echo "=== Test: Initialization ==="
    setup
    bash recycle_bin.sh > /dev/null
    assert_success "Recycle bin initialized successfully"
    [ -d "$HOME/Projeto01_SO_G05P1/recycle_bin/files" ] && echo "✓ Directory structure created"
    [ -f "$HOME/Projeto01_SO_G05P1/recycle_bin/metadata.db" ] && echo "✓ Metadata file created"
}

test_delete_single_file() {
    echo "=== Test: Delete Single File ==="
    setup
    
    echo "hello world" > "$TEST_DIR/file1.txt"
    $SCRIPT delete "$TEST_DIR/file1.txt" > /dev/null
    assert_success "Single file deleted successfully"
    [ ! -f "$TEST_DIR/file1.txt" ] && echo "✓ File removed from original location"
}

test_delete_multiple_files() {
    echo "=== Test: Delete Multiple Files ==="
    setup
    
    echo "a" > "$TEST_DIR/a.txt"
    echo "b" > "$TEST_DIR/b.txt"
    $SCRIPT delete "$TEST_DIR/a.txt" "$TEST_DIR/b.txt" > /dev/null
    assert_success "Multiple files deleted successfully"
}

test_delete_empty_directory() {
    echo "=== Test: Delete Empty Directory ==="
    setup
    
    mkdir -p "$TEST_DIR/empty_folder"
    $SCRIPT delete "$TEST_DIR/empty_folder" > /dev/null
    assert_success "Empty directory deleted successfully"
    [ ! -d "$TEST_DIR/empty_folder" ] && echo "✓ Empty directory removed from original location"
}

test_delete_directory_recursive() {
    echo "=== Test: Delete Directory Recursively ==="
    setup
    
    mkdir -p "$TEST_DIR/folder/sub"
    echo "test" > "$TEST_DIR/folder/sub/file.txt"
    $SCRIPT delete "$TEST_DIR/folder" > /dev/null
    assert_success "Directory deleted recursively"
}

test_list_empty_bin() {
    echo "=== Test: List Empty Recycle Bin ==="
    setup
    
    $SCRIPT list | grep -q "Total de ficheiros: 0"
    assert_success "Empty recycle bin listed successfully"
}

test_list_with_items() {
    echo "=== Test: List With Items ==="
    setup
    
    echo "content" > "$TEST_DIR/file.txt"
    $SCRIPT delete "$TEST_DIR/file.txt" > /dev/null
    $SCRIPT list | grep -q "file.txt"
    assert_success "Recycle bin list shows deleted file"
}

test_restore_single_file_by_id() {
    echo "=== Test: Restore File (by ID) ==="
    setup
    
    echo "to restore" > "$TEST_DIR/restore_me.txt"
    $SCRIPT delete "$TEST_DIR/restore_me.txt" > /dev/null

    # apanha o ID real a partir do metadata.db
    ID=$(awk -F',' 'NR>1 && $2=="restore_me.txt" {print $1; exit}' "$HOME/Projeto01_SO_G05P1/recycle_bin/metadata.db")

    $SCRIPT restore "$ID" > /dev/null
    assert_success "File restored successfully using ID"
    [ -f "$TEST_DIR/restore_me.txt" ] && echo "✓ File restored to original location"
}

test_restore_file_by_name() {
    echo "=== Test: Restore File (by Name) ==="
    setup
    
    echo "restore by name" > "$TEST_DIR/restore_name.txt"
    $SCRIPT delete "$TEST_DIR/restore_name.txt" > /dev/null

    $SCRIPT restore "restore_name.txt" > /dev/null
    assert_success "File restored successfully using filename"
    [ -f "$TEST_DIR/restore_name.txt" ] && echo "✓ File restored to original location"
}

test_restore_to_nonexistent_original_path() {
    echo "=== Test: Restore to Nonexistent Original Path ==="
    setup

    mkdir -p "$TEST_DIR/olddir"
    echo "dados" > "$TEST_DIR/olddir/x.txt"

    $SCRIPT delete "$TEST_DIR/olddir/x.txt" > /dev/null
    assert_success "File deleted successfully"

    rm -rf "$TEST_DIR/olddir"

    $SCRIPT restore "x.txt" > restore_output.txt 2>&1

    grep -q "O diretório original não existe. A criar..." restore_output.txt && echo "✓ Message displayed correctly"
    [ -d "$TEST_DIR/olddir" ] && echo "✓ Directory recreated successfully"
    [ -f "$TEST_DIR/olddir/x.txt" ] && echo "✓ File restored successfully"

    local METADATA_FILE="$HOME/Projeto01_SO_G05P1/recycle_bin/metadata.db"
    ! grep -q "x.txt" "$METADATA_FILE" && echo "✓ Metadata entry removed"

    assert_success "Restore to nonexistent original path handled correctly"
}

test_empty_all_force() {
    echo "=== Test: Empty All Files (--force) ==="
    setup
    
    echo "x" > "$TEST_DIR/x.txt"
    $SCRIPT delete "$TEST_DIR/x.txt" > /dev/null
    $SCRIPT empty --force > /dev/null
    assert_success "Recycle bin emptied using --force"
    $SCRIPT list | grep -q "Total de ficheiros: 0"
    assert_success "Recycle bin confirmed empty"
}

test_restore_nonexistent_id() {
    echo "=== Test: Restore Nonexistent ID ==="
    setup
    
    $SCRIPT restore "fake_id_123" > /dev/null 2>&1
    assert_fail "Restore nonexistent ID handled properly"
}

test_search_existing_file() {
    echo "=== Test: Search Existing File ==="
    setup
    
    echo "abc" > "$TEST_DIR/a.txt"
    $SCRIPT delete "$TEST_DIR/a.txt" > /dev/null
    $SCRIPT search "a.txt" | grep -q "a.txt"
    assert_success "Search found existing file"
}

test_search_nonexistent_file() {
    echo "=== Test: Search Nonexistent File ==="
    setup
    
    $SCRIPT search "nothing" | grep -q "Nenhum ficheiro"
    assert_success "Search for nonexistent file handled correctly"
}

test_help_display() {
    echo "=== Test: Display Help ==="
    setup
    $SCRIPT help | grep -q "Uso:"
    assert_success "Help information displayed successfully"
}

test_preview_file() {
    echo "=== Test: Preview File ==="
    setup
    
    echo -e "one\ntwo\nthree" > "$TEST_DIR/sample.txt"
    $SCRIPT delete "$TEST_DIR/sample.txt" > /dev/null
    ID=$(get_id_by_name "sample.txt")
    $SCRIPT preview "$ID" | grep -q "one"
    assert_success "Preview displays file contents"
}

test_show_statistics() {
    echo "=== Test: Show Statistics ==="
    setup

    # inicializa automaticamente a estrutura
    bash recycle_bin.sh > /dev/null

    echo "A" > "$TEST_DIR/a.txt"
    echo "B" > "$TEST_DIR/b.txt"

    $SCRIPT delete "$TEST_DIR/a.txt" > /dev/null
    $SCRIPT delete "$TEST_DIR/b.txt" > /dev/null

    $SCRIPT statistics > stats_output.txt
    assert_success "Statistics displayed successfully"

    grep -q "Estatísticas do Recycle Bin" stats_output.txt && echo "✓ Statistics header displayed"
    grep -q "Total de itens" stats_output.txt && echo "✓ Total count displayed"
    grep -q "Tamanho total" stats_output.txt && echo "✓ Size displayed"
}

test_auto_cleanup() {
    echo "=== Test: Auto Cleanup ==="
    setup

    # inicializa automaticamente a estrutura
    bash recycle_bin.sh > /dev/null

    # substitui os valores do ficheiro config
    sed -i 's/^RETENTION_DAYS=.*/RETENTION_DAYS=0/' "$HOME/Projeto01_SO_G05P1/recycle_bin/config"
    sed -i 's/^MAX_SIZE_MB=.*/MAX_SIZE_MB=100/' "$HOME/Projeto01_SO_G05P1/recycle_bin/config"

    echo "old data" > "$TEST_DIR/old.txt"
    $SCRIPT delete "$TEST_DIR/old.txt" > /dev/null

    $SCRIPT cleanup > cleanup_output.txt
    assert_success "Auto cleanup executed successfully"

    grep -q "Limpeza Automática" cleanup_output.txt && echo "✓ Cleanup process started"
    grep -q "Limpeza automática concluída" cleanup_output.txt && echo "✓ Cleanup completed message"
}


test_check_quota() {

    echo "=== Test: Check Quota ==="
    setup

    # inicializa automaticamente a estruturaS
    bash recycle_bin.sh > /dev/null

    # substitui os valores do ficheiro config
    sed -i 's/^MAX_SIZE_MB=.*/MAX_SIZE_MB=1/' "$HOME/Projeto01_SO_G05P1/recycle_bin/config"
    sed -i 's/^RETENTION_DAYS=.*/RETENTION_DAYS=30/' "$HOME/Projeto01_SO_G05P1/recycle_bin/config"

    dd if=/dev/zero of="$TEST_DIR/bigfile.bin" bs=1M count=2 > /dev/null 2>&1
    $SCRIPT delete "$TEST_DIR/bigfile.bin" > /dev/null

    $SCRIPT quota > quota_output.txt
    assert_success "Quota check executed successfully"

    grep -q "Aviso: O Recycle bin excedeu o limite" quota_output.txt && echo "✓ Quota exceeded warning displayed"
    
}

# ===========================================================
# Run All Tests
# ===========================================================

echo "==========================================="
echo "     Linux Recycle Bin Automated Tests"
echo "==========================================="

test_init
test_delete_single_file
test_delete_multiple_files
test_delete_empty_directory
test_delete_directory_recursive
test_list_empty_bin
test_list_with_items
test_restore_single_file_by_id
test_restore_file_by_name
test_restore_to_nonexistent_original_path
test_empty_all_force
test_search_existing_file
test_search_nonexistent_file
test_help_display
test_preview_file
test_show_statistics
test_auto_cleanup
test_check_quota

echo "==========================================="
echo "Results: $PASS passed, $FAIL failed"
echo "==========================================="

[ $FAIL -eq 0 ] && exit 0 || exit 1


