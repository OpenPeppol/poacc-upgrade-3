#!/bin/sh

PROJECT=$(dirname $(readlink -f "$0"))
BUILD_LOG="$PROJECT/build.log"

# Keep the complete output of every build step, while reserving the original
# stdout for the warning/error and test-summary reports printed at the end.
exec 3>&1
: > "$BUILD_LOG" || {
    echo "Unable to create build log: $BUILD_LOG" >&3
    exit 1
}
exec >> "$BUILD_LOG" 2>&1

# Delete target folder if found
if [ -e $PROJECT/target ]; then
    docker run --rm -i -v $PROJECT:/src alpine:3.11 rm -rf /src/target
fi

# Structure
docker run --rm -i \
    -v $PROJECT:/src \
    -v $PROJECT/target:/target \
    difi/vefa-structure:0.6.1

# Testing validation rules
docker run --rm -i -v $PROJECT:/src phelger/vefa-validator:2.4.3 build -x -t -n eu.peppol.poacc.upgrade.v3 -a rules -target target/validator-test /src

# Schematron
for sch in $PROJECT/rules/sch/*.sch; do
    docker run --rm -i -v $PROJECT:/src -v $PROJECT/target/schematron:/target klakegg/schematron prepare /src/rules/sch/$(basename $sch) /target/$(basename $sch)
done

# Fix ownership
docker run --rm -i -v $PROJECT:/src alpine:3.11 chown -R $(id -g $USER).$(id -g $USER) /src/target
BUILD_RESULT=$?

printf '\nWarnings and errors from %s:\n' "$BUILD_LOG" >&3
if ! grep -nE '([0-9]{2}:[0-9]{2}:[0-9]{2}([.,][0-9]{1,3})?[[:space:]]+(\|[[:space:]]*-?)?(WARN(ING)?|ERROR).+)' "$BUILD_LOG" >&3; then
    echo "None." >&3
fi

printf '\nBuild log from the last "tests performed" line:\n' >&3
if grep -qi 'tests performed' "$BUILD_LOG"; then
    awk 'tolower($0) ~ /tests performed/ { summary = ""; found = 1 } found { summary = summary $0 ORS } END { if (found) printf "%s", summary }' "$BUILD_LOG" >&3
else
    echo "No test summary found." >&3
fi

exit "$BUILD_RESULT"

rm -rf $PROJECT/target/site/files/PEPPOLBIS-Upgrade-Schematron.zip
rm -rf $PROJECT/target/site/files/PEPPOLBIS-Examples.zip

cd $PROJECT/target
zip -r site/files/PEPPOLBIS-Upgrade-Schematron.zip schematron/

# Example files
cd $PROJECT
zip -r target/site/files/PEPPOLBIS-Examples.zip rules/examples 

# Guides
docker run --rm -i -v $PROJECT:/documents -v $PROJECT/target:/target difi/asciidoctor

# Fix ownership
docker run --rm -i -v $PROJECT:/src alpine:3.11 chown -R $(id -g $USER).$(id -g $USER) /src/target
