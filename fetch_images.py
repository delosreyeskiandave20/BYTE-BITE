"""
Fetch one representative image per unique motorcycle part using
Google Custom Search JSON API and enrich the catalog for Flutter use.

Setup:
1. Enable "Custom Search API" in Google Cloud Console and create an API key.
2. Create a Programmable Search Engine at https://programmablesearchengine.google.com
   - Search the entire web
   - Turn on Image search
   - Copy the Search engine ID (cx)
3. Set GOOGLE_API_KEY and GOOGLE_CSE_ID below (or via env vars).
4. pip install requests
5. python fetch_images.py

Notes:
- Free quota is ~100 searches/day. Re-run later; existing images are skipped.
- Review downloaded images and replace incorrect ones (keep the same filename).
"""

from __future__ import annotations

import json
import os
import re
import time
from pathlib import Path
from typing import Any

import requests

# --- Configuration ---
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY", "YOUR_API_KEY")
GOOGLE_CSE_ID = os.getenv("GOOGLE_CSE_ID", "YOUR_SEARCH_ENGINE_ID")

# Source catalog (list of {brand, model, variant, categories:[{name, parts:[str]}]})
CATALOG_PATH = Path("assets/motorcycle_parts_catalog.json")

# Where downloaded images are stored (included in Flutter assets)
IMAGES_DIR = Path("assets/parts")

# Outputs
PARTS_MAP_JSON = Path("assets/parts_image_map.json")  # { "Part name": "assets/parts/part-name.jpg" }
ENRICHED_CATALOG_JSON = Path(
    "assets/motorcycle_parts_catalog_with_images.json"
)  # catalog with parts as {name, image}

# Search behavior
SEARCH_QUERY_SUFFIX = " motorcycle part"
REQUEST_TIMEOUT = 20
SLEEP_BETWEEN_REQUESTS_SEC = 1.0


