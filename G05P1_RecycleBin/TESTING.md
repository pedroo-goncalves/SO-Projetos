# Linux Recycle Bin System

## Authors

Pedro Miguel Morais Gonçalves
126463
&
David Saraiva Monteiro 
125793

## Test Plan overview

O nosso plano de testes consiste em testar as funções principais e obrigatórias primeiro e só depois testar as funções opcionais. As funções serão testadas pela ordem estabelecida nos requisitos (Secção Features no documento README.md) para evitar possíveis erros derivados de dependências entre funções. Em primeiro lugar, decorrerão os testes das "Funcionalidades Básicas"/"Basic Functionalities" tanto das funções principais como das funções opcionais. Em segundo lugar, vamos testar os "Casos Extremos"/"Edge Cases" associados às diferentes funções. Em terceiro lugar, será feito o "Tratamento de Erros"/"Error Handling" para verificar se as mensagens de erro foram bem implementadas. Por último, terão lugar os "Testes de Performance"/"Performance Tests" para verificar o modo como o sistema lida com ficheiros maiores e operações mais complexas. É preciso mencionar que ada função terá um ou vários cenários de teste para cobrir todas as possibilidades de chamar as funções com diferentes argumentos e flags predefinidas. O script deve ser sempre testado no seguinte diretório "/home/user/Projeto01_SO/G05P1_RecycleBin" (ver regras de instalação no documento README.md).

## Test cases with results

### Test Case 1: Initialize recycle bin structure
**Objetivo:** Verificar se é criada a pasta recycle_bin com todos os ficheiros necessários (diretório "Files", ficheiro "config", ficheiro "log.txt", ficheiro metadata.bd). Isto é, verificar se tem a estrutura correta para que o resto das funções funcionem.
**Passos:**
1. Run: `./recycle_bin.sh`
2. Verificar a emissão da mensagem "O recycle bin não existe atualmente."
3. Verificar a emissão da mensagem "A recycle bin foi inicializada com sucesso no diretório: /home/user/Projeto01_SO/recycle_bin"
4. Averiguar a criação da pasta recycle_bin
5. Averiguar o conteúdo da pasta recycle_bin
**Resultado Esperado:**
- A pasta recycle_bin foi criada no diretório "/home/user/Projeto01_SO/recycle_bin"
- O diretório "Files" foi criado dentro da pasta recycle_bin
- O ficheiro "config" foi criado dentro da pasta recycle_bin com as informações MAX_SIZE_MB=1024 e RETENTION_DAYS=30
- O ficheiro "log.txt" foi criado dentro da pasta recycle_bin com a data da inicialização do recycle bin
- O ficheiro "metadata.bd" foi criado dentro da pasta recycle_bin com as seguintes informações ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER
**Resultado Atual:** 
- A pasta recycle_bin foi criada no diretório "/home/user/Projeto01_SO/recycle_bin"
- O diretório "Files" foi criado dentro da pasta recycle_bin
- O ficheiro "config" foi criado dentro da pasta recycle_bin com as informações MAX_SIZE_MB=1024 e RETENTION_DAYS=30
- O ficheiro "log.txt" foi criado dentro da pasta recycle_bin com a data da inicialização do recycle bin
- O ficheiro "metadata.bd" foi criado dentro da pasta recycle_bin com as seguintes informações ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER
**Estado do Teste:** Pass 
**Screenshots:** [Ver pasta]

### Test Case 2: Delete single file
**Objetivo:** Apagar um ficheiro
**Passos:**
1. Create test file: `echo "test" > test.txt`
2. Run: `./recycle_bin.sh delete test.txt`
3. Verify file is removed from current directory
4. Run: `./recycle_bin.sh list`
5. Verify file appears in recycle bin
**Resultado Esperado:**
- File is moved to ~/.recycle_bin/files/
- Metadata entry is created
- Success message is displayed
- File appears in list output
**Resultado Atual:** [Fill in after testing]
**Estado do Teste:** ☐ Pass ☐ Fail
**Screenshots:** [If applicable]

