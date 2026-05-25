# PRD: Secure Evidence Camera — Keamanan Aplikasi Mobile ITTS

## 1. Concept & Vision

**Secure Evidence Camera** adalah aplikasi kamera yang secara otomatis mengenkripsi setiap foto yang diambil sehingga hanya bisa dilihat melalui aplikasi ini dengan PIN. Foto-foto yang tersimpan tidak dapat dilihat dari gallery biasa, file manager, atau dibuka dengan aplikasi lain. Dirancang untuk menyimpan bukti-bukti sensitif (dokumen, lokasi, adegan) yang membutuhkan privasi tinggi.

**Mood:** Privasi absolut, secure-by-default, no compromise.

**Slogan:** *"Ambil. Simpan. Rahasia."*

---

## 2. Design Language

### Aesthetic Direction
Utilitarian dark theme dengan aksen merah (danger/secure). Terinspirasi dari vault apps dan forensic tools. Clean, minimal, tidak ada elemen gratuitous — semua ada fungsi.

### Color Palette
| Role | Hex |
|---|---|
| Background | `#0A0A0F` |
| Surface | `#14141F` |
| Surface Elevated | `#1E1E2E` |
| Primary | `#DC2626` (red) |
| Secondary | `#991B1B` (dark red) |
| Accent | `#F59E0B` (amber untuk lock/warning) |
| Text Primary | `#F9FAFB` |
| Text Secondary | `#9CA3AF` |
| Success | `#10B981` (green untuk confirm) |
| Error | `#EF4444` |

### Typography
- **Headings:** Inter Bold, 20-24sp
- **Body:** Inter Regular, 14-16sp
- **Captions/Timestamps:** Inter Medium, 12sp, muted color
- **Mono (hex display):** JetBrains Mono, 10-12sp
- **Fallback:** system-ui

### Spatial System
- Base unit: 8dp
- Card padding: 16dp
- Screen padding: 24dp horizontal, 16dp vertical
- Button height: 56dp (touch-friendly)
- Grid: 3 columns untuk gallery

### Motion Philosophy
- Camera shutter: quick white flash overlay (100ms)
- Encryption indicator: red pulse animation saat encrypting
- Lock/unlock: subtle haptic + scale animation
- Delete: slide left with red background reveal
- No excessive animations — security apps should feel fast and serious

### Visual Assets
- **Icons:** Lucide Icons (camera, lock, unlock, eye, eye-off, trash, shield, image)
- **Decorative:** Minimal — lock icon on lock screen, shield on home
- **No images** except user's captured photos

---

## 3. Layout & Structure

### Screen Flow
```
[Lock Screen] → [Camera View] ↔ [Encrypted Gallery]
                    ↓
              [Photo Detail (Decrypted In-Memory)]
```

### Screen 1: Lock Screen
- Full-screen dark background
- Centered app icon (shield + camera)
- Title: "Secure Evidence Camera"
- Subtitle: "Masukkan PIN untuk akses"
- 4-digit PIN input (dots)
- Max 3 attempts → 30s lockout with countdown
- Footer: "Foto terenkripsi. Tidak ada yang bisa membukanya tanpa PIN."

### Screen 2: Camera View
- Full-screen camera preview
- Top bar: back arrow (return to gallery), flash toggle, camera switch
- Bottom bar: gallery shortcut (右下角), capture button (centered, large), settings
- Capture button: large circle with red border
- After capture: brief "Encrypted ✓" overlay
- No preview after capture ( langsung encrypted )

### Screen 3: Encrypted Gallery
- AppBar: "Gallery" + lock icon (tap to lock)
- 3-column grid of thumbnails
- Thumbnails: blurred or dark placeholder (encrypted, no preview)
- Tap thumbnail: prompt PIN again → decrypt in-memory → show full screen
- Long press: select mode (multi-delete)
- Swipe down from top: pull-to-refresh (reload from storage)
- FAB: camera shortcut (direct to capture)

### Screen 4: Photo Detail (In-Memory Only)
- Full-screen decrypted view (temporary)
- Pinch to zoom
- Metadata strip: timestamp (decrypted from filename)
- Bottom: share (re-encrypt before share?), delete
- Swipe left/right to navigate
- App switch / background → immediately re-encrypt (clear memory)
- Screenshot attempt → should be blocked (invisible overlay or black screen if detect screen capture)

