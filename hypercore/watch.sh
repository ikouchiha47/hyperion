#/bin/bash

./run.sh

inotifywait -m -e modify -e create -r . --include '.*\.qml$' | xargs -t -I{} ./run.sh daemon
