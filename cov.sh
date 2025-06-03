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

if ! jq empty "$INPUT_FILE" 2>/dev/null; then
    echo "Error: Invalid JSON format in '$INPUT_FILE'" >&2
    exit 1
fi

# Check if we can find generations field in the nested structure
GENERATIONS_PATH=$(jq -r '
def find_generations(path):
  if type == "object" then
    if has("generations") then
      path + ["generations"]
    else
      to_entries[] | .value | find_generations(path + [.key // "unknown"])
    end
  else
    empty
  end;
find_generations([]) | join(".")
' "$INPUT_FILE" 2>/dev/null)

if [ -z "$GENERATIONS_PATH" ]; then
    echo "Error: 'generations' field not found in JSON structure" >&2
    echo "Available top-level fields:"
    jq -r 'keys[]?' "$INPUT_FILE" 2>/dev/null || echo "Could not determine JSON structure"
    exit 1
fi

# Parse JSON and generate coverage output with null checks
# Handle nested structure by iterating through all objects that have generations
jq -r '
def process_generations:
  if type == "object" then
    if has("generations") and (.generations | type) == "array" then
      # Get all generations data
      .generations as $generations |
      # Find the maximum time to determine how many minutes to show
      ($generations | map(if .time == null then 0 else .time end) | max / 60 | ceil) as $max_minutes |
      # Create array of minute intervals from 0 to max_minutes
      [range(0; $max_minutes + 1)] as $minutes |
      # For each minute, find the latest generation data up to that time
      $minutes[] as $minute |
      # Find the last generation that occurred at or before this minute
      ($generations | map(select(.time != null and (.time / 60) <= $minute)) | 
       if length > 0 then (sort_by(.time) | last) else null end) as $latest_gen |
      # Format output
      ($minute | if . < 10 then "0\(.)" else "\(.)" end) as $formatted_minute |
      if $latest_gen == null then
        "\($formatted_minute)m: 0 Edges, 0 Instrs"
      else
        (if $latest_gen.branch_coverage_value == null then 0 else $latest_gen.branch_coverage_value end) as $edges |
        (if $latest_gen.code_coverage_value == null then 0 else $latest_gen.code_coverage_value end) as $instrs |
        "\($formatted_minute)m: \($edges) Edges, \($instrs) Instrs"
      end
    else
      to_entries[]? | .value | process_generations
    end
  else
    empty
  end;
process_generations
' "$INPUT_FILE"
