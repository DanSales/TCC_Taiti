<h1 align="center">TCC Taiti</h1>
<p align="center">Projeto para receber saída de Taiti e encontrar as dependências estáticas</p>

### Pré-requisitos

Ruby version: 2.1.0 or higher<br/>
Ruby gems: rubrowser, git, fileutils, csv, json<br/><br/>
Também é necessário os arquivos csv para rodar o código: Um csv com a saída de TAITI e outro csv com as hashes de commit da task<br/>
Exemplo dos arquivos está na root do repositório: taiti_result.csv(Saída de TAITI) e tasks_taiti.csv(csv com as hashes de commit da task)

### 🎲 Rodando o Codigo
```bash
Basta alterar a linha 251 do código que possui a chamada para o método main apenas alterando:
main('taiti_result.csv', 'tasks_taiti.csv')
Para
main(caminhocsvsaidataiti, caminhocsvtaskstaiti)
Obs: Caso os arquivos estejam na root, não é necessário o caminho completo apenas o nome do arquivo + extensão
```

