#!/bin/bash
set -euo pipefail

# Create consolidated directory
mkdir -p consolidated

# Get current version from local file (if exists), increment patch
default_version="1.0.0"
if [[ -f consolidated/qlik-cloud.json ]]; then
  current_version=$(jq -r '.info.version' consolidated/qlik-cloud.json 2>/dev/null || echo "$default_version")
else
  current_version="$default_version"
fi
echo "Detected current version: $current_version"
if [[ "$current_version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  major=${BASH_REMATCH[1]}
  minor=${BASH_REMATCH[2]}
  patch=${BASH_REMATCH[3]}
  new_patch=$((patch + 1))
  new_version="$major.$minor.$new_patch"
else
  new_version="$default_version"
fi
echo "New version to be written: $new_version"

# Initialize the base OpenAPI structure with incremented version
cat > consolidated/qlik-cloud.json << EOF
{
  "openapi": "3.0.3",
  "info": {
    "title": "Qlik Cloud",
    "description": "Consolidated OpenAPI specification for published Qlik Cloud APIs.\n\nSee [withdave/qc-specs](https://github.com/withdave/qc-specs) for detailed configuration steps.\n\n## Authentication\n\nEndpoints on the `/api` path in this collection support authentication via API key or OAuth2. Use API key authentication if you want to get started fast or access content as your interactive user, or OAuth2 Machine-to-Machine authentication for the best security and deeper integration.",
    "version": "$new_version",
    "contact": {
      "name": "Dave Channon",
      "url": "https://github.com/withdave/qc-specs"
    }
  },
  "servers": [
    {
      "url": "https://tenantname.region.qlikcloud.com",
      "description": "Your Qlik Cloud tenant URL"
    }
  ],
  "security": [
    {
      "BearerAuth": []
    }
  ],
  "paths": {},
  "components": {
    "securitySchemes": {
      "BearerAuth": {
        "type": "http",
        "scheme": "bearer",
        "bearerFormat": "JWT"
      }
    },
    "schemas": {}
  }
}
EOF

# Function to merge OpenAPI specs
merge_openapi_specs() {
    local spec_file="$1"
    local api_name=$(basename "$spec_file" .json)
    
    echo "Processing: $api_name"
    
    # Create a temporary file for this spec's paths and components
    local temp_file="temp_${api_name}_spec.json"
    
    # Extract paths and components from the spec
    jq -r '
      {
        paths: .paths,
        components: (.components // {})
      }
    ' "$spec_file" > "$temp_file"
    
    # Merge paths into the main spec, defensively coalescing null schemas to {}
    jq -s '
      .[0] as $main |
      .[1] as $spec |
      $main + {
        paths: ($main.paths + $spec.paths),
        components: {
          schemas: ((($main.components.schemas // {}) + ($spec.components.schemas // {})) // {})
        }
      }
    ' consolidated/qlik-cloud.json "$temp_file" > consolidated/temp_merged.json

    mv consolidated/temp_merged.json consolidated/qlik-cloud.json
    rm -f "$temp_file"

    # Check for any null or non-object schemas in the just-merged file (for debugging)
    if jq -e '.components.schemas | to_entries[] | select(.value == null or (type != "object" and type != "array"))' consolidated/qlik-cloud.json > /dev/null; then
      echo "WARNING: Found null or non-object schemas in consolidated/qlik-cloud.json after merging $api_name"
      jq '.components.schemas | to_entries[] | select(.value == null or (type != "object" and type != "array"))' consolidated/qlik-cloud.json
    fi
}

# Process all spec files
for spec_file in specs/*.json; do
    if [[ -f "$spec_file" ]]; then
        filename=$(basename "$spec_file")
        merge_openapi_specs "$spec_file"
    fi
done

echo "Consolidated OpenAPI specification created successfully"
echo "Files created:"
echo "  - consolidated/qlik-cloud.json"