#!/bin/bash
# ===========================================================
# Test Suite for Linux Recycle Bin System
# Authors: Pedro Gonçalves & David Monteiro
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
    $SCRIPT init > /dev/null
    assert_success "Recycle bin initialized successfully"
    [ -d "$HOME/Projeto01_SO/recycle_bin/files" ] && echo "✓ Directory structure created"
    [ -f "$HOME/Projeto01_SO/recycle_bin/metadata.db" ] && echo "✓ Metadata file created"
}

test_delete_single_file() {
    echo "=== Test: Delete Single File ==="
    setup
    $SCRIPT init > /dev/null
    echo "hello world" > "$TEST_DIR/file1.txt"
    $SCRIPT delete "$TEST_DIR/file1.txt" > /dev/null
    assert_success "Single file deleted successfully"
    [ ! -f "$TEST_DIR/file1.txt" ] && echo "✓ File removed from original location"
}

test_delete_multiple_files() {
    echo "=== Test: Delete Multiple Files ==="
    setup
    $SCRIPT init > /dev/null
    echo "a" > "$TEST_DIR/a.txt"
    echo "b" > "$TEST_DIR/b.txt"
    $SCRIPT delete "$TEST_DIR/a.txt" "$TEST_DIR/b.txt" > /dev/null
    assert_success "Multiple files deleted successfully"
}

test_delete_directory_recursive() {
    echo "=== Test: Delete Directory Recursively ==="
    setup
    $SCRIPT init > /dev/null
    mkdir -p "$TEST_DIR/folder/sub"
    echo "test" > "$TEST_DIR/folder/sub/file.txt"
    $SCRIPT delete "$TEST_DIR/folder" > /dev/null
    assert_success "Directory deleted recursively"
}

test_delete_nonexistent_file() {
    echo "=== Test: Delete Nonexistent File ==="
    setup
    $SCRIPT init > /dev/null
    $SCRIPT delete "$TEST_DIR/missing.txt" > /dev/null 2>&1
    assert_fail "Delete nonexistent file handled properly"
}

test_list_empty_bin() {
    echo "=== Test: List Empty Recycle Bin ==="
    setup
    $SCRIPT init > /dev/null
    $SCRIPT list | grep -q "Total de ficheiros: 0"
    assert_success "Empty recycle bin listed successfully"
}

test_list_with_items() {
    echo "=== Test: List With Items ==="
    setup
    $SCRIPT init > /dev/null
    echo "content" > "$TEST_DIR/file.txt"
    $SCRIPT delete "$TEST_DIR/file.txt" > /dev/null
    $SCRIPT list | grep -q "file.txt"
    assert_success "Recycle bin list shows deleted file"
}

test_restore_file_by_id() {
    echo "=== Test: Restore File (by ID) ==="
    setup
    $SCRIPT init > /dev/null
    echo "to restore" > "$TEST_DIR/restore_me.txt"
    $SCRIPT delete "$TEST_DIR/restore_me.txt" > /dev/null

    # apanha o ID real a partir do metadata.db
    ID=$(awk -F',' 'NR>1 && $2=="restore_me.txt" {print $1; exit}' "$HOME/Projeto01_SO/recycle_bin/metadata.db")

    # tenta restaurar pelo ID
    $SCRIPT restore "$ID" > /dev/null
    assert_success "File restored successfully using ID"
    [ -f "$TEST_DIR/restore_me.txt" ] && echo "✓ File restored to original location"
}

test_restore_file_by_name() {
    echo "=== Test: Restore File (by Name) ==="
    setup
    $SCRIPT init > /dev/null
    echo "restore by name" > "$TEST_DIR/restore_name.txt"
    $SCRIPT delete "$TEST_DIR/restore_name.txt" > /dev/null

    # tenta restaurar diretamente pelo nome
    $SCRIPT restore "restore_name.txt" > /dev/null
    assert_success "File restored successfully using filename"
    [ -f "$TEST_DIR/restore_name.txt" ] && echo "✓ File restored to original location"
}


