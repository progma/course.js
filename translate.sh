#!/usr/bin/env sh
mkdir -p js
coffee --output js/ --watch --compile lib/
