#!/usr/bin/env bash

echo "Cleaning..."
kill_port() {
  pid=$(netstat -ano | findstr :8080 | awk '{print $5}')
  if [ -n "$pid" ]; then
    taskkill //F //PID "$pid" 2>/dev/null
  fi
}
kill_port
rm -rf build
mkdir -p build

echo "Building..."
# Compile only the application entrypoint to avoid compiling tests and other
# auxiliary files that the project includes in src/.
c3c compile src/main.c3 -o build/app

./build/app
