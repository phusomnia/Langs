#!/bin/bash

init() {
    name="main"
    echo "Compiling ..."
    wsl.exe gcc -c "$name.c" -o "$name.o"
    wsl.exe gcc -o "$name.out" "$name.o"
    ./"$name.out"
    rm "$name.o"
    rm "$name.out"
}

create_lib() {
    wsl.exe gcc -c swap.cpp genNumber.cpp
    ar cr libSwapGen.a swap.o genNumber.o
    nm libSwapGen.a
    file libSwapGen.a
    clean
}

static_link() {
    create_lib
    wsl.exe gcc main.cpp -L. -lSwapGen -o main_static.out
    ./main_static.out
    clean
}

dynamic_link() {
    wsl.exe gcc -shared swap.cpp genNumber.cpp -o libswap.dll -Wl,--out-implib,libswap.dll.a
    wsl.exe gcc main.cpp -L. -lswap -o main_dynamic.out
    ./main_dynamic.out
    clean
}

clean() {
    rm -f *.o *.out *.dll *.dll.a
}

gcc_build_unix() {
    output="app"
    wsl.exe gcc -Wall -Wextra -O2 main_unix.c logger.c -o "$output"
    wsl.exe ./"$output" 4
    wsl.exe rm -f "$output"
}

"$@"