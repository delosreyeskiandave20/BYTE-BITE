# Fetch part images (adapted for this Flutter app)

This repo includes `fetch_images.py` to download one reference image per unique part from `assets/motorcycle_parts_catalog.json` using Google Custom Search.

## 1) Get credentials
- **Google API key**: [Google Cloud Console](https://console.cloud.google.com/) → create/select project → enable **Custom Search API** → **Credentials** → create API key.
- **Search engine ID (cx)**: [Programmable Search Engine](https://programmablesearchengine.google.com/) → create engine → search the entire web → enable **Image search** → copy the **Search engine ID**.

Keep keys private (do not commit them).

## 2) Provide keys
Either set environment variables (recommended):

**PowerShell**
```powershell
$env:GOOGLE_API_KEY="your_api_key"
$env:GOOGLE_CSE_ID="your_cx_id"
```

**cmd**
```cmd
set GOOGLE_API_KEY=your_api_key
set GOOGLE_CSE_ID=your_cx_id
```

Or edit the placeholders at the top of `fetch_images.py` (avoid committing real keys).

## 3) Install dependency & run
```powershell
pip install requests
python fetch_images.py
```

## 4) What it produces
- `assets/parts/<slug>.<ext>` – downloaded images (skipped on re-run if already present)
- `assets/parts_image_map.json` – map of `"Part name"` → `"assets/parts/<file>"`
- `assets/motorcycle_parts_catalog_with_images.json` – copy of the catalog where each part becomes `{ "name": ..., "image": "assets/parts/..." }` (when found)

`pubspec.yaml` already includes `assets/parts/`, so new images are bundled as Flutter assets (run `flutter pub get`/rebuild as usual).

## 5) Quotas & cleanup
- Free tier is roughly ~100 searches/day. If it stops or leaves missing parts, run `python fetch_images.py` again later (it resumes by skipping existing files).
- Manually review `assets/parts/` and replace any wrong images, keeping the same filename.

## 6) Using in the app
- Use `assets/parts_image_map.json` for simple name→image lookups, or
- Switch data loading to `assets/motorcycle_parts_catalog_with_images.json` if you want image paths embedded per catalog entry.
Adjust your data model/parsing code to accept `parts` as objects (`{name, image}`) if you use the enriched catalog.
