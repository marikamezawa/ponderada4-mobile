# 🌱 ReggieApp — Diário Inteligente de Plantas

> Documento de especificação completo para desenvolvimento com Flutter. Este arquivo deve ser lido integralmente antes de qualquer implementação.

---

## 📌 Visão Geral

O **ReggieApp** é um aplicativo mobile desenvolvido em Flutter que permite ao usuário cadastrar suas plantas domésticas, identificá-las automaticamente por foto usando IA, e receber lembretes personalizados de cuidados (rega, adubação, transplante). O app resolve um problema real: pessoas esquecem de cuidar das plantas em casa e não sabem identificar doenças ou necessidades específicas de cada espécie.

---

## 🎯 Problema e Público-Alvo

**Problema:** Pessoas que têm plantas em casa frequentemente esquecem de regá-las, não sabem identificar a espécie correta, desconhecem a frequência ideal de cuidados e não têm forma de registrar ou compartilhar informações sobre suas plantas.

**Público-alvo:** Adultos entre 20–45 anos que têm plantas em casa ou querem começar a ter, com ou sem experiência em jardinagem.

---

## 🛠️ Tecnologias Utilizadas

| Camada | Tecnologia |
|---|---|
| Mobile | Flutter (Dart) |
| Backend / BaaS | Supabase (Auth + Postgres + Storage) |
| API Externa | Plant.id API (identificação de plantas por foto) |
| Notificações | flutter_local_notifications |
| Compartilhamento | share_plus |
| Câmera | image_picker + camera |
| Gerenciamento de Estado | Riverpod |
| Navegação | GoRouter |
| HTTP Client | Dio |
| Armazenamento local | SharedPreferences |

### Dependências Flutter (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  riverpod: ^2.0.0
  flutter_riverpod: ^2.0.0
  go_router: ^13.0.0
  dio: ^5.0.0
  image_picker: ^1.0.0
  camera: ^0.10.0
  flutter_local_notifications: ^17.0.0
  share_plus: ^9.0.0
  shared_preferences: ^2.0.0
  intl: ^0.19.0
  cached_network_image: ^3.0.0
  uuid: ^4.0.0
  permission_handler: ^11.0.0
