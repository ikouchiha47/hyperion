#!/bin/bash

if [[ "$1" == "rebuild" ]]; then
	cmake -B dist
	cp ./dist/compile_commands.json .
fi

cmake --build dist
./dist/quicknanobrowser
