# Secure Evidence Camera

Aplikasi kamera pengaman offline untuk Android — foto Dienkripsi AES-256-CBC sebelum disimpan ke disk. Tidak ada cloud, tidak ada sharing, 100% offline.

**UTS:** Keamanan Aplikasi Mobile — ITTS 2025 Genap
**Nama:** Bemis Huntala | **NIM:** 1002240018

---

## Cara Menjalankan

### Prerequisites
- Flutter 3.41.6+
- Android SDK (adb)
- Android device dengan USB debugging enabled

### Setup

```bash
# Clone repo
git clone https://github.com/bmzashura/secure-evidence-camera.git
cd secure-evidence-camera

# Install dependencies
flutter pub get

# List devices
flutter devices

# Run on device (USB debugging)
flutter run -d <device_id>

# Contoh:
flutter run -d 143352556L104165

# Build debug APK
flutter build apk --debug
```

### USB Debugging Setup (Android)

1. Enable **Developer Options** di HP:
   - Settings → About Phone → tap "Build Number" 7x
2. Enable **USB Debugging**:
   - Settings → Developer Options → USB Debugging → ON
3. Connect HP ke PC via USB
4. Accept RSA key dialog di HP
5. Verify: `adb devices` — device harus tampil sebagai `device` (bukan `unauthorized`)

### Automation Test

```bash
# Jalankan semua test suite
python3 test_uts_automation.py

# List semua test
python3 test_uts_automation.py --list

# Jalankan spesifik
python3 test_uts_automation.py --test tc05
python3 test_uts_automation.py --test config
```

---

## Arsitektur

Clean Architecture dengan BLoC pattern:

```
lib/
├── main.dart                              # Entry point + lifecycle handler
├── core/
│   ├── auth/
│   │   ├── pin_service.dart              # PBKDF2-SHA256 PIN hashing
│   │   └── session_manager.dart          # 3 attempts, 30s lockout
│   ├── constants/
│   │   ├── colors.dart                    # App color palette
│   │   └── strings.dart                   # Static text
│   └── crypto/
│       └── encryption_service.dart        # AES-256-CBC + compute isolate
├── data/
│   ├── datasources/
│   │   └── secure_local_datasource.dart   # File I/O + metadata JSON
│   └── models/
│       └── photo_model.dart               # Photo entity
└── presentation/
    ├── bloc/
    │   ├── auth/                          # Auth state machine
    │   ├── camera/                        # Camera capture flow
    │   └── gallery/                        # Gallery CRUD
    ├── screens/
    │   ├── lock_screen.dart               # PIN entry / setup
    │   ├── onboarding_screen.dart         # 4-page onboarding
    │   ├── camera_screen.dart             # Camera preview + capture
    │   ├── save_description_screen.dart   # Input deskripsi
    │   ├── gallery_screen.dart            # List foto
    │   └── photo_detail_screen.dart       # In-memory decrypt view
    └── widgets/
        ├── pin_input.dart                 # 4-digit keypad
        ├── capture_button.dart            # Animated capture button
        └── empty_state.dart               # Empty gallery placeholder
```

---

## Fitur Keamanan

| Fitur | Implementasi |
|---|---|
| **PIN Authentication** | 4-digit PIN dengan PBKDF2-SHA256 (10,000 iterations, salt 16-byte) |
| **Lockout** | 3 percobaan salah → 30 detik lockout |
| **Enkripsi Foto** | AES-256-CBC, unique IV (16-byte) per foto |
| **Key Storage** | Master key di iOS Keychain / Android Keystore |
| **Auto-Lock** | Langsung lock saat app di-minimize |
| **Onboarding** | Muncul setelah app di-terminate (bukan backgrounded) |
| **In-Memory Only** | `_decryptedBytes = null` on dispose/pop |
| **Encryption Isolate** | Encrypt/decrypt di compute isolate (no main thread blocking) |
| **No Logging** | Tidak ada `print()` untuk data sensitif |

---

## Alur Authentication

```
App Start
    │
    ▼
AuthCheckStatus
    │
    ├── PIN belum diset  →  PIN Setup Screen
    │
    └── PIN sudah diset  →  PIN Verification
                               │
                               ├── canAttemptPin == false  →  Lockout 30s
                               ├── PIN salah  →  remainingAttempts-- → lockout
                               └── PIN benar
                                       │
                                       ├── wasAppTerminated == true  →  Onboarding
                                       └── wasAppTerminated == false  →  Camera
```

---

## Enkripsi

**Algoritma:** AES-256-CBC (256-bit)
**IV:** 16-byte random unik per foto (`IV.fromSecureRandom()`)
**Key:** 256-bit, disimpan di iOS Keychain / Android Keystore
**Format file:** `{16-byte IV || ciphertext}` → `.bin`

```
Plaintext JPEG
     │
     ▼
AES-256-CBC  ←  Master Key (Keychain/Keystore)
     │
     ▼
{ IV(16B) || ciphertext }  →  enc_<timestamp>.bin
```

---

## Security Testing

**8 Test Cases (TC-01 — TC-08):**

| ID | Test | Tipe |
|---|---|---|
| TC-01 | PIN Brute Force Resistance | Manual |
| TC-02 | Lockout Duration Accuracy | Manual |
| TC-03 | File Unreadability | ADB / Code |
| TC-04 | Unique IV Per Photo | ADB / Code |
| TC-05 | In-Memory Decryption Only | ADB |
| TC-06 | Auto-Lock on Background | Code Review |
| TC-07 | Onboarding After App Termination | Code Review |
| TC-08 | Encryption Key Non-Extractability | Code Review |

Jalankan automation test:
```bash
python3 test_uts_automation.py
```

---

## Tech Stack

| Komponen | Teknologi |
|---|---|
| Framework | Flutter 3.41.6 |
| Bahasa | Dart |
| State Management | flutter_bloc (BLoC pattern) |
| Enkripsi | `encrypt` package — AES-256-CBC |
| Key Storage | `flutter_secure_storage` (iOS Keychain / Android Keystore) |
| Camera | `camera` package |
| Storage | App private directory |
| Platform | Android + iOS |

---

## Project Status

- ✅ App fully functional
- ✅ GitHub: https://github.com/bmzashura/secure-evidence-camera
- ✅ Debug APK built
- ✅ 10/10 automation tests passing (v3)
- ✅ 8/8 security configurations verified
- ✅ 7/7 threats in threat model addressed

---

## Known Limitations

- **Offline only** — tidak ada cloud backup atau remote wipe
- **Rooted device** — tidak ada perlindungan terhadap malware dengan root access
- **No biometric** — sesuai requirement UTS, hanya PIN 4-digit (tidak ada fingerprint/face)

## Rekomendasi

- Enable **ProGuard/R8** untuk release build
- Implementasi **encryption key rotation**
- **Tamper detection** untuk detect jika app dimodifikasi
- **Audit logging** untuk security events (failed PIN, lockout)