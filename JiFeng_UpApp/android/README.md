# JiFeng Android

Native Android port baseline for `JiFeng_UpApp`.

## Current Scope

- Native Android application module: `android/app`
- Package name: `com.jifeng.upapp`
- Target SDK: 35
- Min SDK: 23
- Bottom tab pages:
  - Games
  - Leaderboard
  - Lobby chat
  - Achievements
  - Skin store
  - Profile
- Backend integration:
  - Guest login
  - Profile fetch
  - Chat list/send
  - Game score submit
  - Leaderboard fetch
  - Cross-platform multiplayer rooms
- Game entries are mapped from the iOS game list.
- Playable Android baseline exists for:
  - Draw board
  - Truth or Dare
  - Dice
  - Five in a row
  - Undercover
  - King game
  - Card draw
  - Gesture bomb
  - Puzzle
  - Snake
  - Sudoku
  - Reaction
  - Memory cards
  - 2048 baseline
  - Rhythm baseline
- Remaining work is no longer entry wiring; it is fidelity work: match iOS animations, exact rule variants, assets, sound, orientation behavior, and theme presets.

## Cross-Platform Multiplayer

Android and iOS now share the same lightweight REST room protocol for online party games.

Backend endpoints:

```text
GET  /multiplayer/rooms?kind=UNDERCOVER
POST /multiplayer/rooms
POST /multiplayer/rooms/:roomId/join
GET  /multiplayer/rooms/:roomId?since=0
POST /multiplayer/rooms/:roomId/messages
```

Shared message shape matches the iOS `JFGameMessage` contract:

```json
{
  "type": "identity",
  "from": "peer-id",
  "to": "optional-peer-id",
  "payload": {
    "number": 1,
    "role": "平民",
    "word": "可乐"
  }
}
```

Currently wired game message types:

- `identity`
- `vote_list`
- `vote`
- `vote_result`
- `king_deal`

Android has a room panel in Undercover and King Game. If the room field is empty, it joins the latest room for the current game kind.

## Local Build

This machine currently uses Android Studio's bundled JBR:

```bash
cd android
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
/Users/zhouyi17/.gradle/wrapper/dists/gradle-8.12-bin/cetblhg4pflnnks72fxwobvgv/gradle-8.12/bin/gradle :app:assembleDebug
```

Debug APK output:

```text
android/app/build/outputs/apk/debug/app-debug.apk
```

`android/local.properties` is local machine configuration and should not be committed.

## Release Work Still Required

- Generate Android app icon assets for all densities.
- Create release keystore and configure `signingConfigs.release`.
- Build AAB with `:app:bundleRelease`.
- Replace cleartext backend access with HTTPS before store review.
- Add privacy policy URL.
- Complete Google Play Data Safety form.
- Complete content rating.
- For domestic Android stores, prepare APP filing/备案, software copyright materials where required, screenshots, app description, and privacy compliance text.
- Expand placeholder games until Android behavior matches iOS.
