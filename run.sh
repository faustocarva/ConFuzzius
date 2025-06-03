#!/bin/bash

# Check if required arguments are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 <csv-file> <path-to-B2> [running-time]"
    echo "Example: $0 contracts.csv /path/to/B2 300"
    echo "Example: $0 contracts.csv ./B2 600"
    exit 1
fi

CSV_FILE="$1"
B2_PATH="$2"
RUNNING_TIME="${3:-300}"  # Default to 300 seconds if not provided

# Check if CSV file exists
if [ ! -f "$CSV_FILE" ]; then
    echo "Error: CSV file '$CSV_FILE' not found!"
    exit 1
fi

# Check if fuzzer exists
if [ ! -f "fuzzer/main.py" ]; then
    echo "Error: fuzzer/main.py not found!"
    exit 1
fi

# Create results directory if it doesn't exist
if [ ! -d "results" ]; then
    echo "Creating results directory..."
    mkdir -p results
fi

echo "Starting fuzzer execution for all contracts in $CSV_FILE"
echo "B2 directory: $B2_PATH"
echo "Running time per contract: $RUNNING_TIME seconds"
echo "----------------------------------------"

# Skip header line and process each contract
tail -n +2 "$CSV_FILE" | while IFS=',' read -r contract_file contract_name solc_version; do
    # Remove any whitespace/carriage returns
    contract_file=$(echo "$contract_file" | tr -d '\r\n ')
    contract_name=$(echo "$contract_name" | tr -d '\r\n ')
    solc_version=$(echo "$solc_version" | tr -d '\r\n ')
    
    # Skip empty lines
    if [ -z "$contract_file" ] || [ -z "$contract_name" ] || [ -z "$solc_version" ]; then
        continue
    fi
    
    # Construct the path to the contract
    contract_path="$B2_PATH/$contract_file/$contract_file.sol"
    
    echo "Processing: $contract_name"
    echo "File: $contract_path"
    echo "Solc version: $solc_version"
    
    # Check if contract file exists
    if [ ! -f "$contract_path" ]; then
        echo "Warning: Contract file '$contract_path' not found! Skipping..."
        echo "----------------------------------------"
        continue
    fi

    echo "Creating results directory..."
    mkdir -p results/${contract_file}
    touch results/${contract_file}/log.txt
    
    # Run the fuzzer command
    echo "Running fuzzer..."
    python3 fuzzer/main.py \
        -s "$contract_path" \
        -c "$contract_name" \
        --solc "$solc_version" \
        --evm byzantium \
        -t "$RUNNING_TIME" \
        -r "results/${contract_file}/log.json"
    
    # Check if the command was successful
    if [ $? -eq 0 ]; then
        echo "✓ Successfully completed fuzzing for $contract_name"
    else
        echo "✗ Error occurred while fuzzing $contract_name"
    fi
    
    echo "----------------------------------------"
done

echo "All contracts processed!"
