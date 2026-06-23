# ReggieApp 🌱

**Diário inteligente de plantas para quem está começando a cuidar do verde.**

---

## O Problema

Muitas pessoas que começam a cuidar de plantas em casa enfrentam as mesmas dificuldades: não sabem o nome das espécies que têm, não conhecem a frequência correta de rega e adubação, e acabam esquecendo dos cuidados no dia a dia. Pesquisar no Google ou consultar um chat de IA até ajuda com dúvidas pontuais, mas não resolve o problema completo — faltam lembretes, acompanhamento personalizado por planta e um histórico do crescimento ao longo do tempo. O resultado é quase sempre o mesmo: a planta morre, o usuário se frustra e desiste.

---

## A Solução

O ReggieApp resolve esse problema sendo um diário inteligente de plantas que combina tecnologia e cuidado em um só lugar:

- **Identificação automática por foto** — o usuário fotografa a planta e a IA identifica a espécie instantaneamente
- **Dados de cuidado gerados pelo Gemini** — frequência de rega, adubação, local ideal na casa, curiosidades e dicas personalizadas por espécie
- **Lembretes personalizados** — notificações locais agendadas automaticamente conforme a frequência definida pelo Gemini
- **Registro de cuidados** — histórico de tudo que foi feito com cada planta
- **Linha do tempo com fotos** — acompanhamento visual da evolução da planta ao longo do tempo
- **Compartilhamento nativo** — compartilhe informações da sua planta com quem quiser

O diferencial não é apenas informar — é acompanhar. O ReggieApp cresce junto com as plantas do usuário.

---

## Telas do Aplicativo

| Tela | Descrição |
|---|---|
| **Splash Screen** | Tela inicial que verifica o estado de autenticação e redireciona o usuário para o destino correto |
| **Login Screen** | O usuário autentica com e-mail e senha para acessar o app |
| **Register Screen** | O usuário cria uma nova conta para começar a usar o app |
| **Home Screen** | Visão geral de todas as plantas cadastradas com o status do próximo cuidado de cada uma |
| **Add Plant Screen** | O usuário cadastra uma nova planta usando a câmera ou galeria |
| **Identify Plant Screen** | Exibe o resultado da identificação por IA e os dados gerados pelo Gemini para confirmação |
| **Plant Detail Screen** | Informações completas da planta e acesso a todas as ações disponíveis |
| **Care Log Screen** | Histórico cronológico de todos os cuidados já registrados para a planta |
| **Growth History Screen** | Linha do tempo com fotos que documentam o crescimento da planta ao longo do tempo |
| **Notifications Screen** | Central de lembretes agendados, com status de atenção e próximos cuidados, e controle para ativar/desativar notificações |
| **Profile Screen** | Dados do usuário, estatísticas gerais e acesso às configurações |

---

## Fluxo Principal — Add Plant

```
Abre câmera do celular                       
      ↓
Tira a foto da planta
      ↓
App envia a foto para a API de identificação de plantas
      ↓
API retorna: nome comum e nome científico 
      ↓
App envia o nome identificado para a API do Gemini
      ↓
Gemini retorna (JSON estruturado):
  - Frequência de rega (dias)
  - Frequência de adubação (dias)
  - Local ideal na casa
  - Curiosidades da espécie
  - Dicas de rega, luz, temperatura e adubação
      ↓
Tela exibe resultado completo para o usuário confirmar ou editar
      ↓
Dados salvos no SQLite
Foto salva localmente no dispositivo (path guardado no SQLite)
Notificações de rega e adubação agendadas automaticamente
      ↓
Volta para Home
```

---

## Tecnologias Utilizadas

