#!/bin/bash

set -e

APP_NAME="quicknanobrowser"
BUILD_DIR="./dist"
BINARY="$BUILD_DIR/$APP_NAME"
PID_FILE="$BUILD_DIR/$APP_NAME.pid"

function kill_running_app() {
    if [[ -f $PID_FILE ]]; then
        PID=$(cat $PID_FILE)
        if ps -p $PID > /dev/null 2>&1; then
            echo "Killing running instance of $APP_NAME (PID $PID)"
            kill $PID
            rm -f $PID_FILE
        fi
    fi
}

if [[ "$1" =~ "rebuild" ]]; then
    echo "Rebuilding the project..."
    rm -rf $BUILD_DIR
    cmake -B $BUILD_DIR
    cp $BUILD_DIR/compile_commands.json .
fi

if [[ "$1" == "clean" || "$1" == "rebuild" ]]; then
    kill_running_app
    cmake --build $BUILD_DIR --clean-first
else
    cmake --build $BUILD_DIR
fi

kill_running_app

echo "Launching $APP_NAME..."

if [[ "$1" =~ "daemon" ]]; then
    $BINARY & 
    echo $! > $PID_FILE
fi

$BINARY
