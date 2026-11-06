# AutoCheckIn

macOS menu bar-app i Swift. Checkar automatiskt in i Slack när du ansluter
till konfigurerade WiFi-nät (t.ex. kontoret).

## Stack
- Swift + CoreWLAN (WiFi-detektion)
- Slack API (status-uppdatering)
- Xcode-projekt, distribueras via GitHub Releases

## Kommandon
- `xcodebuild -scheme AutoCheckIn -configuration Release` — bygg release
- `codesign --sign ...` — signera app (kräver Developer ID)

## Viktigt
- macOS-app: kompilera och testa på Mac med Xcode
- WiFi-detektion kräver CoreWLAN-rättigheter i sandbox-konfigurationen
- Releases publiceras på GitHub med `gh release create`
