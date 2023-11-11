#!/bin/bash

# Take four integer arguments: the count of errors, the count of warnings, the count of notes, and the lines of code.
# Then, calculate the normalized vulnerability scores by adding the count of errors multiplied by 10,
# the count of warnings multiplied by 3, and the count of notes multiplied by 1, and then dividing the sum by the thousand lines of code.
# Finally, print the results to the console.

# Add your code below this line. Do not modify anything above this line.

ERRORS=$1
WARNINGS=$2
NOTES=$3
LOC=$4

echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"
echo "Notes: $NOTES"
echo "Lines of Code: $LOC"

# Each weight per pipeline or build environment variables.
: "${WEIGHT_ERROR:=10}"
: "${WEIGHT_WARNING:=3}"
: "${WEIGHT_NOTE:=1}"
: "${LOC_SCALER:=1000}"

WEIGHTED_ERRORS=$((ERRORS * $WEIGHT_ERROR))
WEIGHTED_WARNINGS=$((WARNINGS * $WEIGHT_WARNING))
WEIGHTED_NOTES=$((NOTES * $WEIGHT_NOTE))

echo "Weighted Errors: $WEIGHTED_ERRORS"
echo "Weighted Warnings: $WEIGHTED_WARNINGS"
echo "Weighted Notes: $WEIGHED_NOTES"

NVS=$(echo "scale=2; (${WEIGHTED_ERRORS} + ${WEIGHTED_WARNINGS} + ${WEIGHTED_NOTES}) / (${LOC} / ${LOC_SCALER})" | bc)

echo "NVS: $NVS"
