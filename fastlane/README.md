# Store metadata (F-Droid / IzzyOnDroid)

Listing metadata in the [Fastlane / Triple-T layout](https://f-droid.org/docs/All_About_Descriptions_Graphics_and_Screenshots/)
that F-Droid and IzzyOnDroid read directly from the repo.

```
fastlane/metadata/android/
├─ en-US/
│  ├─ title.txt
│  ├─ short_description.txt   (≤ 80 chars)
│  ├─ full_description.txt    (≤ 4000 chars)
│  ├─ changelogs/1.txt        (one file per versionCode)
│  └─ images/
│     ├─ icon.png
│     └─ phoneScreenshots/    ← drop screenshots here
└─ es-ES/  (same structure, Spanish)
```

## Adding screenshots (the only piece left)

Capture 2–6 PNGs from a phone or emulator and name them in order:

```
fastlane/metadata/android/en-US/images/phoneScreenshots/1.png
fastlane/metadata/android/en-US/images/phoneScreenshots/2.png
...
```

From a running emulator/device:

```bash
flutter run               # or have the app open
# then, per screen:
adb exec-out screencap -p > 1.png   # repeat for each screen
```

Suggested shots: home (plan list), a plan's expenses, the add-expense sheet
(showing the split modes), balances, and the settle tab. The same files can be
copied into `es-ES/images/phoneScreenshots/`.

## New release

Add a changelog file named after the new `versionCode` (e.g. `2.txt`) and bump
the version in `pubspec.yaml`.
