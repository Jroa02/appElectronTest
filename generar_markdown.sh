#!/bin/bash

# Get all the tags in the repository
tags=$(git tag)

# Convert the tags into an array
IFS=$'\n' read -r -d '' -a tags_array <<< "$tags"

# Check if the tags list is empty
if [ ${#tags_array[@]} -eq 0 ]; then
  echo "Error: No tags found in the repository."
  exit 1
fi

# Get the last and the previous tag
last_tag=${tags_array[-1]}
if [ ${#tags_array[@]} -gt 1 ]; then
  previous_tag=${tags_array[-2]}
else
  # If no previous tag, use the first commit
  previous_tag="$(git rev-list --max-parents=0 HEAD)"
fi

# Assign the tags to the variables TAG1 and TAG2
TAG1=$previous_tag
TAG2=$last_tag
OUTPUT_FILE="recent_changes.md"

# Check if the first tag exists
if [ -z "$TAG1" ]; then
  echo "Error: The first tag must be provided as an argument."
  exit 1
fi

# Generate the header of the Markdown file
echo "# Release Notes for $TAG2" > $OUTPUT_FILE
echo "## What's Changed" >> $OUTPUT_FILE

# Check if the second tag exists
if git rev-parse "$TAG2" >/dev/null 2>&1; then
  # If both tags exist, show the commits between them
  git log $TAG1..$TAG2 --oneline --pretty=format:"- %s" >> $OUTPUT_FILE
else
  # If the second tag does not exist, show commits from the beginning of the repo to the first tag
  git log --oneline $TAG1 --pretty=format:"- %s" >> $OUTPUT_FILE
fi

# Add contributors section
echo "" >> $OUTPUT_FILE
echo "## Contributors:" >> $OUTPUT_FILE

# Get the list of contributors (commit authors)
git log $TAG1..$TAG2 --pretty=format:"%an" | sort | uniq | while read contributor; do
  echo "- $contributor" >> $OUTPUT_FILE
done

echo "File $OUTPUT_FILE generated successfully."
