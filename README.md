# AutoCheckIn

A macOS menu bar app that monitors WiFi networks and automatically sends a check-in message to Slack when you connect to a configured network.

## Features

- Real-time WiFi monitoring via CoreWLAN
- Auto check-in to Slack on arrival at a configured network (once per network per day)
- Weather appended to messages via Open-Meteo (free, no API key, uses your location)
- Multiple networks supported — each with its own message
- Manual check-in from the menu bar at any time
- Network change log at `~/autocheckin_log.txt`

## Installation

1. Download `AutoCheckIn.zip` from the [latest release](https://github.com/weekend68/autocheckin/releases/latest)
2. Unzip and move `AutoCheckIn.app` to `/Applications`
3. **First launch:** right-click the app → **Open** (required once to bypass Gatekeeper — the app is not notarised)
4. Grant **Location Services** and **Notifications** permissions when prompted
5. Click the menu bar icon → **Settings**
6. Enter your Slack token and channel
7. Add your WiFi network(s): set the SSID, a check-in message, and enable **Auto check-in**

## Requirements

- macOS 13 or later
- A Slack [user token](https://api.slack.com/authentication/token-types) (`xoxp-...`)

## Building from source

1. Open `AutoCheckIn.xcodeproj` in Xcode 15 or later
2. Build and run (`⌘R`)

## How it works

- AutoCheckIn watches for SSID changes using `CWEventDelegate` with a 10-second polling fallback
- When you connect to a network marked **Auto check-in**, it sends your configured message to Slack (at most once per network per day)
- Weather is fetched from [Open-Meteo](https://open-meteo.com) using your current location and appended to the message

## Settings

| Setting | Description |
|---------|-------------|
| Slack token | `xoxp-...` user token |
| Channel | `#channel-name` or channel ID |
| WiFi entries | SSID + message + auto check-in toggle per network |
| Weather | Toggle on/off; Celsius or Fahrenheit |

## App icon

The `generate_icon.swift` script renders the `person.wave.2` SF Symbol and exports all macOS icon sizes:

```bash
swift generate_icon.swift
```

## Privacy

- Location is used only to fetch local weather; coordinates are sent to Open-Meteo and not stored
- Slack tokens are stored in `UserDefaults` (local to your Mac, not synced)

## License

MIT
