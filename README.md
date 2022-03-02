<h1 align="center">TCC Taiti</h1>
<p align="center">Projeto para receber saída de Taiti e encontrar as dependências estáticas</p>

### Pré-requisitos

Ruby version: 2.1.0 or higher<br/>
Ruby gems: rubrowser, git, fileutils, csv, json<br/><br/>
Também é necessário os arquivos csv para rodar o código: Um csv com a saída de TAITI e outro csv com as hashes de commit da task<br/>
Exemplo dos arquivos está na root do repositório: taiti_result.csv(Saída de TAITI) e tasks_taiti.csv(csv com as hashes de commit da task)

### 🎲 Rodando o Codigo
```bash
Basta executar o script ruby passando os nomes dos arquivos csv, deve ser executado na root do projeto.

O csv com resultado de TAITI primeiro e depois o csv com o as hashes de commit.
Exemplo: 
ruby dependenciesExtractor.rb taiti_result.csv tasks_taiti.csv

O exemplo foi feito em windows, caso a máquina seja linux executar:
./dependenciesExtractor.rb taiti_result.csv tasks_taiti.csv
```

