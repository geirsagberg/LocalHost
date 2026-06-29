# LocalHost Monitor

A tiny native macOS app for seeing running localhost websites.

## Features

- Scans listening local TCP ports and shows the ones that respond over HTTP or HTTPS.
- Shows only visible `200 OK` sites by default, with a toggle to view every entry.
- Infers each page title from the root HTML document.
- Lets you override the displayed title.
- Lets you hide individual entries from the default view.
- Assigns a deterministic emoji per site.
- Lets you clear or override the emoji.
- Can terminate the process listening on a site port, with an administrator prompt if needed.
- Includes a macOS menu bar extra for quick access.
- Uses a custom app icon built from the open-source Lucide `server` icon.

## Run

```sh
swift run LocalHostMonitor
```

## Build A `.app`

```sh
./scripts/build-app.sh
open .build/LocalHostMonitor.app
```

The build script needs either `rsvg-convert` from librsvg or ImageMagick's `magick` command to render `Resources/AppIcon.svg` into a macOS `.icns`.

Overrides are stored in `~/Library/Application Support/LocalHostMonitor/Sites.json`.
