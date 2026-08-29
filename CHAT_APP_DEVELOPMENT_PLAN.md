# 🚀 Secret Real-Time Chat & Calling App — Phase-Wise Development Plan
**Role:** Senior Mobile App Architect & Lead Flutter Engineer  
**Target Platform:** Android (Flutter)  
**Project Integration:** Embedded stealth module within Readify (Secret Easter Egg Trigger)

---

## 📑 Executive Architectural Summary

This document establishes the end-to-end, production-grade development roadmap for a modern, offline-first, real-time messaging and audio/video calling application built directly into the Readify ecosystem.

```
┌────────────────────────────────────────────────────────────────────────┐
│                          READIFY HOST APP                              │
│         (PDF Viewer • Documents • Settings • Dark Mode)                │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │ (Settings: 3 Rapid Taps on Version)
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        SECRET CHAT MODULE                              │
│                                                                        │
│  ┌───────────────────────┐                  ┌──────────────────────┐  │
│  │   UI & PRESENTATION   │                  │     CALL ENGINE      │  │
│  │ Chats • Calls • Req   │                  │ ZegoCloud Audio/Video│  │
│  │ Profile • Room UI     │                  │ 10,000 Mins / Month  │  │
│  └───────────┬───────────┘                  └──────────┬───────────┘  │
│              │                                         │              │
│  ┌───────────▼───────────┐                  ┌──────────▼───────────┐  │
│  │    SYNC ORCHESTRATOR  │                  │  MEDIA PLAYBACK/REC  │  │
│  │  connectivity_plus    │                  │  just_audio • record │  │
│  │  Queue Auto-Dispatcher│                  │  video_player • dio  │  │
│  └─────┬───────────┬─────┘                  └──────────┬───────────┘  │
│        │           │                                   │              │
│  ┌─────▼─────┐   ┌─▼───────────────────────────────────▼───────────┐  │
│  │  FIREBASE │   │             LOCAL DEVICE STORAGE                │  │
│  │ Auth/Cloud│   │  ┌─────────────────────┐ ┌───────────────────┐  │  │
│  │ Firestore │   │  │   SQLite (sqflite)  │ │ File Disk Storage │  │  │
│  │  Storage  │   │  │ Metadata & Messages │ │ .mp4/.m4a/.jpg    │  │  │
│  └───────────┘   │  └─────────────────────┘ └───────────────────┘  │  │
│                  └─────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Complete Technology Matrix

| Layer / Capability | Technology Selected | Responsibility |
|---|---|---|
| **Framework & UI** | Flutter 3.x / Dart 3.x | Cross-platform UI, Material 3, Dark/Light theming |
| **Authentication** | `firebase_auth` | Email & Password authentication (100% Free / Unlimited) |
| **Realtime Cloud DB** | `cloud_firestore` | Live chat streams, user directory, friend requests |
| **Cloud Media Storage** | `firebase_storage` | Remote file bucket for photos, voice notes, video clips |
| **Local Relational DB** | `sqflite` + `path` | Relational offline storage, message status tracking (`pending`, `sent`, `delivered`, `read`) |
| **Local Disk Storage** | `path_provider` + `dio` | Downloading & saving raw `.mp4`, `.m4a`, `.jpg` to app sandbox |
| **Media Caching** | `cached_network_image` | In-memory and on-disk image/avatar caching |
| **Calling (VoIP & Video)**| `zego_uikit_prebuilt_call` | 1-on-1 audio & video calling with native call UI (10k free min/mo) |
| **Voice Notes & Audio** | `record` + `just_audio` | Voice note recorder with waveform and local audio player |
| **Video Playback** | `video_player` + `chewie` | In-app video preview and playback for offline/online video |
| **Network & Queue** | `connectivity_plus` | Real-time network state monitoring & background dispatch queue |
| **State Management** | `provider` | Decoupled reactive state across views and services |
| **Utilities** | `intl`, `uuid`, `image_picker` | Timestamps, unique payload IDs, camera/gallery picking |

---

# 📅 Phase-Wise Implementation Roadmap

```mermaid
gantt
    title Development Phases
    dateFormat  YYYY-MM-DD
    section Core & Storage
    Phase 1: Environment & Firebase Setup      :p1, 2026-09-01, 2d
    Phase 2: SQLite & Offline Storage Engine   :p2, after p1, 3d
    section Auth & Social
    Phase 3: Auth System & Profiles           :p3, after p2, 3d
    Phase 4: Friend Request & Contact Graph    :p4, after p3, 2d
    section Chat & Media
    Phase 5: Real-Time Messaging & Sync Engine :p5, after p4, 4d
    Phase 6: Rich Media Engine (Voice/Video)   :p6, after p5, 4d
    section Calling & Integration
    Phase 7: ZegoCloud Calling Engine          :p7, after p6, 3d
    Phase 8: Tabs, Navigation & Stealth Gate   :p8, after p7, 2d
    section QA & Release
    Phase 9: Security, Edge Cases & Testing    :p9, after p8, 3d
    Phase 10: Production Release & ProGuard    :p10, after p9, 2d
