# DateEvent Style Album

## Overview
A Flutter desktop app that organizes iPhone photos and Live Photos into categorized folders. Processing is primarily by date, with image-analysis LLM for content identification and EXIF location data for trip detection.

## Core Features

### 1. Folder Selection
- Browse and select a source folder containing photos/Live Photos
- Browse and select a destination folder for organized output

### 2. File Scanning & Parsing
- Scan folder recursively for photos (jpg, jpeg, heic, heif, png, gif)
- Detect Live Photo pairs (`.heic` + `.mov` with same filename)
- Read EXIF data: date taken, GPS location, camera model
- Extract creation date from file metadata as fallback

### 3. Classification Logic
Three passes in priority order:

#### Pass 1 — Trip Detection (by date clusters + location)
- Group photos by date proximity (consecutive days)
- Within each date range, check if GPS locations are from a different region than the user's home
- If 2+ consecutive days with photos all in a non-home location → classify as "Trip: [Location Name]"
- Use reverse geocoding (via EXIF lat/lon → city/country name)

#### Pass 2 — Content Classification (via LLM vision)
- For remaining unclassified photos, batch-send to LLM with image understanding
- Classify into categories: Food, Pet, Family, Portrait, Landscape, Architecture, Document, Receipt, Art, Event, Other
- LLM prompt: "Analyze this photo and classify into one category. Return only the category name."

#### Pass 3 — Daily Life Organization
- Photos not classified as Trip or any specific category → organize by date
- Folder structure: `YYYY/YYYY-MM-DD/`

### 4. Output Structure
```
Destination/
├── Trips/
│   ├── Trip_Name_2025-03/
│   │   ├── photo1.heic
│   │   ├── photo1.mov
│   │   ├── photo2.heic
│   │   └── ...
│   └── Trip_Name2_2024-12/
├── By_Content/
│   ├── Food/
│   │   └── 2025-03-15_lasagna.jpg
│   ├── Pet/
│   │   └── 2025-04-01_cat.jpg
│   ├── Family/
│   └── ...
├── By_Date/
│   ├── 2025/
│   │   ├── 2025-03-15/
│   │   ├── 2025-03-16/
│   │   └── ...
│   └── 2024/
│       └── ...
└── Uncategorized/
    └── (files that could not be read)
```

### 5. Preview & Confirm
- Show summary of detected items before organizing:
  - "Found 230 photos | 3 trips detected | 45 food photos | 32 pets | ..."
- Show folder tree preview
- User clicks "Organize" to execute
- Progress bar during processing

### 6. Configurable Settings
- Home GPS location (for trip detection)
- Whether to copy vs move files
- LLM API key and model selection
- Classification confidence threshold
- Custom output folder naming

## Tech Stack
- **Flutter** (Windows desktop)
- **exif** dart package for EXIF reading
- **geocoding** for reverse geocoding
- **LLM API** (OpenAI-compatible: gpt-4o or similar vision model) for photo classification
- **Provider** or **Riverpod** for state management
- **file_picker** for folder selection

## Future Enhancements
- Duplicate detection (by hash)
- Video organization
- Face recognition grouping
- Tag-based search within the app
- Export to cloud albums
