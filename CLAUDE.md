# AutoCheckIn

macOS menu bar-app i Swift. Checkar automatiskt in i Slack när du ansluter
till konfigurerade WiFi-nät (t.ex. kontoret).

## Stack
- Swift + CoreWLAN (WiFi-detektion)
- Slack API (status-uppdatering)
- Xcode-projekt, distribueras via GitHub Releases

## Kommandon
- `xcodebuild -scheme AutoCheckIn -configuration Release` — bygg release
- Signering: ad-hoc (`CODE_SIGN_IDENTITY = "-"`, inget Developer ID/Team) —
  därför måste användare kringgå Gatekeeper vid första start (se README)

## Viktigt
- macOS-app: kompilera och testa på Mac med Xcode
- App Sandbox är avstängd (`WiFiMonitor.entitlements`). CoreWLAN kräver
  Location Services-behörighet för att få ut SSID — utan den blir SSID nil
- Releases publiceras på GitHub med `gh release create`