```

---

## 📍 Phase 1: Environment, Dependencies & Firebase Initialization
**Goal:** Prepare the Flutter project, establish the secret directory hierarchy, and link Firebase services without breaking Readify's existing PDF functions.

### Tasks:
1. **`pubspec.yaml` Dependency Upgrade**:
   Add all necessary packages with version pinning to avoid dependency conflicts.
2. **Android Configuration**:
   - Update `android/app/build.gradle`:
     - `minSdkVersion 21` (or 23 for ZegoCloud).
     - `compileSdkVersion 34`.
     - Enable `multiDexEnabled true`.
   - Update `android/app/src/main/AndroidManifest.xml`:
     - Add camera, microphone, internet, and storage permissions:
       ```xml
       <uses-permission android:name="android.permission.INTERNET"/>
       <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
       <uses-permission android:name="android.permission.RECORD_AUDIO"/>
       <uses-permission android:name="android.permission.CAMERA"/>
       <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
       <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
       <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
       <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
       <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
       ```
3. **Firebase Project Setup**:
   - Register Android package `com.example.readify` in Firebase Console.
   - Download and place `google-services.json` in `android/app/`.
   - Enable **Firebase Authentication (Email/Password)**.
   - Enable **Cloud Firestore** and **Firebase Storage**.
4. **Project Directory Structuring**:
   Create a dedicated, modular folder structure inside `lib/chat/`:
   ```
   lib/chat/
   ├── core/
   │   ├── constants/
   │   ├── theme/
   │   └── utils/
   ├── models/
   │   ├── user_model.dart
   │   ├── message_model.dart
   │   ├── chat_model.dart
   │   ├── friend_request_model.dart
   │   └── call_log_model.dart
   ├── services/
   │   ├── auth_service.dart
   │   ├── firestore_service.dart
   │   ├── sqlite_service.dart
   │   ├── storage_service.dart
   │   ├── sync_service.dart
   │   ├── media_service.dart
   │   └── call_service.dart
   ├── providers/
   │   ├── auth_provider.dart
   │   ├── chat_provider.dart
   │   ├── friend_provider.dart
   │   └── call_provider.dart
   ├── screens/
   │   ├── auth/
   │   │   ├── login_screen.dart
   │   │   ├── register_screen.dart
   │   │   └── forgot_password_screen.dart
   │   ├── main_chat_host_screen.dart
   │   ├── tabs/
   │   │   ├── chats_tab.dart
   │   │   ├── calls_tab.dart
   │   │   ├── requests_tab.dart
   │   │   └── profile_tab.dart
   │   ├── chat_room/
   │   │   ├── chat_room_screen.dart
   │   │   └── media_viewer_screen.dart
   │   └── search/
   │       └── search_users_screen.dart
   └── widgets/
       ├── chat_bubble.dart
       ├── audio_player_widget.dart
       ├── voice_record_bar.dart
       ├── video_thumbnail_widget.dart
       └── call_tile.dart
   ```

---

## 📍 Phase 2: SQLite Local Database & Disk Storage Architecture
**Goal:** Implement the local database engine and disk storage manager to support offline-first operation.

### Tasks:
1. **`SqliteService` Implementation**:
   Build `DatabaseHelper` singleton managing the SQLite database (`readify_chat.db`).
2. **Database Table Creation**:
   ```sql
   -- 1. User/Contacts cache
   CREATE TABLE contacts (
       id TEXT PRIMARY KEY,
       name TEXT NOT NULL,
       email TEXT NOT NULL,
       avatar_url TEXT,
       about TEXT,
       last_seen INTEGER
   );

   -- 2. Conversations Summary
   CREATE TABLE conversations (
       chat_id TEXT PRIMARY KEY,
       peer_id TEXT NOT NULL,
       peer_name TEXT NOT NULL,
       peer_avatar TEXT,
       last_message TEXT,
       last_message_time INTEGER,
       last_message_type TEXT,
       unread_count INTEGER DEFAULT 0,
       FOREIGN KEY (peer_id) REFERENCES contacts (id)
   );

   -- 3. Messages Table (with offline status & local path)
   CREATE TABLE messages (
       id TEXT PRIMARY KEY,
       chat_id TEXT NOT NULL,
       sender_id TEXT NOT NULL,
       receiver_id TEXT NOT NULL,
       message_type TEXT NOT NULL, -- text, image, audio, video
       content TEXT,               -- text string or remote URL
       local_path TEXT,            -- local disk path
       status TEXT NOT NULL,       -- pending, sent, delivered, read
       timestamp INTEGER NOT NULL,
       duration INTEGER DEFAULT 0, -- audio duration in sec
       file_size INTEGER DEFAULT 0,
       FOREIGN KEY (chat_id) REFERENCES conversations (chat_id)
   );

   -- 4. Call Logs
   CREATE TABLE call_logs (
       id TEXT PRIMARY KEY,
       peer_id TEXT NOT NULL,
       peer_name TEXT NOT NULL,
       peer_avatar TEXT,
       call_type TEXT NOT NULL,    -- audio or video
       direction TEXT NOT NULL,    -- incoming, outgoing, missed
       duration INTEGER DEFAULT 0,
       timestamp INTEGER NOT NULL
   );
   ```
3. **Local Disk Media Manager (`MediaStorageService`)**:
   - Establish dedicated application sandbox folders using `path_provider`:
     - `/app_storage/chat_images/`
     - `/app_storage/chat_audio/`
     - `/app_storage/chat_videos/`
   - Implement `Dio` downloader to pull remote files and update the `local_path` column in SQLite.

---

## 📍 Phase 3: Authentication & Profile Management
**Goal:** Provide secure user onboarding, session persistence, and profile customization using Firebase Auth and Firestore.

### Tasks:
1. **`AuthService`**:
   - `signUpWithEmail(email, password, name)`
   - `signInWithEmail(email, password)`
   - `signOut()`
   - `resetPassword(email)`
   - `currentUserStream` for reactive session listening.
2. **User Profile Model & Firestore Schema**:
   ```
   users/
     {userId}/
       uid: string
       name: string
       email: string
       avatarUrl: string
       about: string
       onlineStatus: boolean
       lastSeen: timestamp
       createdAt: timestamp
   ```
3. **UI Screens**:
   - `LoginScreen`: Form validation, loading state, error banners, password visibility toggle.
   - `RegisterScreen`: Full name, email, password confirmation, auto-creation of Firestore user doc.
   - `ProfileTab` / `EditProfileScreen`: View and edit display name, about status, and upload profile avatar to Firebase Storage.

---

## 📍 Phase 4: Social Graph & Friend Request System
**Goal:** Implement a closed social model (like WhatsApp) where conversations occur only between approved friends.

### Tasks:
1. **Firestore Data Design**:
   ```
   users/{userId}/
     friends/
       {friendId} -> { addedAt: timestamp, friendUid: string }
     
   friend_requests/
     {requestId}/
       fromUid: string
       fromName: string
       fromEmail: string
       fromAvatar: string
       toUid: string
       status: "pending" | "accepted" | "rejected"
       createdAt: timestamp
   ```
2. **Friend Request Operations**:
   - `searchUserByEmail(email)`: Query Firestore for existing registered accounts.
   - `sendFriendRequest(targetUid)`: Create a pending request document.
   - `acceptFriendRequest(requestId, fromUid, toUid)`: Atomic Firestore transaction to add both users to each other's `friends` collection and update request status to `accepted`.
   - `rejectFriendRequest(requestId)`: Update request status to `rejected` or delete document.
3. **`RequestsTab` UI**:
   - Tab 1: **Received Requests** (with Accept & Decline buttons).
   - Tab 2: **Sent Requests** (pending indicator).
   - Search bar to look up users by exact email address.

---

## 📍 Phase 5: Real-Time Messaging & Offline Sync Engine
**Goal:** Build the core 1-on-1 real-time messaging pipeline featuring WhatsApp-like offline caching and auto-dispatching.

### Architecture Workflow:

```
[User Types & Hits Send]
          │
          ▼