```

---

## 🗂️ Arquitetura — Clean Architecture (adaptada para Flutter)

O projeto segue uma arquitetura em camadas inspirada em Clean Code, adaptada para Flutter com Riverpod.

```
lib/
├── main.dart
├── app.dart                          # MaterialApp + GoRouter setup
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── app_routes.dart
│   ├── errors/
│   │   └── app_exception.dart
│   ├── services/
│   │   ├── notification_service.dart     # flutter_local_notifications
│   │   └── share_service.dart            # share_plus
│   └── utils/
│       └── date_helper.dart
│
├── domain/
│   ├── entities/
│   │   ├── plant.dart                # Entidade principal
│   │   ├── care_log.dart             # Registro de cuidados
│   │   └── user_profile.dart
│   ├── repositories/
│   │   ├── plant_repository.dart     # Interface (contrato)
│   │   ├── care_log_repository.dart
│   │   └── auth_repository.dart
│   └── usecases/
│       ├── identify_plant_usecase.dart
│       ├── save_plant_usecase.dart
│       ├── schedule_care_usecase.dart
│       └── get_user_plants_usecase.dart
│
├── data/
│   ├── repositories/
│   │   ├── plant_repository_impl.dart    # Implementação concreta
│   │   ├── care_log_repository_impl.dart
│   │   └── auth_repository_impl.dart
│   ├── datasources/
│   │   ├── supabase_plant_datasource.dart
│   │   ├── plant_id_api_datasource.dart  # API externa Plant.id
│   │   └── local_datasource.dart
│   └── models/
│       ├── plant_model.dart              # JSON serialization
│       ├── care_log_model.dart
│       └── plant_id_response_model.dart  # Resposta da Plant.id API
│
├── presentation/
│   ├── screens/
│   │   ├── splash/
│   │   │   └── splash_screen.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── add_plant/
│   │   │   ├── add_plant_screen.dart
│   │   │   └── identify_plant_screen.dart
│   │   ├── plant_detail/
│   │   │   └── plant_detail_screen.dart
│   │   ├── care_log/
│   │   │   └── care_log_screen.dart
│   │   └── profile/
│   │       └── profile_screen.dart
│   ├── widgets/
│   │   ├── plant_card.dart
│   │   ├── care_badge.dart
│   │   ├── loading_overlay.dart
│   │   └── error_snackbar.dart
│   └── providers/
│       ├── auth_provider.dart
│       ├── plant_provider.dart
│       ├── care_log_provider.dart
│       └── notification_provider.dart
```

---

## 🖥️ Telas do Aplicativo

### 1. Splash Screen (`/`)
- Logo do app centralizado
- Verifica sessão ativa no Supabase
- Redireciona para Home (logado) ou Login (não logado)
- Duração: 2 segundos com animação de fade

### 2. Login Screen (`/login`)
- Campo de e-mail e senha
- Botão "Entrar"
- Link para tela de cadastro
- Autenticação via Supabase Auth
- Tratamento de erros (credenciais inválidas, sem conexão)

### 3. Register Screen (`/register`)
- Campos: nome, e-mail, senha, confirmação de senha
- Validação de campos em tempo real
- Criação de conta via Supabase Auth
- Após cadastro, redireciona para Home

### 4. Home Screen (`/home`)
- AppBar com nome do usuário e avatar
- Grid ou lista de plantas cadastradas (PlantCard)
- Badge de próximo cuidado em cada planta
- FAB para adicionar nova planta
- Estado vazio com ilustração e CTA quando não há plantas
- Pull-to-refresh para atualizar lista

### 5. Add Plant Screen (`/add-plant`)
- Botão para abrir câmera **(uso de hardware — câmera)**
- Preview da foto tirada
- Botão "Identificar planta" → chama Plant.id API
- Exibe resultado: nome comum, nome científico, nível de confiança
- Campos editáveis: nome personalizado, localização na casa (ex: "sala", "varanda")
- Seleção de frequência de cuidados: rega (diária/2x semana/semanal), adubação (mensal/bimestral)
- Botão "Salvar planta" → persiste no Supabase e agenda notificações

### 6. Plant Detail Screen (`/plant/:id`)
- Foto da planta em destaque (header)
- Nome comum e científico
- Chips de cuidados com próxima data
- Botão "Registrar cuidado" → abre modal para logar rega/adubação feita
- Botão "Compartilhar" → share_plus com card da planta **(compartilhamento)**
- Histórico de cuidados em lista (últimos 10)
- Botão de deletar planta (com confirmação)

### 7. Care Log Screen (`/plant/:id/history`)
- Timeline completa de todos os cuidados registrados da planta
- Filtro por tipo (rega, adubação, transplante)
- Data e hora de cada registro
- Nota opcional por registro

### 8. Profile Screen (`/profile`)
- Avatar e nome do usuário
- Total de plantas cadastradas
- Total de cuidados registrados
- Botão de logout
- Switch para ativar/desativar notificações globais

---

## 🔌 Integrações

### Supabase (Backend + Banco de Dados)

#### Tabelas

```sql
-- Usuários (gerenciado pelo Supabase Auth)
-- A tabela auth.users já existe automaticamente

-- Perfil do usuário
CREATE TABLE profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Plantas
CREATE TABLE plants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  name TEXT NOT NULL,
  scientific_name TEXT,
  common_name TEXT,
  photo_url TEXT,
  location TEXT,
  water_frequency_days INTEGER DEFAULT 3,
  fertilize_frequency_days INTEGER DEFAULT 30,
  last_watered TIMESTAMP,
  last_fertilized TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Registro de cuidados
CREATE TABLE care_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plant_id UUID REFERENCES plants NOT NULL,
  user_id UUID REFERENCES auth.users NOT NULL,
  care_type TEXT NOT NULL, -- 'water', 'fertilize', 'repot'
  note TEXT,
  logged_at TIMESTAMP DEFAULT NOW()
);
```

#### Storage
- Bucket `plant-photos` para armazenar as fotos tiradas pela câmera
- Fotos são salvas com UUID único: `{user_id}/{plant_id}.jpg`

#### Row Level Security (RLS)
- Ativar RLS em todas as tabelas
- Usuários só acessam seus próprios dados

---

### Plant.id API (API Externa)

**Endpoint:** `https://api.plant.id/v3/identification`

**Como funciona:**
1. Usuário tira a foto com a câmera
2. A imagem é convertida para base64
3. Enviada para a API Plant.id via POST
4. A resposta retorna uma lista de sugestões com nome, confiança e dados de cuidados

**Exemplo de request:**
```dart
// Em: lib/data/datasources/plant_id_api_datasource.dart

Future<PlantIdResponseModel> identifyPlant(File imageFile) async {
  final bytes = await imageFile.readAsBytes();
  final base64Image = base64Encode(bytes);

  final response = await dio.post(
    'https://api.plant.id/v3/identification',
    data: {
      'images': [base64Image],
      'classification_level': 'species',
    },
    options: Options(
      headers: {
        'Api-Key': Env.plantIdApiKey,
        'Content-Type': 'application/json',
      },
    ),
  );

  return PlantIdResponseModel.fromJson(response.data);
}
```

