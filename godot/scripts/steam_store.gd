extends RefCounted

# TODO: Set the full game's Steam App ID (not the demo App ID).
# Until configured, the Steam shareware purchase button opens nothing.
const APP_ID=""

static func url() -> String:
	return "https://store.steampowered.com/app/"+APP_ID+"/" if not APP_ID.is_empty() else ""
