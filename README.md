# 🐍 Jogo da Cobrinha (Snake Game) em Assembly MIPS

Este projeto é uma implementação do clássico jogo da cobrinha (*Snake Game*), desenvolvido inteiramente em linguagem **Assembly MIPS** para execução no simulador **MARS 4.5** (*MIPS Assembler and Runtime Simulator*).

O jogo faz uso das ferramentas nativas do MARS: **Bitmap Display** para a renderização gráfica dos elementos em tela e **Keyboard and Display MMIO Simulator** para captura e processamento das entradas de teclado do jogador em tempo real.

---

## 🛠️ Requisitos e Ferramentas

* **MARS 4.5** (*MIPS Assembler and Runtime Simulator*).
* **Java Runtime Environment (JRE)** instalado para rodar o MARS.
* Código fonte: `snake.asm`.

---

## ⚙️ Como Configurar e Executar no MARS

Siga a ordem dos passos para garantir a execução correta do jogo:

### 1. Compilar o Código
1. Abra o arquivo `snake.asm` no **MARS**.
2. Clique na aba **Edit** e pressione **F3** (ou vá no menu superior e clique no ícone da chave de fenda/chave inglesa `Assemble`).

### 2. Configurar o Bitmap Display (Tela do Jogo)
1. No menu superior, acesse: `Tools` ➔ `Bitmap Display`.
2. Configure os parâmetros exatamente com estes valores:
   * **Unit Width in Pixels:** `16`
   * **Unit Height in Pixels:** `16`
   * **Display Width in Pixels:** `512`
   * **Display Height in Pixels:** `512`
   * **Base address for display:** `0x10010000 (static data)`
3. Clique no botão **Connect to MIPS** na parte inferior da janela.

### 3. Configurar o Simulador de Teclado (MMIO)
1. No menu superior, acesse: `Tools` ➔ `Keyboard and Display MMIO Simulator`.
2. Clique no botão **Connect to MIPS** no canto inferior esquerdo da janela.

### 4. Iniciar a Partida
1. Pressione **F5** (ou clique no botão verde de Play `►` na barra de ferramentas do MARS).
2. Clique com o mouse **dentro da caixa branca inferior** da janela do *Keyboard and Display MMIO Simulator* para dar foco ao teclado.
3. Pressione a tecla **`D`** (Direita) ou **`S`** (Baixo) para iniciar o movimento da cobra em uma direção segura.

---

## 🕹️ Controles

| Tecla | Direção |
| :---: | :--- |
| **`W`** | Mover para Cima |
| **`S`** | Mover para Baixo |
| **`A`** | Mover para a Esquerda |
| **`D`** | Mover para a Direita |

> **Nota:** Como a cobra nasce no canto superior esquerdo $(0,0)$, pressionar `W` ou `A` no início causará uma colisão imediata com a parede.

---

## 🏆 Regras e Pontuação

* **Sobrevivência:** Cada movimento bem-sucedido concede **1 ponto**.
* **Maçãs:** Cada comida verde coletada concede **5 pontos** extras e aumenta o tamanho da cobra.
* **Game Over:** Ocorre ao colidir com as paredes laterais/superiores ou contra a própria cauda.
* **Exibição:** O resultado final e o histórico da partida são impressos na aba **Run I/O** na parte inferior do MARS.

---

## 👤 Autor e Disciplina

* **Aluno:** Felipe Alves ([@felipealves02](https://github.com/felipealves02))
* **Instituição:** Universidade Federal Rural de Pernambuco (UFRPE)
* **Docente:** Prof.ª Millena Cavalcanti (`@millenacavalcanti`)