### Settings Screen (optional, bisa di-swipe atau tap icon di lock screen)
- Change PIN
- Enable/disable decoy gallery (foto public yang tidak terencrypt)
- Export encrypted backup (ke file yang hanya bisa di-decrypt oleh app ini)
- About

### Responsive Strategy
- Mobile-first (portrait primary)
- Tidak ada tablet layout untuk MVP

---

## 4. Features & Interactions

### Core Features

#### F1: Secure Camera Capture
- Camera access → capture photo
- **Immediately encrypt with AES-256-CBC before saving to disk**
- Save only: encrypted blob + IV + metadata (timestamp only)
- Original file never written to disk in plaintext
- EXIF data stripped before encryption
- Filename: `enc_<timestamp>.bin` (not .jpg)

#### F2: Encrypted Storage
- **flutter_secure_storage** for PIN and key material
- **AES-256-CBC encryption** for each photo
- Each photo has unique IV (random 16 bytes)
- Master key derived from device secure enclave (not from PIN directly)
- PIN used to derive unlock key, not to encrypt photos directly
- All photos stored in app's private directory

#### F3: PIN Protection
- First launch → PIN setup (4-digit)
- bcrypt hashing for PIN storage (cost factor 12)
- Max 3 attempts → 30s lockout
- Session timeout: auto-lock after 2min background
- No recovery mechanism (by design — if someone knows PIN, they have access)

#### F4: Decoy Gallery (Optional Feature)
- Second "gallery" yang terlihat seperti gallery biasa
- Contains fake/normal photos
- Accessible via normal unlock (same PIN)
- For scenarios where you're forced to unlock phone

#### F5: Photo Viewing (In-Memory Only)
- When viewing: decrypt to memory
- Never write decrypted data to disk
- On app background/switch: clear decrypted data immediately
- Screenshot detection: show black screen if attempt detected (platform-specific)

#### F6: Before/After Security Comparison
- **Before:** Show that normal photos (from decoy gallery) are visible in device gallery
- **After:** Show that Secure Evidence photos are NOT visible anywhere except in app
- Demonstrate by trying to open encrypted file with standard image viewer

### Edge Cases
| Scenario | Behavior |
|---|---|
| Camera permission denied | Show explanation + button to settings |
| Storage full | Alert before capture, prevent save |
| Wrong PIN | Shake animation, attempt counter, 3x → lockout |
| Lockout active | Show countdown timer, disable input |
| Photo viewing interrupted | Immediately re-encrypt |
| Screenshot attempt | Show black overlay (android) or notification warning |
| Uninstall app | Data stays encrypted, unrecoverable |
| Device rooted | Warn user (encryption key might be extractable) |

### States
- **Locked:** Lock screen visible
- **Unlocking:** Brief animation then camera
- **Camera active:** Preview + capture button
- **Gallery active:** Grid of encrypted thumbnails
- **Viewing photo:** Full decrypted view in memory
- **Processing:** Encryption in progress indicator
- **Error:** Error toast with retry

---

## 5. Component Inventory

### C1: PinInput (Lock Screen)
- 4 circular indicators
- Numeric keypad (1-9, 0, backspace)
- States: default, error (red shake), success (green pulse), lockout (disabled + countdown)
- Haptic feedback on each tap

### C2: CaptureButton (Camera)
- Large circular button (72dp)
- Red border, white center
- Press: scale 0.9 animation (100ms)
- During encryption: pulsing red glow
- After encrypted: brief checkmark overlay (500ms)

### C3: EncryptedThumbnail (Gallery)
- Square aspect ratio
- Dark/blurred placeholder (encrypted = no preview)
- Lock icon overlay in corner
- Long press: red highlight (selection mode)

### C4: SecurePhotoViewer
- Full-screen with gesture support (pinch zoom, swipe)
- Background: pure black
- Top overlay (semi-transparent): timestamp
- Bottom overlay: delete button
- On background/switch: instantly remove from view

### C5: LockIconAnimated
- Shield with camera lens
- Locked: shield closed
- Unlocking: brief open animation

### C6: CountdownOverlay
- Full screen semi-transparent dark
- Large countdown number (30, 29, 28...)
- "Terlalu banyak percobaan. Coba lagi dalam X detik."

### C7: EmptyState
- Camera icon (large, muted)
- Title: "Belum Ada Foto"
- Subtitle: "Tiap foto otomatis terenkripsi. Hanya bisa dilihat di aplikasi ini."

---

## 6. Technical Approach

