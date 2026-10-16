# HARD Platform — UML Class Diagram

This document contains the complete UML Class Diagram for the **HARD** backend architecture, database entities, and their relationships.

---

```mermaid
classDiagram
    direction TB

    %% ================= CORE DOMAIN =================
    class User {
        +UUID id
        +String username
        +String email
        +String password
        +Int level
        +Int currentXp
        +Int totalXp
        +Int streak
        +DateTime lastActiveAt
        +DateTime createdAt
        +DateTime updatedAt
    }

    class Workout {
        +UUID id
        +UUID userId
        +String name
        +DateTime date
        +Int duration
        +Float totalVolume
        +Text notes
        +DateTime createdAt
        +DateTime updatedAt
    }

    class Exercise {
        +UUID id
        +String name
        +String muscleGroup
        +Text instructions
        +Text formTips
        +JSON alternatives
        +String imageUrl
        +String videoUrl
        +DateTime createdAt
        +DateTime updatedAt
    }

    class WorkoutExercise {
        +UUID id
        +UUID workoutId
        +UUID exerciseId
        +Int sets
        +Int reps
        +Float weight
        +Int order
        +DateTime createdAt
        +DateTime updatedAt
    }

    %% ================= AI & RAG DOMAIN =================
    class Embedding {
        +UUID id
        +UUID exerciseId
        +JSON vector
        +DateTime createdAt
        +DateTime updatedAt
    }

    class Conversation {
        +UUID id
        +UUID userId
        +String title
        +DateTime createdAt
        +DateTime updatedAt
    }

    class Message {
        +UUID id
        +UUID conversationId
        +String role
        +Text content
        +DateTime createdAt
        +DateTime updatedAt
    }

    %% ================= GAMIFICATION DOMAIN =================
    class XpLog {
        +UUID id
        +UUID userId
        +Int amount
        +String type
        +String description
        +DateTime createdAt
        +DateTime updatedAt
    }

    class Achievement {
        +UUID id
        +UUID userId
        +String type
        +String name
        +Text description
        +String badgeIcon
        +DateTime unlockedAt
    }

    %% ================= RELATIONSHIPS =================
    User "1" --> "0..*" Workout : logs
    Workout "1" *-- "1..*" WorkoutExercise : contains
    Exercise "1" <-- "0..*" WorkoutExercise : references
    Exercise "1" *-- "0..1" Embedding : vector representation

    User "1" --> "0..*" Conversation : owns
    Conversation "1" *-- "0..*" Message : contains

    User "1" --> "0..*" XpLog : earns
    User "1" --> "0..*" Achievement : unlocks
```

---

## 🏛️ Domain Breakdown

| Module | Entities | Key Responsibilities |
| :--- | :--- | :--- |
| **Core & Tracking** | `User`, `Workout`, `Exercise`, `WorkoutExercise` | User account lifecycle, workout execution logging, set/rep/weight tracking, and automatic volume recalculation. |
| **AI & RAG** | `Embedding`, `Conversation`, `Message` | 384-dimensional dense vectors for semantic similarity search, multi-turn chat persistence with user isolation. |
| **Gamification** | `XpLog`, `Achievement` | Immutable XP audit ledger, leveling mechanics, and milestone badge achievements. |
