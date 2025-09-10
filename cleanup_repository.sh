#!/bin/bash

echo "Cleaning up experimental and duplicate files..."

# Remove experimental variants
rm -f main.c.with-emojis-broken
rm -f main.c.pre-swagger
rm -f env_v0.example
rm -f Makefile_v0

# Remove redundant README files (keep main ones)
rm -f README_v2.md
rm -f README_ENTERPRISE.md
rm -f README_EXTENSIONS.md
rm -f README_FINAL_UPDATED.md
rm -f README_METRICS_FIX.md
rm -f README_SCRIPTS.md

# Remove timestamped diagnostic files
rm -f diagnostic_*.txt
rm -f metrics_enhanced_*.txt
rm -f metrics_sample_*.txt
rm -f validation_results_*.json
rm -f pganalytics_debug_*.tar.gz
rm -rf logs_20*
rm -rf logs_enhanced_*
rm -rf pganalytics_debug_*

# Create single authoritative README
mv README.md README_original.md

echo "Repository cleanup completed!"
