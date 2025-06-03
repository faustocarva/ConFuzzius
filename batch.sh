#!/bin/bash

# Check if results directory is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <results_directory> [parse_script_path]"
    echo "Example: $0 ./results ./parse_vulnerabilities.sh"
    exit 1
fi

RESULTS_DIR="$1"
PARSE_SCRIPT="${2:-./parse_vulnerabilities.sh}"

# Check if results directory exists
if [ ! -d "$RESULTS_DIR" ]; then
    echo "Error: Results directory '$RESULTS_DIR' not found!"
    exit 1
fi

# Check if parse script exists
if [ ! -f "$PARSE_SCRIPT" ]; then
    echo "Error: Parse script '$PARSE_SCRIPT' not found!"
    exit 1
fi

# Make parse script executable
chmod +x "$PARSE_SCRIPT"

echo "Processing contracts in $RESULTS_DIR..."

# Counter for processed contracts
PROCESSED=0
TOTAL=0

# Count total directories with log.json
for contract_dir in "$RESULTS_DIR"/*; do
    if [ -d "$contract_dir" ] && [ -f "$contract_dir/log.json" ]; then
        ((TOTAL++))
    fi
done

echo "Found $TOTAL contracts with log.json files"

# Process each contract directory
for contract_dir in "$RESULTS_DIR"/*; do
    if [ -d "$contract_dir" ]; then
        contract_name=$(basename "$contract_dir")
        log_json="$contract_dir/log.json"
        log_txt="$contract_dir/log.txt"
        
        if [ -f "$log_json" ]; then
            echo "Processing $contract_name..."
            
            # Run the parse script and save output to log.txt
            if "$PARSE_SCRIPT" "$log_json" > "$log_txt" 2>/dev/null; then
                ((PROCESSED++))
                # Count vulnerabilities found
                vuln_count=$(wc -l < "$log_txt" 2>/dev/null || echo "0")
                echo "  → $vuln_count vulnerabilities found in $contract_name"
            else
                echo "  → Error processing $contract_name"
                # Create empty log.txt on error
                touch "$log_txt"
            fi
        else
            echo "Skipping $contract_name (no log.json found)"
        fi
    fi
done

echo ""
echo "Processing complete!"
echo "Processed: $PROCESSED/$TOTAL contracts"
