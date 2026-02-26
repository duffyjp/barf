#!/bin/bash
set -e

# Ensure gems are installed (needed because the volume mount
# overlays the /gem directory from the image build)
bundle check || bundle install

exec "$@"