| Tecnologia | Finalidade | Justificativa |
|---|---|---|
| Flutter | Framework mobile | Permite desenvolvimento para Android e iOS com uma única base de código |
| Dart | Linguagem | Linguagem oficial do Flutter, tipada e com boa performance |
| SQLite (sqflite) | Banco de dados local | Persistência local de plantas, usuários, cuidados e histórico de crescimento sem necessidade de backend |
| shared_preferences | Persistência de sessão | Armazena o usuário autenticado localmente entre sessões do app |
| crypto | Hash de senha | Criptografia SHA256 para armazenar senhas de forma segura no banco local |
| API de identificação de plantas | Identificar espécie por foto | Automatiza o cadastro e elimina a necessidade de o usuário saber o nome da planta |
| Gemini API | Dados completos de cuidado | Gera frequência de rega e adubação, local ideal, curiosidades e dicas específicas por espécie |
| dio | Cliente HTTP | Requisições para as APIs externas com suporte a timeout e retry |
| flutter_local_notifications | Notificações locais | Lembretes de rega e adubação agendados diretamente no dispositivo, sem servidor |
| share_plus | Compartilhamento nativo | Usa o recurso nativo do sistema operacional para compartilhar informações da planta |
| image_picker | Acesso à câmera e galeria | Permite ao usuário tirar foto ou escolher da galeria para identificar a planta |
| permission_handler | Permissões em runtime | Solicita permissão de câmera antes de acessar o hardware |
| Riverpod | Gerenciamento de estado | Gerenciamento reativo, testável e sem boilerplate excessivo |
| GoRouter | Navegação | Navegação declarativa com suporte a rotas nomeadas e redirecionamentos |
| path_provider | Armazenamento de arquivos | Localiza o diretório correto no dispositivo para salvar as fotos localmente |

---

## Recursos de Hardware e Funcionalidades Nativas

O ReggieApp utiliza a **câmera do dispositivo** como recurso de hardware principal: ela é acionada tanto na tela de Add Plant, para fotografar e identificar a espécie, quanto na Growth History, para registrar visualmente a evolução ao longo do tempo. Em dispositivos físicos Android e iOS, o app exibe um bottomsheet com as opções "Câmera" e "Galeria" antes de abrir o hardware, e solicita a permissão de câmera em runtime via `permission_handler`. Além da câmera, o app integra o **sistema de compartilhamento nativo** do sistema operacional via `share_plus`, e utiliza **notificações locais periódicas** agendadas no dispositivo para lembrar o usuário da rega e adubação de cada planta — com suporte nativo para Android e iOS.

---

## Arquitetura

O projeto segue **Clean Architecture** em camadas:

```
lib/
├── core/            # constantes, erros, serviços e utilitários
├── data/            # datasources, models e repositórios (implementações)
│   ├── datasources/ # SQLite, auth local, Plant ID API, Gemini API
│   ├── models/      # modelos de dados com serialização
│   └── repositories/
├── domain/          # entidades, interfaces de repositórios e use cases
└── presentation/    # providers (Riverpod), screens e widgets
```

A autenticação é **100% local** — usuários e senhas (hash SHA256) são armazenados no SQLite do dispositivo. Não há backend externo ou BaaS.

---

## Observação sobre Testes e Demonstração em Vídeo

O desenvolvimento e os testes deste projeto foram realizados em um PC com Windows, sem acesso a um dispositivo Android físico. Para viabilizar os testes, foi utilizado o emulador Android do Android Studio. Para a funcionalidade de câmera — que não está disponível no ambiente de emulação — foi utilizado o seletor de arquivos (galeria) como alternativa. No entanto, o app detecta a plataforma em runtime: em dispositivos físicos Android e iOS, exibe o bottomsheet com "Câmera" e "Galeria" e solicita permissão; em desktop/emulador, abre direto o seletor de arquivos. Da mesma forma, as notificações nativas são agendadas apenas em Android e iOS; no ambiente de desktop, os lembretes são exibidos na Central de Notificações dentro do próprio app.

---

## Como Executar

1. **Pré-requisitos:** Flutter SDK >= 3.12.0 e Android Studio com emulador configurado
2. Clone o repositório:
   ```bash
   git clone <url-do-repositorio>
   cd ponderada4-mobile
   ```
3. Instale as dependências:
   ```bash
   flutter pub get
   ```
4. Configure as chaves de API copiando o arquivo de exemplo:
   ```bash
   cp lib/core/constants/env.dart.example lib/core/constants/env.dart
   ```
   Em seguida, edite `lib/core/constants/env.dart` com sua chave do **Plant ID API** e sua chave do **Gemini API**.
5. Execute o app:
   ```bash
   flutter run
   ```

---

# Vídeo de Demonstração

Para acessar o vídeo, [clique aqui](https://drive.google.com/file/d/1mu59ofS0r8arzginfSEj3R0bpyMqXiHf/view?usp=sharing)