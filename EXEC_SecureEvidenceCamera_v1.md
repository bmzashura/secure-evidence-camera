# EXEC PLAN: Secure Evidence Camera

## Overview
Secure Evidence Camera — offline-only encrypted photo capture app untuk UTS Keamanan Aplikasi Mobile ITTS.

**Target:** Flutter app (iOS + Android), fully offline, no backend.

---

## Development Phases

### Phase 1: Setup + Lock Screen + PIN Auth
**Timeline:** Day 1-2
**Goal:** App bisa unlock dengan PIN, PIN ter-hash dengan bcrypt

#### Tasks:
- [ ] `flutter create secure_evidence_camera --org com.itts.secureevidence`
- [ ] Setup project structure (Clean Architecture folders)
- [ ] Install dependencies:
  - `flutter_bloc` — state management
  - `flutter_secure_storage` — secure key storage
  - `encrypt` — AES-256 crypto
  - `camera` — camera access
  - `path_provider` — file path
  - `equatable` — bloc equality
- [ ] `PinInput` widget (4-digit, keypad, states: default/error/lockout)
- [ ] `LockScreen` with PIN setup (first launch) and verify
- [ ] `PinService` — bcrypt hash + verify
- [ ] `AuthBloc` — session state, attempt counter, lockout timer
- [ ] Session timeout — auto-lock after 2min background
- [ ] Test: PIN setup flow, wrong PIN → lockout

#### Verification:
- App locked saat start ✅
- Wrong PIN 3x → lockout 30s ✅
- Correct PIN → unlock to camera ✅
- bcrypt hash visible in storage inspector ✅

---

### Phase 2: Camera Capture + Encryption
**Timeline:** Day 3
**Goal:** Foto langsung ter-encrypt sebelum disave ke disk

#### Tasks:
- [ ] `CameraBloc` — camera state management
- [ ] `CameraScreen` — full preview + capture button
- [ ] `CaptureButton` widget — large circular, animation
- [ ] `EncryptionService` — AES-256-CBC encrypt per photo
- [ ] `KeyManager` — derive master key from secure storage
- [ ] Camera permission handling
- [ ] EXIF stripping before encryption
- [ ] Save encrypted blob + IV to app private storage
- [ ] Filename: `enc_<timestamp>.bin`
- [ ] `capture_photo` usecase

#### Verification:
- Capture photo → no plaintext .jpg saved ✅
- Encrypted file only in app directory ✅
- Brief "Encrypted ✓" overlay shown ✅

---

### Phase 3: Encrypted Gallery
**Timeline:** Day 4
**Goal:** Display encrypted photo thumbnails (blurred placeholders), tap to view

#### Tasks:
- [ ] `GalleryBloc` — load photos from encrypted storage
- [ ] `GalleryScreen` — 3-column grid, pull-to-refresh
- [ ] `EncryptedThumbnail` widget — blurred/lock overlay, no actual preview
- [ ] `PhotoModel` — id, encrypted_path, iv, timestamp
- [ ] `PhotoRepository` — CRUD operations on encrypted files
- [ ] `SecureLocalDatasource` — read/write encrypted blobs
- [ ] `EmptyState` widget
- [ ] Direct camera shortcut via FAB
- [ ] Lock button (manual lock)

#### Verification:
- Gallery shows placeholders for encrypted photos ✅
- Photos not visible in device gallery ✅
- Pull refresh reloads from storage ✅

---

### Phase 4: Photo Viewing (In-Memory)
**Timeline:** Day 5
**Goal:** Tap photo → decrypt to memory only, never to disk

#### Tasks:
- [ ] `PhotoDetailScreen` — full-screen decrypted view
- [ ] Decrypt to `Uint8List` memory only (not file)
- [ ] Pinch-to-zoom gesture
- [ ] Swipe left/right navigation
- [ ] Background/switch app → clear decrypted data immediately
- [ ] Screenshot detection (platform-specific)
- [ ] `decrypt_photo` usecase
- [ ] `delete_photo` usecase with confirmation

#### Verification:
- Photo visible in app but not accessible outside ✅
- Switching apps clears decrypted view ✅
- Delete works with confirmation ✅

---

### Phase 5: Lockout + Security Polish
**Timeline:** Day 6
**Goal:** Full security demo ready

#### Tasks:
- [ ] Lockout screen with countdown overlay
- [ ] Max 3 attempts enforcement
- [ ] Session timeout (2min background → lock)
- [ ] Change PIN functionality
- [ ] Haptic feedback on actions
- [ ] Error handling + edge cases

#### Verification:
- 3 wrong PINs → 30s countdown ✅
- Background 2min → auto-lock ✅
- All error states handled gracefully ✅

---

### Phase 6: Documentation + Video
**Timeline:** Day 7-8
**Goal:** Laporan + video presentation ready for UTS

