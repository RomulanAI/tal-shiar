#!/bin/bash
# Quartz entrypoint with continuous YAML frontmatter lint.
#
# Problem: The bot creates wiki pages with unquoted colons in YAML titles
# (e.g. title: Lesson 1: Foo) which crashes Quartz's YAML parser.
#
# Solution: Run a background loop that fixes frontmatter every 30 seconds.
# This catches bad pages before Quartz's hot-reload picks them up.

fix_frontmatter() {
    find /opt/quartz/content -name '*.md' -newer /tmp/.last-lint -exec \
        sed -i 's/^title: \([^"]\(.*:.*\)\)$/title: "\1"/' {} \; 2>/dev/null
    touch /tmp/.last-lint
}

# Initial fix before first build
touch /tmp/.last-lint
find /opt/quartz/content -name '*.md' -exec \
    sed -i 's/^title: \([^"]\(.*:.*\)\)$/title: "\1"/' {} \; 2>/dev/null

# Background lint loop — checks for new/modified files every 30s
(
    while true; do
        sleep 30
        fix_frontmatter
    done
) &

exec npx quartz build --serve --port 9090