test_restore_nonexistent_id() {
    echo "=== Test: Restore Nonexistent ID ==="
    setup
    $SCRIPT init > /dev/null
    $SCRIPT restore "fake_id_123" > /dev/null 2>&1
    assert_fail "Restore nonexistent ID handled properly"
}

test_search_existing_file() {
    echo "=== Test: Search Existing File ==="
    setup
    $SCRIPT init > /dev/null
    echo "abc" > "$TEST_DIR/a.txt"
    $SCRIPT delete "$TEST_DIR/a.txt" > /dev/null
    $SCRIPT search "a.txt" | grep -q "a.txt"
    assert_success "Search found existing file"
}

test_search_nonexistent_file() {
    echo "=== Test: Search Nonexistent File ==="
    setup
    $SCRIPT init > /dev/null
    $SCRIPT search "nothing" | grep -q "Nenhum ficheiro"
    assert_success "Search for nonexistent file handled correctly"
}

test_preview_file() {
    echo "=== Test: Preview File ==="
    setup
    $SCRIPT init > /dev/null
    echo -e "one\ntwo\nthree" > "$TEST_DIR/sample.txt"
    $SCRIPT delete "$TEST_DIR/sample.txt" > /dev/null
    ID=$(get_id_by_name "sample.txt")
    $SCRIPT preview "$ID" | grep -q "one"
    assert_success "Preview displays file contents"
}

test_empty_specific_file() {
    echo "=== Test: Empty Specific File ==="
    setup
    $SCRIPT init > /dev/null
    echo "unique" > "$TEST_DIR/unique.txt"
    $SCRIPT delete "$TEST_DIR/unique.txt" > /dev/null
    
    # Obtém o ID real do ficheiro a partir da metadata
    local file_id
    file_id=$(tail -n +2 "$METADATA_FILE" | grep "unique.txt" | cut -d',' -f1)
    
    $SCRIPT empty "$file_id" --force > /dev/null
    assert_success "Specific file removed with --force"
}


test_empty_all_force() {
    echo "=== Test: Empty All Files (--force) ==="
    setup
    $SCRIPT init > /dev/null
    echo "x" > "$TEST_DIR/x.txt"
    $SCRIPT delete "$TEST_DIR/x.txt" > /dev/null
    $SCRIPT empty --force > /dev/null
    assert_success "Recycle bin emptied using --force"
    $SCRIPT list | grep -q "Total de ficheiros: 0"
    assert_success "Recycle bin confirmed empty"
}

test_help_display() {
    echo "=== Test: Display Help ==="
    setup
    $SCRIPT help | grep -q "Uso:"
    assert_success "Help information displayed successfully"
}

test_invalid_command() {
    echo "=== Test: Invalid Command ==="
    setup
    $SCRIPT invalid_option > /dev/null 2>&1
    assert_fail "Invalid command handled correctly"
}

test_delete_hidden_file() {
    echo "=== Test: Delete Hidden File ==="
    setup
    $SCRIPT init > /dev/null
    echo "secret" > "$TEST_DIR/.hidden.txt"
    $SCRIPT delete "$TEST_DIR/.hidden.txt" > /dev/null
    $SCRIPT list | grep -q ".hidden.txt"
    assert_success "Hidden file deleted and listed successfully"
}

test_delete_with_spaces() {
    echo "=== Test: Delete File With Spaces ==="
    setup
    $SCRIPT init > /dev/null
    echo "spacey" > "$TEST_DIR/file with spaces.txt"
    $SCRIPT delete "$TEST_DIR/file with spaces.txt" > /dev/null
    assert_success "File with spaces deleted successfully"
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
test_delete_directory_recursive
test_delete_nonexistent_file
test_list_empty_bin
test_list_with_items
test_restore_file_by_id
test_restore_file_by_name
test_restore_nonexistent_id
test_search_existing_file
test_search_nonexistent_file
test_preview_file
test_empty_specific_file
test_empty_all_force
test_help_display
test_invalid_command
test_delete_hidden_file
test_delete_with_spaces

teardown

echo "==========================================="
echo "Results: $PASS passed, $FAIL failed"
echo "==========================================="

[ $FAIL -eq 0 ] && exit 0 || exit 1

