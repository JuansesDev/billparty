# Submitting BillParty to F-Droid

This folder holds the **draft build recipe** for the official F-Droid repo. It is
not used by the app; it's what you copy into a Merge Request to
[`fdroiddata`](https://gitlab.com/fdroid/fdroiddata).

F-Droid **builds the app from source** on its own servers and **signs it with the
F-Droid key** (not your release keystore). The Fastlane metadata already in this
repo (`fastlane/metadata/…`: descriptions, screenshots, changelog, icon) is
picked up automatically.

## Steps

1. Create a GitLab account and **fork** `https://gitlab.com/fdroid/fdroiddata`.
2. Copy [`io.github.juansesdev.billparty.yml`](io.github.juansesdev.billparty.yml)
   into the fork at:
   ```
   metadata/io.github.juansesdev.billparty.yml
   ```
3. *(Optional but recommended)* lint and test-build locally with the
   `fdroidserver` tools:
   ```bash
   fdroid rewritemeta io.github.juansesdev.billparty
   fdroid lint io.github.juansesdev.billparty
   fdroid build -v -l io.github.juansesdev.billparty
   ```
4. Commit and open a **Merge Request** against `fdroiddata`.
5. A maintainer reviews it. Expect a couple of rounds on the `Builds:` block
   (Flutter version, NDK, etc.) before it builds cleanly — this is normal and is
   not a rejection.

## References

- Inclusion how-to: https://f-droid.org/docs/Inclusion_How-To/
- Build metadata reference: https://f-droid.org/docs/Build_Metadata_Reference/
- Reproducible builds: https://f-droid.org/docs/Reproducible_Builds/
- Best source of truth for the `Builds:` block: an existing **Flutter** app in
  `fdroiddata` (search the repo for `srclibs:` + `flutter@`).

## New versions later

Because of `UpdateCheckMode: Tags` + `AutoUpdateMode: Version v%v`, F-Droid will
pick up new releases automatically: just push a new `vX.Y.Z` git tag with a
matching `versionCode`, and add a `fastlane/.../changelogs/<versionCode>.txt`.