[1. Insert to SQLite immediately] ──► Status = 'pending' ──► Render on UI with 🕒 Clock Icon
          │
          ├── [Has Internet?]
          │         │
         YES        NO ──► [Wait in SQLite Queue]
          │                       │
          │                       ▼
          │             [connectivity_plus triggers Online]
          │                       │
          ▼                       ▼
[2. Push to Firestore: /chats/{chatId}/messages/{msgId}]
          │
          ▼
[3. Update SQLite record] ────────► Status = 'sent' ───► Update UI to ✓ Single Grey Tick
          │
          ▼
[4. Receiver App Opens & Listens]
          │
          ▼
[5. Receiver updates Firestore seen]
          │
          ▼
[6. Sender listens to status stream] ──► Update SQLite ──► UI shows ✓✓ Blue Double Tick
```

### Tasks:
1. **Chat ID Determinism**:
   Generate consistent channel IDs for two users:
   ```dart
   String getChatId(String uid1, String uid2) {
     return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
   }
   ```
2. **`SyncService` & Connectivity Orchestrator**:
   - Listen to `Connectivity().onConnectivityChanged`.
   - When connection returns, query SQLite:
     ```sql
     SELECT * FROM messages WHERE status = 'pending' ORDER BY timestamp ASC;
     ```
   - Dispatch pending payloads to Firestore sequentially and update statuses to `sent`.
3. **`ChatRoomScreen` UI**:
   - Message bubbles with directional alignment (right for sender, left for receiver).
   - Dynamic message indicators:
     - 🕒 `pending`
     - ✓ `sent`
     - ✓✓ `delivered`
     - <span style="color:blue">✓✓</span> `read`
   - Real-time timestamp headers (e.g., *Today*, *Yesterday*, *DD/MM/YYYY*).

---

## 📍 Phase 6: Rich Media Engine (Voice Notes, Images & Videos)
**Goal:** Enable recording voice notes, capturing/picking photos & videos, uploading them, and playing them offline if already downloaded.

```
┌──────────────────────────────────────────────────────────┐
│                   MEDIA MESSAGE PIPELINE                 │
│                                                          │
│  [Record / Pick Media] ──► Save to Device Sandbox        │
│                                      │                   │
│                                      ▼                   │
│                   Insert into SQLite with local_path     │
│                                      │                   │
│                                      ▼                   │
│                   Upload to Firebase Storage in bg       │
│                                      │                   │
│                                      ▼                   │
│                   Send Message to Firestore with URL     │
│                                                          │
│  [Receiver Side]                                         │
│  Receive Firestore message ──► Download file via Dio     │
│                                      │                   │
│                                      ▼                   │
│                   Save to sandbox & update SQLite        │
│                                      │                   │
│                                      ▼                   │
│                   Play/View offline without network!     │
└──────────────────────────────────────────────────────────┘
```

### Tasks:
1. **Audio / Voice Notes**:
   - Integrate `record` package to record `.m4a` audio with hold-to-record or lock-to-record UI.
   - Integrate `just_audio` to play voice messages with slider progress, duration, and play/pause controls.
2. **Photos**:
   - Pick from camera/gallery via `image_picker`.
   - Compress image before upload to minimize data usage.
   - Display full-screen interactive viewer with pinch-to-zoom.
3. **Videos**:
   - Pick/record video clips.
   - Generate local thumbnail for instant preview.
   - Inline video player with `video_player`.
4. **Offline Cache Handling**:
   - Check if `local_path` exists on disk:
     - **If YES:** Play directly from local file.
     - **If NO (and online):** Show download icon button; download via `Dio` and save local path.

---

## 📍 Phase 7: Real-Time Audio & Video Calling (ZegoCloud)
**Goal:** Implement 1-on-1 audio and video calling with native ringing, call screens, and call log persistence.

### Tasks:
1. **ZegoCloud Account & Project Integration**:
   - Create project in ZegoCloud Console.
   - Obtain `appID` and `appSign`.
   - Initialize `ZegoUIKitPrebuiltCallInvitationService` on chat module login.
2. **Call Triggering**:
   - In `ChatRoomScreen` AppBar:
     - 📞 **Audio Call Button**: Trigger audio call with Zego prebuilt configuration.
     - 🎥 **Video Call Button**: Trigger video call with camera enabled.
3. **Call Screen Implementation**:
   ```dart
   class CallPage extends StatelessWidget {
     final String callID;
     final String userID;
     final String userName;
     final bool isVideo;

     const CallPage({
       super.key,
       required this.callID,
       required this.userID,
       required this.userName,
       required this.isVideo,
     });

     @override
     Widget build(BuildContext context) {
       return ZegoUIKitPrebuiltCall(
         appID: ZegoConfig.appId,
         appSign: ZegoConfig.appSign,
         userID: userID,
         userName: userName,
         callID: callID,
         config: isVideo
             ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
             : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
       );
     }
   }
   ```
4. **Call History Persistence**:
   - Record call duration, direction (*Incoming/Outgoing/Missed*), and timestamp into SQLite `call_logs` table upon call completion.

---

## 📍 Phase 8: Main Navigation, Tabs & Stealth Integration
**Goal:** Unify all chat sub-systems into a 4-tab host scaffold and wire it seamlessly into Readify's Settings screen via the secret Easter egg gesture.

### Tasks:
1. **`MainChatHostScreen`**:
   - Modern Material 3 `NavigationBar` with 4 tabs:
     1. 💬 **Chats Tab**: Active conversations list, unread badges, last message preview, floating action button to start chat.
     2. 📞 **Calls Tab**: Call history logs with callback buttons.
     3. 👥 **Requests Tab**: Manage incoming/outgoing friend requests.
     4. 👤 **Profile Tab**: User profile, status, storage usage, and logout button.
2. **Stealth Gatekeeper (`ChatAppScreen`)**:
   - Replace old Spin Wheel code in `lib/screens/chat_app_screen.dart`.
   - Act as authentication gatekeeper:
     - Check `FirebaseAuth.instance.currentUser`.
     - **If null:** Open `LoginScreen`.
     - **If logged in:** Open `MainChatHostScreen`.
3. **Preserve Easter Egg Trigger**:
   - Ensure `SettingsScreen` in Readify keeps the 3-tap rapid trigger on the version tile:
     ```dart
     // lib/screens/settings_screen.dart
     ListTile(
       leading: const Icon(Icons.info_outline_rounded),
       title: const Text('App Version'),
       subtitle: const Text('1.0.0'),
       onTap: _onVersionTap, // 3 taps within 1s triggers secret chat
     )
     ```

---

## 📍 Phase 9: Testing, Edge Cases & Security
**Goal:** Ensure fault tolerance, security, and graceful degradation during network transitions.

### Tasks:
1. **Firestore Security Rules**:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Only authenticated users can access
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
         allow read: if request.auth != null; // For user search
       }
       match /friend_requests/{requestId} {
         allow read, write: if request.auth != null;
       }
       match /chats/{chatId}/messages/{messageId} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```