### Framework & Stack
| Layer | Technology |
|---|---|
| Framework | Flutter 3.x |
| Language | Dart 3.x |
| Camera | camera package |
| Crypto | encrypt package (AES-256-CBC) |
| Secure Storage | flutter_secure_storage (iOS Keychain / Android Keystore) |
| State Management | flutter_bloc (BLoC) |
| Architecture | Clean Architecture |

### Project Structure
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── colors.dart
│   │   ├── strings.dart
│   │   └── dimensions.dart
│   ├── crypto/
│   │   ├── encryption_service.dart    # AES-256 encrypt/decrypt per photo
│   │   └── key_manager.dart           # Master key management
│   ├── auth/
│   │   ├── pin_service.dart          # PIN hash + verify
│   │   └── session_manager.dart       # Session timeout tracking
│   └── utils/
│       ├── image_utils.dart           # EXIF strip, thumbnail generate
│       └── screenshot_detector.dart    # Prevent screenshot
├── data/
│   ├── models/
│   │   └── photo_model.dart
│   ├── repositories/
│   │   └── photo_repository_impl.dart
│   └── datasources/
│       └── secure_local_datasource.dart
├── domain/
│   ├── entities/
│   │   └── photo.dart
│   ├── repositories/
│   │   └── photo_repository.dart
│   └── usecases/
│       ├── capture_photo.dart
│       ├── get_photos.dart
│       ├── decrypt_photo.dart
│       └── delete_photo.dart
└── presentation/
    ├── bloc/
    │   ├── auth/
    │   │   ├── auth_bloc.dart
    │   │   ├── auth_event.dart
    │   │   └── auth_state.dart
    │   ├── camera/
    │   │   ├── camera_bloc.dart
    │   │   ├── camera_event.dart
    │   │   └── camera_state.dart
    │   └── gallery/
    │       ├── gallery_bloc.dart
    │       ├── gallery_event.dart
    │       └── gallery_state.dart
    ├── screens/
    │   ├── lock_screen.dart
    │   ├── camera_screen.dart
    │   ├── gallery_screen.dart
    │   └── photo_detail_screen.dart
    └── widgets/
        ├── pin_input.dart
        ├── capture_button.dart
        ├── encrypted_thumbnail.dart
        ├── countdown_overlay.dart
        └── empty_state.dart
```

### Security Mechanisms

| # | Mechanism | Implementation |
|---|---|---|
| 1 | AES-256-CBC Encryption | Each photo encrypted before disk write |
| 2 | Unique IV per Photo | Random 16 bytes, stored alongside ciphertext |
| 3 | bcrypt PIN Hashing | Cost factor 12, salt included |
| 4 | Max 3 Login Attempts | Counter + 30s lockout |
| 5 | Session Timeout | 2min background → auto-lock |
| 6 | In-Memory Only Decrypt | Decrypted photo never written to disk |
| 7 | EXIF Stripping | Remove metadata before encryption |
| 8 | Screenshot Detection | Block/notify on screenshot attempt |
| 9 | No Preview Generation | Thumbnails are blurred placeholders |

### Before/After Comparison

| Aspek | Before (Plaintext) | After (Encrypted) |
|---|---|---|
| Storage | .jpg readable anywhere | .bin unreadable without key |
| Gallery | Visible in photo app | Not visible |
| Metadata | EXIF with location/time | Stripped |
| Decrypt | Direct open | Need PIN + app |
| Screenshot | Possible | Detected/warned |

---

## 7. Demo Flow for UTS

1. **Buka device gallery** — kosong atau hanya foto biasa
2. **Buka app** → lock screen
3. **Ambil foto** → lihat "Encrypted ✓" overlay
4. **Tutup app** → buka lagi → harus unlock
5. **Buka gallery** → foto terenkripsi muncul sebagai placeholder gelap
6. **Tap foto** → unlock → lihat foto (in-memory only)
7. **Coba buka encrypted file via file manager** → tidak bisa
8. **Coba salah PIN 3x** → lockout countdown
9. **Bandingkan** dengan foto plaintext (decoy gallery jika enabled)

---

## 8. Out of Scope

- Cloud backup
- Biometric unlock (Touch/Face ID)
- Video recording
- Photo editing
- Sharing photos (complex — would need secure channel)
- Multiple albums
- Password (PIN only, 4-digit)

---

*Document version: 1.0*
*Created for: UTS Praktik Keamanan Aplikasi Mobile ITTS 2025 Genap*