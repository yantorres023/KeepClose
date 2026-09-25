# Android release signing (HUMAN ACTION REQUIRED)

CI builds are signed with the debug key and **must not be uploaded to Google Play**.

1. Create an upload keystore (keep it and its passwords safe, outside the repo):
   ```
   keytool -genkey -v -keystore ~/keepclose-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `android/key.properties` (git-ignored):
   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/absolute/path/to/keepclose-upload.jks
   ```
3. `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`.
4. In Play Console, enrol in Play App Signing and upload the AAB to a **closed testing** track.
5. For CI signing, store the keystore as a base64 GitHub secret and write `key.properties` in a workflow step (not configured yet — requires the owner's secrets).
