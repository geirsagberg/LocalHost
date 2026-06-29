# LocalHost Monitor

A tiny native macOS app for seeing running localhost websites.

## Features

- Scans listening local TCP ports and shows the ones that respond over HTTP or HTTPS.
- Shows only `200 OK` sites by default, with a toggle to view every HTTP response.
- Infers each page title from the root HTML document.
- Lets you override the displayed title.
- Assigns a deterministic emoji per site.
- Lets you clear or override the emoji.
- Includes a macOS menu bar extra for quick access.

## Run

```sh
swift run LocalHostMonitor
```

## Build A `.app`

```sh
./scripts/build-app.sh
open .build/LocalHostMonitor.app
```

Overrides are stored in `~/Library/Application Support/LocalHostMonitor/Sites.json`.
