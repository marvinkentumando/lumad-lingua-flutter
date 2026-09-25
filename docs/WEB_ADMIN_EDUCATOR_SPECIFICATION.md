# Lumad Lingua - Web Admin & Educator Specification & Parity Checklist

This document serves as the official specification and validation checklist to ensure that the **Web Version** of the **Administrator** and **Educator** panels maintains complete design, feature, data model, and security parity with the mobile/core app architecture.

---

## 🎯 Purpose & Scope
The web dashboard allows Administrators and Educators to manage learning materials, review native-speaker audio recordings, govern user roles, monitor digital language vitality, and publish content directly to desktop and tablet browsers without intermediate validator queues.

---

## 🔐 1. Role-Based Access Control (RBAC) & Authentication

### Role Definitions
- **`admin`**: Full system governance, user role modification, system configuration, audit log viewing, sentiment dashboard overrides, and global content oversight.
- **`educator`**: Direct publishing and editing of lessons, direct audio reference upload, vocabulary entry management, and Leitner SRS parameter configuration.
- **`learner`**: Read-only mobile/web learning participant.

### Web Parity Checklist - Security & Auth
- [ ] **Firebase Auth Integration**: Web authentication uses standard Firebase Auth credentials and persistent sessions (`Persistence.LOCAL`).
- [ ] **Role Claims Check**: Web router (`GoRouter`) guards restrict route access based on custom claims or user document `role` field from Firestore (`users/{uid}`).
- [ ] **Route Protection**: Direct URL navigation to `/admin/*` or `/educator/*` redirects non-authorized users to `/login` or unauthorized landing page.
- [ ] **Firestore Security Rules Consistency**: Security rules validate `request.auth.token.role` or `get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role` across both Web and Mobile calls.

---

## 🎨 2. Design System & UI Consistency Guidelines

### Cultural Color Palette (Lumad Lingua Theme)
To maintain visual identity across Web and Mobile, all web interfaces must strictly implement the brand theme colors:
- **Primary / Heritage Gold**: `#D4AF37` / `Colors.amber`
- **Secondary / Forest Green**: `#1E4D2B` / `Colors.green[900]`
- **Background / Cream Paper**: `#FDFBF7`
- **Surface / Dark Container**: `#2D3748` / `#1A202C` (for dark mode or high-contrast cards)
- **Accent / Warm Ochre**: `#C86400`

### Desktop Responsive Web Layout Standard
- [ ] **Navigation Shell**: Persistent collapsible Sidebar for Desktop (`>1024px`), Drawer for Tablet/Mobile (`<1024px`).
- [ ] **Top App Bar**: Displays current User Profile, Role Badge (`Administrator` / `Educator`), Language Context (`Mansaka`), and Notification/Audit Indicator.
- [ ] **Data Tables & Grid Views**: Data grids for users, lessons, and vocabulary include sorting, pagination, and quick-filter bars.
- [ ] **Live Mobile Preview Panel**: Educator Lesson Editor includes a side-by-side mobile emulator frame showing real-time preview of student view.

---

## 📚 3. Educator Web Dashboard Specifications

### Core Modules & Features
1. **Lesson & Curriculum Builder (`/educator/lessons`)**
   - [ ] Multi-step lesson builder: Title, Category, Cultural Context, Flashcards, and Interactive Quizzes.
   - [ ] Direct publishing: Content is published immediately to production collections upon saving.
   - [ ] Drag-and-drop reordering for lesson steps and vocabulary cards.
   - [ ] Rich-text field editor for cultural notes and usage examples.
   - [ ] Spaced Repetition System (SRS) interval metadata configuration.

2. **Audio & Media Asset Manager (`/educator/media`)**
   - [ ] Supabase Storage Web Upload integration for native speaker WAV/MP3 files (< 10 MB).
   - [ ] In-browser Web Audio Waveform visualizer & playback comparison tool.
   - [ ] Binds uploaded reference audio directly to dictionary entries (`words/{wordId}`) or lesson prompts.

3. **Analytics & Student Performance (`/educator/analytics`)**
   - [ ] Progress reports across assigned student cohorts.
   - [ ] Pronunciation accuracy breakdown (DTW score distribution across classes).

---

## 🛡️ 4. Administrator Web Dashboard Specifications

### Core Modules & Features
1. **User & Role Management (`/admin/users`)**
   - [ ] Searchable user list with role filtering (`admin`, `educator`, `learner`).
   - [ ] Role promotion / demotion dialog with confirmation prompt.
   - [ ] Account status toggles (`active`, `suspended`) with reason field.

2. **Content Management & Direct Administration (`/admin/content`)**
   - [ ] Direct management overview of active dictionary terms, voice recordings, and published lessons.
   - [ ] Admin powers to directly edit, unpublish, or archive any content across the platform.

3. **Audit Log System (`/admin/audit-logs`)**
   - [ ] Real-time stream of `AuditLogEntry` records (`action`, `actorId`, `targetType`, `timestamp`).
   - [ ] Filter by activity type (`word_created`, `user_role_updated`, `lesson_published`).

4. **Sentiment & Language Vitality Monitor (`/admin/vitality`)**
   - [ ] Sentiment distribution dashboard for Mansaka digital presence (Positive, Negative, Neutral).
   - [ ] Manual override & recalibration panel for AI/keyword sentiment classification outputs.

---

## 💾 5. Shared Firestore Data Structures & Parity

To ensure the Web and Mobile apps stay perfectly synchronized, both platforms must write to and read from identical Firestore schemas:

```yaml
collections:
  users/{userId}:
    - role: string ("admin" | "educator" | "learner")
    - name: string
    - email: string
    - status: string ("active" | "suspended")
    - xp: number
    - wordCount: number
    - createdAt: timestamp
    
  words/{wordId}:
    - term: string
    - dialect: string ("Mansaka")
    - filipinoTranslation: string
    - englishTranslation: string
    - audioUrl: string
    - status: string ("published" | "archived")
    - contributorId: string
    - createdAt: timestamp

  lessons/{lessonId}:
    - title: string
    - category: string
    - difficulty: string
    - steps: array of maps
    - status: string ("published" | "draft")
    - educatorId: string
    - createdAt: timestamp

  audit_logs/{logId}:
    - action: string
    - actorId: string
    - actorName: string
    - targetId: string
    - targetType: string
    - timestamp: timestamp
    - metadata: map
```

---

## 🚀 6. Testing & Deployment Verification Checklist

Before publishing the web build (`flutter build web`), verify the following:

- [ ] **Cross-Browser Compatibility**: Test on Chrome, Edge, Firefox, and Safari Desktop.
- [ ] **Web Media Compatibility**: Audio recording (`record` package) and playback (`audioplayers`) function properly in browser environments.
- [ ] **File Picker Support**: File selection for native speaker audio uploads uses web-compatible bytes/blobs.
- [ ] **No Hardcoded Platform Code**: Code checks `kIsWeb` before executing mobile-only platform channels (e.g. native path providers or Android-specific plugins).
- [ ] **Environment Configuration**: Web build correctly loads `.env` or Firebase Web configuration parameters.
- [ ] **Build Output Check**: Static web assets generated cleanly inside `build/web/`.