### Test Case 3: Delete multiple files in one command
**Objetivo:** Verificar se é criada a pasta recycle_bin com todos os ficheiros necessários para funcionar
**Passos:**
1. Create test file: `echo "test" > test.txt`
2. Run: `./recycle_bin.sh delete test.txt`
3. Verify file is removed from current directory
4. Run: `./recycle_bin.sh list`
5. Verify file appears in recycle bin
**Resultado Esperado:**
- File is moved to ~/.recycle_bin/files/
- Metadata entry is created
- Success message is displayed
- File appears in list output
**Resultado Atual:** [Fill in after testing]
**Estado do Teste:** ☐ Pass ☐ Fail
**Screenshots:** [If applicable]

### Test Case 4: Delete empty directory
**Objetivo:** Verificar se é criada a pasta recycle_bin com todos os ficheiros necessários para funcionar
**Passos:**
1. Create test file: `echo "test" > test.txt`
2. Run: `./recycle_bin.sh delete test.txt`
3. Verify file is removed from current directory
4. Run: `./recycle_bin.sh list`
5. Verify file appears in recycle bin
**Resultado Esperado:**
- File is moved to ~/.recycle_bin/files/
- Metadata entry is created
- Success message is displayed
- File appears in list output
**Resultado Atual:** [Fill in after testing]
**Estado do Teste:** ☐ Pass ☐ Fail
**Screenshots:** [If applicable]

### Test Case 5: Delete directory with contents(recursive)
**Objetivo:** Verificar se é criada a pasta recycle_bin com todos os ficheiros necessários para funcionar
**Passos:**
1. Create test file: `echo "test" > test.txt`
2. Run: `./recycle_bin.sh delete test.txt`
3. Verify file is removed from current directory
4. Run: `./recycle_bin.sh list`
5. Verify file appears in recycle bin
**Resultado Esperado:**
- File is moved to ~/.recycle_bin/files/
- Metadata entry is created
- Success message is displayed
- File appears in list output
**Resultado Atual:** [Fill in after testing]
**Estado do Teste:** ☐ Pass ☐ Fail
**Screenshots:** [If applicable]

### Test Case 6: List empty recycle bin
**Objetivo:** Verificar se é criada a pasta recycle_bin com todos os ficheiros necessários para funcionar
**Passos:**
1. Create test file: `echo "test" > test.txt`
2. Run: `./recycle_bin.sh delete test.txt`
3. Verify file is removed from current directory
4. Run: `./recycle_bin.sh list`
5. Verify file appears in recycle bin
**Resultado Esperado:**
- File is moved to ~/.recycle_bin/files/
- Metadata entry is created
- Success message is displayed
- File appears in list output
**Resultado Atual:** [Fill in after testing]
**Estado do Teste:** ☐ Pass ☐ Fail
**Screenshots:** [If applicable]

### Test Case 7: List recycle bin with items
**Objetivo:** Verificar se é criada a pasta recycle_bin com todos os ficheiros necessários para funcionar
**Passos:**
1. Create test file: `echo "test" > test.txt`
2. Run: `./recycle_bin.sh delete test.txt`
3. Verify file is removed from current directory
4. Run: `./recycle_bin.sh list`
5. Verify file appears in recycle bin
**Resultado Esperado:**
- File is moved to ~/.recycle_bin/files/
- Metadata entry is created
- Success message is displayed
- File appears in list output
**Resultado Atual:** [Fill in after testing]
**Estado do Teste:** ☐ Pass ☐ Fail
**Screenshots:** [If applicable]

