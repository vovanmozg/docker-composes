#!/bin/sh

if [ "$(printf '%s' "$BUNDLE")" == 1 ]; then
  bundle
fi

ruby ./run.rb