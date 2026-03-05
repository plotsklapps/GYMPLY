# GYMPLY Release & Update Guide

Since GYMPLY is distributed as a native Android APK via GitHub (without the Play Store), follow this specific workflow to push updates to your users.

---

## 🚀 The Release Workflow

### 1. Preparation (Local)
*   **Increment Version:** Open `pubspec.yaml` and increase the version.
    *   *Example:* `version: 0.0.1+8` ➡️ `version: 0.0.1+9`
*   **Build APK:** Run the following command in your terminal:
    ```bash
    flutter build apk --release
    ```
*   **Locate & Rename:** Go to `build/app/outputs/flutter-apk/`.
*   **Rename** `app-release.apk` to `gymply.apk`.

### 2. Host the APK (GitHub Releases)
*   Go to your repository on GitHub.com.
*   Click **Releases** (on the right sidebar) ➡️ **Draft a new release**.
*   **Tag:** Create a new tag (e.g., `v0.0.1.9`).
*   **Upload:** Drag and drop your renamed `gymply.apk` into the "Attach binaries" box.
*   **Publish:** Click **Publish release**.
*   **Get Direct Link:** 
    1. Once published, look at the "Assets" section of the release.
    2. Right-click on `gymply.apk`.
    3. Select **Copy link address**. (You will need this for the next step).

### 3. Update Metadata (GitHub Push)
*   Open the `version.json` file in your project root.
*   **Update the values:**
    ```json
    {
      "version_code": 9,
      "version_name": "0.0.1+9",
      "download_url": "PASTE_THE_LINK_YOU_COPIED_FROM_STEP_2"
    }
    ```
*   **Commit & Push:**
    ```bash
    git add version.json
    git commit -m "Release v0.0.1+9"
    git push
    ```

---

## 🛠️ How the Update System Works
1.  **Check:** When a user taps "Check for Updates" in the Menu, the app fetches the **Raw** `version.json` from GitHub.
2.  **Compare:** It compares the `version_code` in the JSON with the `buildNumber` currently installed on the phone.
3.  **Download:** If the JSON number is higher, the app downloads the APK to a temporary folder and shows a progress bar.
4.  **Install:** Once the download is 100%, the app triggers the Android Package Installer.

---

## ⚠️ Important Notes
*   **Raw URL:** Ensure `UpdateService.dart` always points to the **Raw** GitHub URL (e.g., `https://raw.githubusercontent.com/.../version.json`).
*   **First Install:** The very first time a user updates this way, Android will ask: *"Allow GYMPLY to install apps from this source?"* The user must select **Allow**.
*   **Firebase:** This project is now **Firebase-Free**. No hosting or initialization is required.
