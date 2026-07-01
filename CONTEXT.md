# LocalHost Monitor

LocalHost Monitor is a native macOS app for discovering and working with running localhost websites. This context names the app concepts that should shape modules and tests.

## Language

**Localhost site**:
A website-like endpoint discovered from a local listening port after it responds over HTTP or HTTPS. It carries the display URL, port, process identity, inferred title, HTTP status, and detection time.
_Avoid_: server, endpoint, service

**Listening port**:
A local TCP port with a process accepting connections. It is not a localhost site until metadata probing confirms an HTTP or HTTPS response.
_Avoid_: socket, endpoint

**Site preferences**:
User-owned overrides for a localhost site, including title, emoji, and default-view visibility.
_Avoid_: settings, config

**Site presentation**:
The preference-aware view of a localhost site used by the window and menu bar access. It combines discovered metadata with site preferences into structured display facts, emoji, visibility, and action state; it should not collapse distinct facts into one mashed-together subtitle.
_Avoid_: view model row, UI state

**Default view**:
The normal filtered list of localhost sites, showing visible OK-status sites unless the user chooses to include explicitly hidden sites, non-OK localhost sites, or both.
_Avoid_: filtered mode, main list
