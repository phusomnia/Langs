import std::io;
import std::time;
import zarr;

fn void main()
{
	types();
	io::printfn("default_loop(): %d", default_loop());
	io::printfn("default_loop(times: 100): %d", default_loop(foo: 100));
	test_va();
	zarr::fixed_1d_arr();
}

// Functions
fn void loop(int times)
{
	for(int i = 0; i < times; ++i)
	{
		io::printfn("Hello %d", i);
	}
}

fn int default_loop(int foo = 1)
{
	return foo;
}

// Vaargs
fn void test_va()
{
	// va_singletyped(1, 2, 3);

	int x = 1;
	any v = &x;
	va_variants_explicit(&&1, &x, v);
	va_variants_implicit(1, x, "foo");
	test_add();
}
fn void va_singletyped(int... args)
{
	io::printfn("count: %d", args.len);

	foreach(v : args)
	{
		io::printn(v);
	}
}
fn void va_variants_explicit(any... args)
{
	io::printfn("count: %d", args.len);

	foreach(v : args)
	{
		io::printn(v);
	}
}
fn void va_variants_implicit(args...)
{
	io::printfn("count: %d", args.len);

	foreach(v : args)
	{
		io::printn(v);
	}
}

// Methods
fn void test_add()
{
	int i = 3;
	int j = i.add(4);
	io::printfn("y: %d", j);
}
fn int int.add(int i, int other)
{
	return i + other;
}


fn void types()
{
	// primary basic_types
	int a = 1234;
	ulong b = 0xFFAABBCCDDEEFF;
	double d = 13.03e-04;
	char[*] hex = x"4865 6c6c 6f20 776f 726c 6421";
	bool yes = true;
	bool no = false;
	int* p = &a;
	void* vp = p;
	
	io::printfn("a was: %d", a);
	io::printfn("b in hex was: %x", b);
	io::printfn("d in scientific notation was: %e", d);
	io::printfn("Bytes as string: %s", (String)&hex);
	io::printfn("yes is %s", yes);
	io::printfn("no is %s", no);
	io::printfn("p  = %p", p);
	io::printfn("vp = %p", vp);
	io::printfn("&p = %p", &p); // addr p of p
	io::printfn("&vp = %p", &vp); // addr p of vp
	io::printfn("%s", p == vp ? "same" : "different");
	io::printfn("%s", &p == &vp ? "same" : "different");

	int x;  
	int y @noinit;  

	io::printfn("x was: %d", x);
	io::printfn("y was: %d", y);
}