def slugify(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    text = re.sub(r"-+", "-", text).strip("-")
    return text or "part"


def load_catalog(path: Path) -> list[dict[str, Any]]:
    with path.open("r", encoding="utf-8-sig") as f:
        data = json.load(f)
    if not isinstance(data, list):
        raise ValueError(f"Expected a JSON array in {path}")
    return data


def extract_unique_parts(catalog: list[dict[str, Any]]) -> list[str]:
    seen: set[str] = set()
    unique: list[str] = []
    for entry in catalog:
        for category in entry.get("categories", []) or []:
            for part in category.get("parts", []) or []:
                if isinstance(part, dict):
                    name = str(part.get("name", "")).strip()
                else:
                    name = str(part).strip()
                if not name or name in seen:
                    continue
                seen.add(name)
                unique.append(name)
    return unique


def search_image_url(part_name: str) -> str | None:
    url = "https://www.googleapis.com/customsearch/v1"
    params = {
        "key": GOOGLE_API_KEY,
        "cx": GOOGLE_CSE_ID,
        "q": f"{part_name}{SEARCH_QUERY_SUFFIX}",
        "searchType": "image",
        "num": 1,
        "safe": "active",
    }
    resp = requests.get(url, params=params, timeout=REQUEST_TIMEOUT)
    if resp.status_code != 200:
        print(f"  ! Search failed for '{part_name}': {resp.status_code} {resp.text[:200]}")
        return None
    data = resp.json()
    items = data.get("items") or []
    if not items:
        return None
    link = items[0].get("link")
    return str(link) if link else None


def guess_extension(url: str, content_type: str | None) -> str:
    if content_type:
        ct = content_type.split(";")[0].strip().lower()
        mapping = {
            "image/jpeg": ".jpg",
            "image/jpg": ".jpg",
            "image/png": ".png",
            "image/webp": ".webp",
            "image/gif": ".gif",
        }
        if ct in mapping:
            return mapping[ct]
    m = re.search(r"\.(jpg|jpeg|png|webp|gif)(?:\?|$)", url, re.IGNORECASE)
    if m:
        ext = m.group(1).lower()
        return ".jpg" if ext == "jpeg" else f".{ext}"
    return ".jpg"


def download_image(url: str, dest_base: Path) -> Path | None:
    headers = {"User-Agent": "Mozilla/5.0 (compatible; MotoScanImageFetcher/1.0)"}
    resp = requests.get(url, headers=headers, timeout=REQUEST_TIMEOUT, stream=True)
    if resp.status_code != 200:
        print(f"  ! Download failed: {resp.status_code} {url}")
        return None
    ext = guess_extension(url, resp.headers.get("Content-Type"))
    dest = dest_base.with_suffix(ext)
    with dest.open("wb") as f:
        for chunk in resp.iter_content(chunk_size=8192):
            if chunk:
                f.write(chunk)
    return dest


def find_existing_image(dest_base: Path) -> Path | None:
    for ext in (".jpg", ".png", ".webp", ".gif"):
        p = dest_base.with_suffix(ext)
        if p.exists() and p.stat().st_size > 0:
            return p
    return None


def as_posix_asset(path: Path) -> str:
    # Flutter asset paths use forward slashes
    return path.as_posix()


def enrich_catalog(
    catalog: list[dict[str, Any]], part_to_image: dict[str, str]
) -> list[dict[str, Any]]:
    enriched = json.loads(json.dumps(catalog))  # deep copy
    for entry in enriched:
        for category in entry.get("categories", []) or []:
            new_parts = []
            for part in category.get("parts", []) or []:
                name = part.get("name") if isinstance(part, dict) else part
                name = str(name).strip()
                image = part_to_image.get(name)
                if isinstance(part, dict):
                    obj = dict(part)
                    obj["name"] = name
                    if image:
                        obj["image"] = image
                    new_parts.append(obj)
                else:
                    obj = {"name": name}
                    if image:
                        obj["image"] = image
                    new_parts.append(obj)
            category["parts"] = new_parts
    return enriched


def main() -> int:
    if GOOGLE_API_KEY == "YOUR_API_KEY" or GOOGLE_CSE_ID == "YOUR_SEARCH_ENGINE_ID":
        print("ERROR: Set GOOGLE_API_KEY and GOOGLE_CSE_ID (env vars or in this file).")
        return 1
    if not CATALOG_PATH.exists():
        print(f"ERROR: Catalog not found: {CATALOG_PATH}")
        return 1

    IMAGES_DIR.mkdir(parents=True, exist_ok=True)

    catalog = load_catalog(CATALOG_PATH)
    parts = extract_unique_parts(catalog)
    print(f"Found {len(parts)} unique parts in {CATALOG_PATH}.")

    part_to_image: dict[str, str] = {}
    downloaded = 0
    skipped = 0
    missing = 0

    for i, part in enumerate(parts, 1):
        dest_base = IMAGES_DIR / slugify(part)
        existing = find_existing_image(dest_base)
        if existing:
            part_to_image[part] = as_posix_asset(existing)
            skipped += 1
            continue

        print(f"[{i}/{len(parts)}] Searching: {part}")
        image_url = search_image_url(part)
        if not image_url:
            print(f"  - No image result for '{part}'")
            missing += 1
            time.sleep(SLEEP_BETWEEN_REQUESTS_SEC)
            continue

        saved = download_image(image_url, dest_base)
        if saved:
            part_to_image[part] = as_posix_asset(saved)
            downloaded += 1
            print(f"  + Saved {saved}")
        else:
            missing += 1

        time.sleep(SLEEP_BETWEEN_REQUESTS_SEC)

    # Write outputs
    PARTS_MAP_JSON.parent.mkdir(parents=True, exist_ok=True)
    with PARTS_MAP_JSON.open("w", encoding="utf-8") as f:
        json.dump(part_to_image, f, ensure_ascii=False, indent=2)
    print(f"Wrote image map: {PARTS_MAP_JSON} ({len(part_to_image)} entries)")

    enriched = enrich_catalog(catalog, part_to_image)
    with ENRICHED_CATALOG_JSON.open("w", encoding="utf-8") as f:
        json.dump(enriched, f, ensure_ascii=False, indent=2)
    print(f"Wrote enriched catalog: {ENRICHED_CATALOG_JSON}")

    print(
        f"Done. downloaded={downloaded}, skipped_existing={skipped}, "
        f"missing={missing}, mapped={len(part_to_image)}/{len(parts)}"
    )
    if missing:
        print("Re-run tomorrow if you hit the daily quota, or review missing parts.")
    print("Review images in assets/parts/ and replace any incorrect ones (keep filenames).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
