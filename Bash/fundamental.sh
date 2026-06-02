#!/bin/bash

echo "Hello World"

# variables 
Series="Lain"
Year=1998

# env variable
export APP_ENV=production``

echo "$Series is released in $Year"

# global


# input 
read -p "Enter your name: " name
echo "Hello $name"

# conditions 
read -p "Enter your age" age
if [ $age -ge 18 ]; then 
    echo "Adult"
fi

# loops 

## 
for i in 1 2 3 4 5
do 
    echo $i
done

# Command line args