**Tratamento de erros:**
- Timeout na API → exibir mensagem e permitir cadastro manual
- Confiança baixa (< 30%) → avisar usuário e sugerir tentar outra foto
- Sem conexão → mensagem de erro com botão de retry

---

### Sistema de Notificações

**Biblioteca:** `flutter_local_notifications`

**Quando notificar:**
- No momento de salvar a planta, agendar notificações recorrentes
- Ex: planta com rega a cada 3 dias → notificação a cada 3 dias às 08h00
- Ex: adubação mensal → notificação todo dia 1º do mês

**Implementação:**

```dart
// Em: lib/core/services/notification_service.dart

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> scheduleWaterReminder({
    required String plantId,
    required String plantName,
    required int frequencyDays,
  }) async {
    await _plugin.periodicallyShow(
      plantId.hashCode,
      '🌿 Hora de regar!',
      '$plantName está com sede. Não se esqueça!',
      RepeatInterval.daily, // ajustar conforme frequência
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'care_reminders',
          'Lembretes de Cuidados',
          importance: Importance.high,
        ),
      ),
    );
  }

  Future<void> cancelReminder(String plantId) async {
    await _plugin.cancel(plantId.hashCode);
  }
}
```

**Permissões:**
- Solicitar permissão de notificação no primeiro uso
- Respeitar configuração global de notificações da tela de Perfil

---

### Compartilhamento

**Biblioteca:** `share_plus`

**O que compartilhar:** Card com foto da planta, nome da espécie e próximos cuidados

**Implementação:**

```dart
// Em: lib/core/services/share_service.dart

class ShareService {
  Future<void> sharePlant(Plant plant) async {
    final text = '''
🌱 Minha planta: ${plant.name}
📖 Espécie: ${plant.scientificName ?? 'Não identificada'}
💧 Próxima rega: ${plant.nextWateringDate}
🌿 Cadastrada no ReggieApp
    ''';

    if (plant.photoUrl != null) {
      // Baixar imagem e compartilhar com texto
      final response = await http.get(Uri.parse(plant.photoUrl!));
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/share_plant.jpg');
      await file.writeAsBytes(response.bodyBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
      );
    } else {
      await Share.share(text);
    }
  }
}
```

---

### Uso de Hardware — Câmera

**Biblioteca:** `image_picker` + `camera`

```dart
// Em: lib/presentation/screens/add_plant/add_plant_screen.dart

Future<void> _openCamera() async {
  final picker = ImagePicker();
  final XFile? photo = await picker.pickImage(
    source: ImageSource.camera,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );

  if (photo != null) {
    setState(() => _selectedImage = File(photo.path));
    _identifyPlant(_selectedImage!);
  }
}
```

**Permissões necessárias:**
- Android: `CAMERA`, `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE` no `AndroidManifest.xml`
- iOS: `NSCameraUsageDescription` no `Info.plist`

---

## 🎨 Design Visual

### Paleta de Cores

```dart
// lib/core/constants/app_colors.dart

class AppColors {
  static const primary = Color(0xFF2D6A4F);       // Verde escuro
  static const primaryLight = Color(0xFF52B788);  // Verde médio
  static const accent = Color(0xFFB7E4C7);        // Verde claro
  static const background = Color(0xFFF8FFF9);    // Fundo quase branco
  static const surface = Color(0xFFFFFFFF);       // Cards
  static const textPrimary = Color(0xFF1B1B1B);   // Texto principal
  static const textSecondary = Color(0xFF6B6B6B); // Texto secundário
  static const error = Color(0xFFE63946);         // Erros
  static const warning = Color(0xFFF4A261);       // Alertas de cuidado
}
```

### Tipografia
- Fonte: **Inter** (Google Fonts)
- Títulos: Inter Bold, 24px
- Subtítulos: Inter SemiBold, 18px
- Corpo: Inter Regular, 14px
- Labels: Inter Medium, 12px

### Componentes Visuais

**PlantCard:**
- Imagem da planta com bordas arredondadas (12px)
- Badge colorido para próximo cuidado (azul = rega, verde = adubação, laranja = urgente)
- Sombra suave (elevation 2)

**Tema Geral:**
- `ThemeData` com `useMaterial3: true`
- ColorScheme baseado em `AppColors.primary`
- AppBar sem elevação, fundo branco
- BottomNavigationBar com ícones arredondados

---

## 🔄 Fluxo de Navegação