#### Tasks:
- [ ] `PLAN_` + `EXEC_` documentation in Obsidian vault
- [ ] Before/after comparison screenshot
- [ ] Storage inspector evidence (encrypted blob vs plaintext)
- [ ] Laporan lengkap 9 sections (per UTS format)
- [ ] Video recording:
  1. Perkenalan (name, NIM, title)
  2. Threat model explanation
  3. Code walkthrough (PIN hash, encryption)
  4. Demo: capture → encrypted → view
  5. Demo: wrong PIN → lockout
  6. Demo: try open encrypted file externally (fail)
  7. Penutup + recommendation

---

## File Structure

```
secure_evidence_camera/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/
│   │   │   ├── colors.dart
│   │   │   ├── strings.dart
│   │   │   └── dimensions.dart
│   │   ├── crypto/
│   │   │   ├── encryption_service.dart
│   │   │   └── key_manager.dart
│   │   ├── auth/
│   │   │   ├── pin_service.dart
│   │   │   └── session_manager.dart
│   │   └── utils/
│   │       ├── image_utils.dart
│   │       └── screenshot_detector.dart
│   ├── data/
│   │   ├── models/
│   │   │   └── photo_model.dart
│   │   ├── repositories/
│   │   │   └── photo_repository_impl.dart
│   │   └── datasources/
│   │       └── secure_local_datasource.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   └── photo.dart
│   │   ├── repositories/
│   │   │   └── photo_repository.dart
│   │   └── usecases/
│   │       ├── capture_photo.dart
│   │       ├── get_photos.dart
│   │       ├── decrypt_photo.dart
│   │       └── delete_photo.dart
│   └── presentation/
│       ├── bloc/
│       │   ├── auth/
│       │   │   ├── auth_bloc.dart
│       │   │   ├── auth_event.dart
│       │   │   └── auth_state.dart
│       │   ├── camera/
│       │   │   ├── camera_bloc.dart
│       │   │   ├── camera_event.dart
│       │   │   └── camera_state.dart
│       │   └── gallery/
│       │       ├── gallery_bloc.dart
│       │       ├── gallery_event.dart
│       │       └── gallery_state.dart
│       ├── screens/
│       │   ├── lock_screen.dart
│       │   ├── camera_screen.dart
│       │   ├── gallery_screen.dart
│       │   └── photo_detail_screen.dart
│       └── widgets/
│           ├── pin_input.dart
│           ├── capture_button.dart
│           ├── encrypted_thumbnail.dart
│           ├── countdown_overlay.dart
│           └── empty_state.dart
├── ios/
├── android/
├── pubspec.yaml
└── README.md
```

---

## Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5
  flutter_secure_storage: ^9.2.2
  encrypt: ^5.0.3
  camera: ^0.11.0+2
  path_provider: ^2.1.4
  path: ^1.9.0
  permission_handler: ^11.3.1
  uuid: ^4.5.1
  image: ^4.3.0  # EXIF stripping
  intl: ^0.19.0  # timestamp formatting
```

---

## Security Implementation Details

### Encryption Flow (Capture)
```
1. Camera captures YUV → convert to JPEG bytes
2. Strip EXIF data (remove GPS, device info)
3. Generate random 16-byte IV
4. Load master key from flutter_secure_storage
5. AES-256-CBC encrypt JPEG bytes
6. Save: {iv || ciphertext} to file as .bin
7. Store metadata in SQLite/secure_shared_prefs:
   {id, filename, iv_hex, created_at}
```

### Decryption Flow (View)
```
1. Load encrypted blob from file
2. Extract IV from first 16 bytes
3. Load master key from secure storage
4. AES-256-CBC decrypt to memory (Uint8List)
5. Display via Image.memory()
6. On dispose / app background → clear Uint8List
```

### Key Derivation
- Master key generated once on first launch
- Stored in iOS Keychain / Android Keystore via flutter_secure_storage
- PIN hashes are separate — used to verify identity, not to encrypt photos
- Key never leaves secure enclave

### bcrypt PIN
- Cost factor: 12
- Salt: auto-generated by bcrypt
- Stored in secure storage
- Verify on each unlock attempt

---

## Comparison for UTS

### Before (Plaintext Photo)
```
Filename: IMG_20260525_123456.jpg
Gallery: Visible ✅
File Manager: Openable ✅
Metadata: GPS, device, timestamp exposed
Screenshot: Possible ✅
```

### After (Encrypted)
```
Filename: enc_1716644000.bin
Gallery: Not visible ❌
File Manager: Unreadable ❌
Metadata: Stripped ✅
Screenshot: Detected/warned ✅
```

---

## Timeline Summary

| Day | Phase | Deliverable |
|---|---|---|
| 1-2 | Setup + Lock Screen | App with PIN auth, lockout works |
| 3 | Camera + Encryption | Photos encrypted on capture |
| 4 | Gallery | Encrypted placeholders visible |
| 5 | Viewing + Security | In-memory decrypt, auto-lock |
| 6 | Polish | Haptics, edge cases, change PIN |
| 7-8 | Docs + Video | Laporan + UTS video |

---

*Plan version: 1.0*
*Created: 2026-05-25*