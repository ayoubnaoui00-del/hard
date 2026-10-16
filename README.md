# 📋 CAHIER DES CHARGES — APPLICATION « HARD »
> **Plateforme Mobile Intelligente d'Entraînement et de Coaching Fitness Assisté par IA**
> 
> *Version : 1.0.0 — Production Ready | Date : Octobre 2026*

---

## 📑 Sommaire
1. [Présentation Générale & Vision du Projet](#1-présentation-générale--vision-du-projet)
2. [Périmètre Fonctionnel (Spécifications Fonctionnelles)](#2-périmètre-fonctionnel-spécifications-fonctionnelles)
3. [Architecture Technique & Stack Technologique](#3-architecture-technique--stack-technologique)
4. [Moteur d'Intelligence Artificielle (DeepSeek & RAG Pinecone)](#4-moteur-dintelligence-artificielle-deepseek--rag-pinecone)
5. [Spécifications des Données & Schéma Relationnel](#5-spécifications-des-données--schéma-relationnel)
6. [Design System & Expérience Utilisateur (UI/UX)](#6-design-system--expérience-utilisateur-uiux)
7. [Exigences Non-Fonctionnelles (Sécurité, Performance, Robustesse)](#7-exigences-non-fonctionnelles-sécurité-performance-robustesse)
8. [Plan de Test & Assurance Qualité](#8-plan-de-test--assurance-qualité)
9. [Guide d'Installation & Démarrage](#9-guide-dinstallation--démarrage)

---

## 1. Présentation Générale & Vision du Projet

### 1.1 Contexte & Problématique
Les applications de fitness conventionnelles se limitent généralement à des feuilles de calcul déguisées en carnets de bord numériques (saisie passive des répétitions, absence de rétroaction dynamique, manque d'adaptation aux charges et à la fatigue). À l'inverse, l'accompagnement par un coach sportif humain demeure onéreux et inaccessible pour une grande majorité de pratiquants.

### 1.2 Objectif de l'Application « HARD »
**HARD** comble ce fossé en fusionnant :
1. **Un suivi d'entraînement de précision** avec calcul instantané du volume ($\sum \text{poids} \times \text{reps}$) et estimations du 1RM.
2. **Un modèle anatomique 3D interactif (WebGL)** pour visualiser et cibler intuitivement les groupes musculaires.
3. **Un Coach IA autonome en temps réel (DeepSeek + RAG Pinecone)** capable de raisonner sur les sciences de l'exercice, d'exécuter des actions concrètes dans la base de données (Function Calling) et de diffuser ses conseils en streaming (SSE).
4. **Un moteur de gamification personnelle infalsifiable** reposant sur un grand livre d'audit d'XP, des séries de jours consécutifs (*streaks*) et des badges de jalons.

### 1.3 Cible Utilisateur
- Athlètes débutants à confirmés pratiquant la musculation, le powerlifting ou le fitness fonctionnel.
- Pratiquants recherchant des conseils personnalisés sur la surcharge progressive et l'exécution technique des mouvements sans frais d'abonnement exorbitants.

---

## 2. Périmètre Fonctionnel (Spécifications Fonctionnelles)

```mermaid
mindmap
  root((HARD Mobile App))
    Authentification & Sécurité
      Inscription & Connexion JWT
      Stockage Sécurisé Keychain
      Profil & Métriques Athlète
    Bibliothèque d'Exercices
      1 324 Mouvements Détaillés
      Modèle Anatomique 3D WebGL
      Filtres Multi-Critères
      Démonstrations Vidéo/GIF
    Journalisation des Séances
      Enregistrement Séries / Répétitions / RPE
      Calculateur de Volume Automatique
      Historique & Statistiques
    Coach IA & RAG
      Dialogue Contextuel Streaming SSE
      RAG Vectoriel Pinecone 1024-dim
      Function Calling 8 Outils Autonomes
    Gamification Personnelle
      Grand Livre d'Audit XP
      Niveaux & Courbe de Progression
      Séries de Jours Consécutifs
      Badges & Accomplissements
```

### 2.1 Authentification & Gestion des Profils
- **Authentification Stateless JWT** : Tokens d'accès (courte durée : 15 min) et tokens de rafraîchissement (longue durée : 7 jours) persistés dans le Keychain/Keystore sécurisé via `flutter_secure_storage`.
- **Validation Robuste** : Validation des e-mails, hachage irréversible des mots de passe (`bcryptjs`, sel à 10 tours) et protection contre les injections.
- **Gestion du Profil** : Suivi des métriques physiques (poids, taille, niveau d'expérience, objectifs de force ou d'hypertrophie).

### 2.2 Bibliothèque d'Exercices & Modèle Anatomique 3D
- **Catalogue de 1 324 exercices** : Classés par groupes musculaires primaires, muscles secondaires, niveau de difficulté, équipements (Barbell, Dumbbell, Machine, Cable, Bodyweight) et catégories (Hypertrophy, Strength, Endurance, Mobility).
- **Modèle Anatomique 3D Interactif** :
  - Intégration d'un canevas 3D WebGL local (`Three.js`) servi sans latence par un serveur HTTP loopback embarqué.
  - Sélection par raycasting des maillages musculaires anatomiques (Poitrine, Épaules, Bras, Dos, Jambes, Abdominaux).
  - Synchronisation bidirectionnelle : cliquer sur un muscle (ex. les Bras) filtre instantanément les mouvements correspondants (**Biceps**, **Triceps**, **Avant-bras**).
  - Démonstrations vidéo animées et conseils de placement biomécanique pour chaque exercice.

### 2.3 Journalisation & Métriques d'Entraînement
- **Création de Séance en Temps Réel** : Ajout d'exercices, saisie des séries, répétitions, charges (kg/lbs) et indice de perception de l'effort (RPE).
- **Moteur de Volume Automatique** : Calcul automatique du tonnage total ($\sum \text{poids} \times \text{reps}$) et comparaison avec les séances précédentes pour valider la surcharge progressive.
- **Minuteur de Récupération Intégré** : Compte à rebours dynamique entre les séries.

### 2.4 Gamification Personnelle
- **Grand Livre d'Audit des XP (`XpLogs`)** : Toute progression d'expérience est journalisée de manière immuable avec horodatage, action déclencheuse et volume associé (garantie anti-triche).
- **Courbe de Niveaux** : Formule de montée en niveau progressive récompensant la régularité et le volume soulevé.
- **Série d'Entraînement (`Streaks`)** : Calcul des jours consécutifs d'entraînement avec bonus multiplicateur d'XP.
- **Badges d'Accomplissement** : Déverrouillage automatique de distinctions (Premier Pas, Guerrier de l'Échauffement, Club des Centurion, Palier de Niveau).

### 2.5 Coach IA Conversationnel Autonome
- **Interface de Chat Haute Performance** : Échange fluide en langage naturel avec streaming temps réel (Server-Sent Events).
- **Exécution d'Actions Autonomes (8 Outils DB)** :
  1. `logWorkout` : Enregistre une séance complète directement depuis la conversation.
  2. `getUserStats` : Récupère le niveau, le total d'XP, le streak et le volume cumulé à vie.
  3. `getRecentWorkouts` : Analyse l'historique récent pour recommander la charge optimale.
  4. `addXp` : Crédite de l'expérience avec justification tracée.
  5. `checkAchievements` : Évalue et attribue les badges débloqués.
  6. `suggestNextExercise` : Conseille l'exercice complémentaire basé sur les muscles non sollicités.
  7. `generateWorkoutPlan` : Génère une routine structurée au format JSON (échauffement, séries de travail, retour au calme).
  8. `updateStreak` : Met à jour la série de jours consécutifs.

---

## 3. Architecture Technique & Stack Technologique

```
┌────────────────────────────────────────────────────────────────────────┐
│                   CLIENT MOBILE : FLUTTER (DART 3.x)                  │
│  • MVVM + Riverpod Reactive State Management                           │
│  • GoRouter Declarative Routing with Left-to-Right Screen Transitions  │
│  • Dio Interceptor-based Networking with Secure Keychain Storage       │
│  • WebGL Three.js Interactive 3D Anatomy Model via Loopback Server     │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ HTTPS REST & SSE Streaming
┌───────────────────────────────────▼────────────────────────────────────┐
│                    SERVEUR BACKEND : NODE.JS / EXPRESS                 │
│  • API REST Modulaire (Routes, Contrôleurs, Middlewares JWT)          │
│  • Sequelize ORM avec Migrations PostgreSQL                            │
│  • Agent Tool Dispatcher (8 Outils Autonomes avec Validation Schéma)   │
└───────────────▲───────────────────────────────────────▲────────────────┘
                │ SQL Queries                           │ API REST / Embeddings
┌───────────────▼────────────────────────┐ ┌────────────▼────────────────┐
│      BASE DE DONNÉES POSTGRESQL        │ │        ÉCOSYSTÈME IA        │
│  • Tables Relationnelles CASCADÉES     │ │  • DeepSeek API (LLM)       │
│  • Audit Immuable (XpLogs)             │ │  • Pinecone Vector DB (RAG) │
│  • 1 324 Exercices Pré-ensemencés      │ │  • llama-text-embed-v2      │
└────────────────────────────────────────┘ └─────────────────────────────┘
```

### 3.1 Stack Mobile Frontend
| Composant | Technologie | Justification |
| :--- | :--- | :--- |
| **Framework** | Flutter (Dart 3.x) | Performance native 60+ FPS sur iOS et Android à partir d'une base de code unique. |
| **Pattern** | MVVM | Séparation stricte de la logique métier, de l'état réactif et de la vue. |
| **State Management** | `flutter_riverpod` | Gestion d'état compile-safe, testable et dépourvue de boilerplate contextuel. |
| **Navigation** | `go_router` | Routage déclaratif, gardes d'authentification et transitions animées cinématiques. |
| **Réseau** | `dio` | Intercepteurs d'attachement JWT automatique, cycle de refresh token et support SSE. |
| **Persistance** | `flutter_secure_storage` | Chiffrement matériel Keychain (iOS) et AES-GCM Keystore (Android). |
| **3D Rendering** | WebGL / Three.js | Rendu interactif du corps humain avec coloration dynamique des maillages musculaires. |

### 3.2 Stack Serveur Backend
| Composant | Technologie | Justification |
| :--- | :--- | :--- |
| **Runtime** | Node.js (ES Modules) | Vitesse d'exécution I/O asynchrone idéale pour les flux temps réel (SSE). |
| **Framework Web** | Express.js | Simplicité, légèreté et extensibilité des middlewares de sécurité. |
| **ORM** | Sequelize ORM | Schémas relationnels typés, migrations versionnées et sécurité contre les injections SQL. |
| **Base de Données** | PostgreSQL | Robustesse ACID, intégrité référentielle en cascade et support des métriques volumétriques. |

---

## 4. Moteur d'Intelligence Artificielle (DeepSeek & RAG Pinecone)

### 4.1 Architecture RAG (Retrieval-Augmented Generation)
Pour garantir que le Coach IA ne commette aucune hallucination biomécanique :
1. **Génération d'Embeddings Sémantiques** : L'invite utilisateur est convertie en vecteur dense de 1 024 dimensions via l'API d'inférence Pinecone (`llama-text-embed-v2`).
2. **Recherche par Similarité Cosinus** : Le vecteur est comparé à la base vectorielle des 1 324 exercices indexés pour extraire les mouvements les plus pertinents.
3. **Injection Contextuelle** : Les consignes d'exécution, conseils de placement et variantes sont directement injectés dans le *System Prompt* de DeepSeek avant toute génération de réponse.

### 4.2 Séquence d'Exécution du Function Calling

```mermaid
sequenceDiagram
    autonumber
    actor Athlète as Athlète (Flutter App)
    participant Backend as Serveur Express (AgentService)
    participant DeepSeek as DeepSeek AI (deepseek-chat)
    participant Tools as AgentToolService
    participant DB as PostgreSQL

    Athlète->>Backend: POST /agent/chat (Message: "Je viens de faire 4x10 au développé couché à 80kg")
    Backend->>DeepSeek: Envoi du prompt système + Historique + Définition des 8 outils
    DeepSeek-->>Backend: Détection d'intention : tool_calls = logWorkout(...)
    Backend->>Tools: handleLogWorkout(userId, { name, exercises, duration })
    Tools->>DB: INSERT INTO Workouts & WorkoutExercises
    Tools->>DB: Calcul du Volume Total & Mise à jour Streak
    Tools->>DB: INSERT INTO XpLogs (+XP) & Évaluation Badges
    DB-->>Tools: Confirmation transactionnelle
    Tools-->>Backend: Résultat de l'outil (ID, Volume, XP gagnés)
    Backend->>DeepSeek: Résultat de l'outil injecté en rôle 'tool'
    DeepSeek-->>Backend: Flux SSE final de coaching ("Excellent travail ! 3 200 kg validés...")
    Backend-->>Athlète: Diffusion en continu SSE (Tokens + Tool Status)
```

---

## 5. Spécifications des Données & Schéma Relationnel

```mermaid
erDiagram
    USERS ||--o{ WORKOUTS : logs
    USERS ||--o{ ACHIEVEMENTS : earns
    USERS ||--o{ CONVERSATIONS : owns
    USERS ||--o{ XP_LOGS : records
    WORKOUTS ||--o{ WORKOUT_EXERCISES : contains
    EXERCISES ||--o{ WORKOUT_EXERCISES : referenced_in
    EXERCISES ||--o| EMBEDDINGS : has
    CONVERSATIONS ||--o{ MESSAGES : contains

    USERS {
        uuid id PK
        string username UK
        string email UK
        string password
        int level
        int currentXp
        int totalXp
        int streak
        timestamp lastActiveAt
    }

    EXERCISES {
        uuid id PK
        string name UK
        string muscleGroup
        text instructions
        text formTips
        json alternatives
    }

    WORKOUTS {
        uuid id PK
        uuid userId FK
        string name
        int duration
        float totalVolume
        text notes
        timestamp date
    }

    WORKOUT_EXERCISES {
        uuid id PK
        uuid workoutId FK
        uuid exerciseId FK
        json sets
        int orderIndex
    }

    XP_LOGS {
        uuid id PK
        uuid userId FK
        int amount
        string source
        string description
        timestamp createdAt
    }

    ACHIEVEMENTS {
        uuid id PK
        uuid userId FK
        string badgeId
        string title
        timestamp unlockedAt
    }
```

---

## 6. Design System & Expérience Utilisateur (UI/UX)

### 6.1 Identité Visuelle « Forest Noir & Velocity »
- **Background Principal** : `Forest Noir Dark` (`#02060E` — Midnight Noir profond).
- **Couleur Signature** : `Velocity Lime` (`#CEFA2B` — Vert électrique haute énergie).
- **Accents Secondaires** :
  - `Electric Tech Blue` (`#2979FF`) pour les modules techniques et musculaires (Dos).
  - `Punchy Coral` (`#FF5252`) pour les alertes et le ciblage Pectoraux.
  - `Warm Amber` (`#FFB300`) pour les streaks et récompenses d'XP.
- **Surfaces Élevées** : `Titanium Slate` (`#141822`) avec bordures raffinées (`#232C3A`).

### 6.2 Cinématique & Micro-Animations
1. **Écran d'Accueil / Splash Screen** :
   - Apparition ultra-fluide du logo HARD au centre avec fondu et mise à l'échelle élastique (`950ms`).
   - Maintien pendant 6 secondes avec une pulsation discrète simulant la respiration au repos d'un athlète.
   - Glissement fluide vers la droite (`Curves.easeInOutCubic`) au terme des 6 secondes ou au toucher.
2. **Transition vers l'Interface Principale** :
   - L'écran de connexion ou le tableau de bord principal glisse élégamment de la gauche vers la droite (`Offset(-1.0, 0.0)` $\rightarrow$ `Offset.zero`), prolongeant le mouvement naturel du logo.
3. **Modèle 3D Interactif** :
   - Rotation fluide de la caméra à 360°, passage instantané Vue de Face $\leftrightarrow$ Vue de Dos et surbrillance néon des groupes musculaires cliqués.

---

## 7. Exigences Non-Fonctionnelles (Sécurité, Performance, Robustesse)

### 7.1 Sécurité
- Chiffrement symétrique des tokens JWT stockés en environnement client.
- Déconnexion automatique et invalidation des sessions à l'expiration des refresh tokens.
- Nettoyage des données en cascade (`CASCADE DELETE`) empêchant tout orphelinat en base de données.
- Isolation stricte des données : un utilisateur ne peut accéder ni modifier les séances, messages de chat ou métriques d'un tiers.

### 7.2 Performance & Fluidité
- Temps de réponse de l'API REST $< 50$ ms sur les requêtes paginées.
- Rendu du modèle 3D sans dépendance à une connexion internet grâce au serveur HTTP embarqué.
- Défilement à 60 FPS garanti dans la liste des 1 324 exercices via la pagination optimisée.
- Streaming SSE du Coach IA avec premier token affiché en $< 600$ ms.

---

## 8. Plan de Test & Assurance Qualité

Le projet applique une couverture de tests automatisés à 100 % sur l'ensemble des modules critiques :

| Suite de Tests | Périmètre Validé | Tests | Statut |
| :--- | :--- | :---: | :---: |
| **Auth & Security** | Inscription, connexion, validation JWT, hachage, isolation utilisateur | 17 | ✅ 100% |
| **Catalog & Exercises** | Récupération paginée, recherche, filtres musculaires (Bras = Biceps + Triceps + Avant-bras) | 16 | ✅ 100% |
| **Workouts & Gamification** | Calcul du volume, enregistrement des séries, grand livre d'XP, streaks | 4 | ✅ 100% |
| **Chat Sessions & Memory** | Création de conversation, historique, suppression cascade | 14 | ✅ 100% |
| **RAG Vector Retrieval** | Similarité cosinus, embedding 1024-dim, injection de contexte | 11 | ✅ 100% |
| **Autonomous Function Calling** | Exécution des 8 outils, validation des schémas d'arguments, fallbacks | 20 | ✅ 100% |
| **SSE Streaming Endpoint** | Connexion SSE, émission de chunks, token de fin | 6 | ✅ 100% |
| **Flutter Widget & MVVM Tests** | Rendu de la vue Welcome, navigation, écran 3D, sélecteur musculaire | 60 | ✅ 100% |
| **TOTAL** | **Validation globale Backend + Frontend** | **148** | **✅ 100% PASS** |

---

## 9. Guide d'Installation & Démarrage

### 9.1 Prérequis
- **Node.js** $\ge$ v18.x
- **Flutter SDK** $\ge$ 3.x
- **PostgreSQL** $\ge$ 14.x
- Clé d'API **DeepSeek** & Clé d'API **Pinecone**

### 9.2 Configuration du Backend
1. Se positionner dans le répertoire backend :
   ```bash
   cd backend
   npm install
   ```
2. Configurer les variables d'environnement (`backend/.env`) :
   ```env
   PORT=3000
   DATABASE_URL=postgres://postgres:password@127.0.0.1:5432/hard_development
   JWT_SECRET=votre_cle_secrete_jwt_access
   JWT_REFRESH_SECRET=votre_cle_secrete_jwt_refresh
   
   DEEPSEEK_API_KEY=votre_cle_api_deepseek
   DEEPSEEK_BASE_URL=https://api.deepseek.com
   DEEPSEEK_MODEL=deepseek-chat

   PINECONE_API_KEY=votre_cle_api_pinecone
   PINECONE_INDEX=hard
   PINECONE_EMBED_MODEL=llama-text-embed-v2
   ```
3. Exécuter les migrations et le chargement des exercices :
   ```bash
   npx sequelize-cli db:migrate
   npm run seed:exercises
   ```
4. Démarrer le serveur backend :
   ```bash
   npm run dev
   ```

### 9.3 Lancement du Frontend Flutter
1. Se positionner dans le répertoire frontend :
   ```bash
   cd frontend
   flutter pub get
   ```
2. Lancer la suite de tests de validation :
   ```bash
   flutter test
   ```
3. Lancer l'application sur un émulateur ou appareil connecté :
   ```bash
   flutter run
   ```

---
*Document certifié conforme aux spécifications architecturales et fonctionnelles de la plateforme HARD.*
