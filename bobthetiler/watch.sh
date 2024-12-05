#!/bin/bash

inotifywait -m -e modify -r . --include '.*\.rs$' | xargs  -I{} sh -c 'cargo run'
