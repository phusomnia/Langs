module zarr;

import std::io;

struct ZArr(T) {
    T* data,
    usz len,
    usz cap,
}

fn void init<T>(ZArr(T) *zarr)
{
    zarr.data = null;
    zarr.len  = 0;
    zarr.cap  = 0;
}

fn void push<T>(
    ZArr(T) *zarr, 
    T value
)
{
    if(zarr.len >= zarr.cap)
    {
        usz new_cap = zarr.cap == 0 ? 4 : zarr.cap * 2;
    }   
    
    zarr.data[zarr.len] = value;
    zarr.len++;
}

fn T get<T>(
    ZArr(T) *zarr, 
    usz index
)
{
    return arr.data[index];
}

fn void fixed_1d_arr()
{
    int[3] x = {1, 2, 3};

    int [*] y = {2, 3, 4};

    io::printn(foo(&x, 2));
    io::printn(foo(&y, 2));

    // len
    io::printfn("len of x: %d", x.len);

    ZArr(int) arr;
    init<int>(&arr);
    push<int>(&arr, 1);

    for(int i = 0; i < )
}

fn int foo(int *a, int idx) { 
    return a[idx];
}