2. **Edge-Case Validation**:
   - [ ] Airplane mode: typing, sending, and queuing 10+ messages.
   - [ ] Restoring network: verify all 10 messages push to Firestore in correct order.
   - [ ] Offline audio playback: verify previously downloaded voice notes play with zero lag.
   - [ ] App process killed while recording audio / uploading media: verify no corrupt SQLite state.
   - [ ] Simultaneous calls handling when app is backgrounded.

---

## 📍 Phase 10: Release Optimization & Production Build
**Goal:** Optimize the APK size, configure ProGuard rules for SQLite and ZegoCloud, and build the release binary.

### Tasks:
1. **ProGuard Rules (`android/app/proguard-rules.pro`)**:
   Ensure SQLite and Zego SDK classes are preserved during code shrinking:
   ```proguard
   -keep class com.zego.** { *; }
   -dontwarn com.zego.**
   -keep class io.flutter.plugins.firebase.** { *; }
   ```
2. **Build Commands**:
   ```bash
   # Clean previous build artifacts
   flutter clean
   flutter pub get

   # Build universal release APK
   flutter build apk --release

   # Or build split per ABI (smaller download size)
   flutter build apk --split-per-abi
   ```
3. **Artifact Location**:
   `build/app/outputs/flutter-apk/app-release.apk`

---

## 🏁 Phase Sign-Off & Verification Checklist

- [ ] **Phase 1**: Firebase initialized & Android permissions configured.
- [ ] **Phase 2**: SQLite database tables created and disk sandbox accessible.
- [ ] **Phase 3**: User registration, login, and profile editing verified.
- [ ] **Phase 4**: Friend search, request send, and accept/reject flows functional.
- [ ] **Phase 5**: Real-time messaging with live status (`pending` 🕒 -> `sent` ✓ -> `read` ✓✓) working.
- [ ] **Phase 6**: Voice recording, image sharing, and video playback operational offline.
- [ ] **Phase 7**: 1-on-1 audio and video calls working smoothly via ZegoCloud.
- [ ] **Phase 8**: 4-tab host navigation and 3-tap Easter egg entry functional.
- [ ] **Phase 9**: Firestore security rules deployed and network drops handled gracefully.
- [ ] **Phase 10**: Production release APK built and tested on physical Android device.
