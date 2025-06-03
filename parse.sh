#!/bin/bash
# Check if input file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <input_json_file>" >&2
    exit 1
fi
INPUT_FILE="$1"
# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found!" >&2
    exit 1
fi
# Parse JSON and extract vulnerabilities with type conversion
jq -r '
to_entries[] | 
.key as $contract_name | 
.value.errors | 
to_entries[] | 
.value[] | 
# Convert vulnerability types
(.type | 
    if . == "Block Dependency" then "BlockstateDependency"
    elif . == "Unchecked Return Value" then "MishandledException"
    elif . == "Reentrancy" then "Reentrancy"
    elif . == "Leaking Ether" then "EtherLeak"
    elif . == "Integer Overflow" then "IntegerBug"
    else empty
    end
) as $converted_type |
# Skip if conversion resulted in empty (type not in our filter list)
select($converted_type != null) |
# Convert time from seconds to days:hours:minutes:seconds
(.time | floor) as $total_seconds |
($total_seconds / 86400 | floor) as $days |
(($total_seconds % 86400) / 3600 | floor) as $hours |
(($total_seconds % 3600) / 60 | floor) as $minutes |
($total_seconds % 60) as $seconds |
"[\(if $days < 10 then "0" else "" end)\($days):\(if $hours < 10 then "0" else "" end)\($hours):\(if $minutes < 10 then "0" else "" end)\($minutes):\(if $seconds < 10 then "0" else "" end)\($seconds)] found \($converted_type) at \(.line):\(.column)"
' "$INPUT_FILE"
