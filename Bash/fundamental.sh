#!/bin/bash

echo "Hello World"

# variables 
Series="Lain"
Year=1998
echo "$Series is released in $Year"

## env variable
export APP_ENV=production

## Readonly
readonly VERSION="1.0"
# VERSION="2.0"
echo "$VERSION"

## Local variable
greet() {
    local name="John"
    echo "$name"
}
greet

## Args 
echo "Current: $0"
echo "First args: $1" 
echo "Count: $#"  
echo "Proccess ID: $$"
echo "Bg proc: $!"

# Qouting
## Single quotes
name="Terry"
echo '$name'
echo "he said \"Hello\""

# Brace Exapansion
echo file{1..5}.txt
echo ~

# Command sub
current=$(pwd)
echo "Current file: $current"

# Arithmetric
echo $((5 + 3))
expr 10 + 5
count=0
((count++))
((count--))
echo $count