### Test Case 8: Restore single file
**Objetivo:** Verificar se é criada a pasta recycle_bin com todos os ficheiros necessários para funcionar
**Passos:**
1. Create test file: `echo "test" > test.txt`
2. Run: `./recycle_bin.sh delete test.txt`
3. Verify file is removed from current directory
4. Run: `./recycle_bin.sh list`
5. Verify file appears in recycle bin
**Resultado Esperado:**
- File is moved to ~/.recycle_bin/files/
- Metadata entry is created
- Success message is displayed
- File appears in list output
**Resultado Atual:** [Fill in after testing]
**Estado do Teste:** ☐ Pass ☐ Fail
**Screenshots:** [If applicable]

### Test Case 9: Restore to non-existent original path
**Objetivo:** Verificar se é criada a pasta recycle_bin com todos os ficheiros necessários para funcionar
**Passos:**
1. Create test file: `echo "test" > test.txt`
2. Run: `./recycle_bin.sh delete test.txt`
3. Verify file is removed from current directory
4. Run: `./recycle_bin.sh list`
5. Verify file appears in recycle bin
**Resultado Esperado:**
- File is moved to ~/.recycle_bin/files/
- Metadata entry is created
- Success message is displayed
- File appears in list output
**Resultado Atual:** [Fill in after testing]
**Estado do Teste:** ☐ Pass ☐ Fail
**Screenshots:** [If applicable]

### Test Case 10: Empty entire recycle bin
**Objetivo:** Verificar se é criada a pasta recycle_bin com todos os ficheiros necessários para funcionar
**Passos:**
1. Create test file: `echo "test" > test.txt`
2. Run: `./recycle_bin.sh delete test.txt`
3. Verify file is removed from current directory
4. Run: `./recycle_bin.sh list`
5. Verify file appears in recycle bin
**Resultado Esperado:**
- File is moved to ~/.recycle_bin/files/
- Metadata entry is created
- Success message is displayed
- File appears in list output
**Resultado Atual:** [Fill in after testing]
**Estado do Teste:** ☐ Pass ☐ Fail
**Screenshots:** [If applicable]

### Test Case 11: Search for existing file
**Objetivo:** Verificar se é criada a pasta recycle_bin com todos os ficheiros necessários para funcionar
**Passos:**
1. Create test file: `echo "test" > test.txt`
2. Run: `./recycle_bin.sh delete test.txt`
3. Verify file is removed from current directory
4. Run: `./recycle_bin.sh list`
5. Verify file appears in recycle bin
**Resultado Esperado:**
- File is moved to ~/.recycle_bin/files/
- Metadata entry is created
- Success message is displayed
- File appears in list output
**Resultado Atual:** [Fill in after testing]
**Estado do Teste:** ☐ Pass ☐ Fail
**Screenshots:** [If applicable]

### Test Case 12: Search for non-existent file
**Objetivo:** Verificar se é criada a pasta recycle_bin com todos os ficheiros necessários para funcionar
**Passos:**
1. Create test file: `echo "test" > test.txt`
2. Run: `./recycle_bin.sh delete test.txt`
3. Verify file is removed from current directory
4. Run: `./recycle_bin.sh list`
5. Verify file appears in recycle bin
**Resultado Esperado:**
- File is moved to ~/.recycle_bin/files/
- Metadata entry is created
- Success message is displayed
- File appears in list output
**Resultado Atual:** [Fill in after testing]
**Estado do Teste:** ☐ Pass ☐ Fail
**Screenshots:** [If applicable]

### Test Case 13: Display help information
**Objetivo:** Verificar se é criada a pasta recycle_bin com todos os ficheiros necessários para funcionar
**Passos:**
1. Create test file: `echo "test" > test.txt`
2. Run: `./recycle_bin.sh delete test.txt`
3. Verify file is removed from current directory
4. Run: `./recycle_bin.sh list`
5. Verify file appears in recycle bin
**Resultado Esperado:**
- File is moved to ~/.recycle_bin/files/
- Metadata entry is created
- Success message is displayed
- File appears in list output
**Resultado Atual:** [Fill in after testing]
**Estado do Teste:** ☐ Pass ☐ Fail
**Screenshots:** [If applicable]

## Edge cases tested

## Error Handling

## Known bugs or limitations

## Test coverage summary
