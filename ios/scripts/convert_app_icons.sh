#!/bin/bash

# Convert a source image to iOS app icons in multiple sizes using macOS sips utility
# Usage: ./convert_app_icons.sh <source_image> <output_directory>

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source_image> <output_directory>"
    echo "Example: $0 icon_source.png App/Resources/Assets.xcassets/AppIcon.appiconset"
    exit 1
fi

SOURCE_IMAGE="$1"
OUTPUT_DIR="$2"

if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "✗ Source image not found: $SOURCE_IMAGE"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "✓ Loaded source image: $SOURCE_IMAGE"

# Generate each icon size
generate_icon() {
    local filename=$1
    local size=$2
    local output_path="$OUTPUT_DIR/$filename"

    sips -z $size $size "$SOURCE_IMAGE" --out "$output_path" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "✓ Converted $filename (${size}x${size})"
    else
        echo "✗ Error converting $filename"
        exit 1
    fi
}

generate_icon "Icon-20@2x.png" 40
generate_icon "Icon-20@3x.png" 60
generate_icon "Icon-29@2x.png" 58
generate_icon "Icon-29@3x.png" 87
generate_icon "Icon-40@2x.png" 80
generate_icon "Icon-40@3x.png" 120
generate_icon "Icon-60@2x.png" 120
generate_icon "Icon-60@3x.png" 180
generate_icon "Icon-1024.png" 1024

echo ""
echo "✓ Successfully converted all app icons in $OUTPUT_DIR"