```
Splash
  ├── (logado) → Home
  └── (não logado) → Login
                       └── Register → Home

Home
  ├── FAB → Add Plant
  │           └── (foto tirada) → Identify Plant → (confirmado) → Home
  ├── PlantCard tap → Plant Detail
  │                     ├── Botão Histórico → Care Log
  │                     └── Botão Compartilhar → Share Sheet (nativo)
  └── BottomNav → Profile
```

---

## 📋 Checklist de Requisitos da Ponderada

| Requisito | Implementação | Status |
|---|---|---|
| Tecnologia mobile (Flutter) | Flutter + Dart | ✅ |
| Mais de duas telas | 8 telas implementadas | ✅ |
| Navegação funcional | GoRouter com rotas nomeadas | ✅ |
| Backend funcional | Supabase (Auth + DB + Storage) | ✅ |
| Banco de dados | Supabase Postgres (plants, care_logs, profiles) | ✅ |
| API externa | Plant.id API para identificação de espécies | ✅ |
| Sistema de notificações | flutter_local_notifications com agendamento recorrente | ✅ |
| Compartilhamento | share_plus com foto + texto da planta | ✅ |
| Hardware do celular | Câmera via image_picker | ✅ |
| Interface organizada | Material 3, paleta verde, tipografia Inter | ✅ |
| Tratamento de erros | Try/catch em todas chamadas, estados de loading e erro | ✅ |
| Documentação mínima | Este README + instruções de execução abaixo | ✅ |
| Vídeo demonstrativo | A gravar após implementação | ⬜ |
| Código em repositório público | A publicar no GitHub | ⬜ |

---

## 🚀 Instruções de Execução

### Pré-requisitos
- Flutter SDK >= 3.0.0
- Dart >= 3.0.0
- Android Studio ou VS Code com extensão Flutter
- Conta no Supabase (gratuito)
- Chave de API da Plant.id (plano gratuito disponível)

### Configuração

1. Clone o repositório
```bash
git clone https://github.com/seu-usuario/reggieapp.git
cd reggieapp
```

2. Instale as dependências
```bash
flutter pub get
```

3. Configure as variáveis de ambiente. Crie um arquivo `lib/core/constants/env.dart`:
```dart
class Env {
  static const supabaseUrl = 'SUA_SUPABASE_URL';
  static const supabaseAnonKey = 'SUA_SUPABASE_ANON_KEY';
  static const plantIdApiKey = 'SUA_PLANT_ID_API_KEY';
}
```

4. Execute as migrations SQL no Supabase Dashboard (SQL Editor) — usar os scripts da seção de banco de dados acima

5. No Supabase Storage, criar o bucket `plant-photos` com acesso público para leitura

6. Execute o app
```bash
flutter run
```

### Configuração Android

No arquivo `android/app/src/main/AndroidManifest.xml`, adicionar:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```

---

## ⚠️ Pontos de Atenção para Implementação

1. **Plant.id API:** O plano gratuito tem limite de requisições. Fazer o identify apenas quando o usuário clicar no botão, nunca automaticamente.

2. **Notificações no Android 13+:** Solicitar permissão `POST_NOTIFICATIONS` em runtime usando `permission_handler`.

3. **Upload de imagem para Supabase Storage:** Fazer o upload antes de salvar a planta no banco, usar a URL retornada no campo `photo_url`.

4. **Riverpod:** Usar `AsyncNotifierProvider` para os providers que fazem chamadas assíncronas (plantas, cuidados). Usar `StateNotifierProvider` para estado de UI (loading, erro).

5. **GoRouter:** Configurar redirect na rota raiz para verificar sessão do Supabase antes de decidir para onde navegar.

6. **Tratamento de erros:** Toda chamada de API deve ter:
   - Estado de loading (mostrar `CircularProgressIndicator`)
   - Estado de erro (mostrar `SnackBar` com mensagem amigável)
   - Estado de sucesso

7. **Imagens em cache:** Usar `cached_network_image` para não recarregar fotos já baixadas.

---

## 📹 Roteiro do Vídeo Demonstrativo

1. **Problema (30s):** Mostrar plantas esquecidas, falar sobre o problema de esquecer de cuidar
2. **Solução (30s):** Apresentar o ReggieApp e suas funcionalidades principais
3. **Demo — Cadastro (60s):** Abrir câmera → tirar foto → identificação automática → salvar planta
4. **Demo — Notificação (30s):** Mostrar notificação chegando no celular
5. **Demo — Detalhes e Compartilhamento (30s):** Abrir planta → registrar cuidado → compartilhar
6. **Considerações finais (30s):** Tecnologias usadas, aprendizados, possíveis evoluções