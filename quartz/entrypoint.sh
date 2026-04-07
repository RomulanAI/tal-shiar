#!/bin/bash
# Auto-fix YAML frontmatter issues before Quartz builds.
# Quartz crashes on unquoted colons in title fields (e.g. "title: Lesson 1: Foo").
# This runs on every container start, so even if the bot creates bad frontmatter,
# Quartz won't crash.

find /opt/quartz/content -name '*.md' -exec \
  sed -i 's/^title: \([^"]\(.*:.*\)\)$/title: "\1"/' {} \; 2>/dev/null

exec npx quartz build --serve --port 9090
