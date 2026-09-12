#!/usr/bin/env sh
# Vercel "Build Command" for emotely-web: a static Jaspr build into
# build/jaspr (the project's Output Directory), sitemap included.
set -eu

export PATH="$PWD/.dart-sdk/bin:$HOME/.pub-cache/bin:$PATH"

jaspr build --sitemap-domain https://getemotely.com

# build_web_compilers copies every package's non-Dart assets next to the
# compiled JS (analyzer docs, test runner pages, ...). Nothing in the site
# references them; only the compiled entrypoint and our own files ship.
rm -rf build/jaspr/.dart_tool build/jaspr/.build.manifest build/jaspr/packages
ls -la build/jaspr
