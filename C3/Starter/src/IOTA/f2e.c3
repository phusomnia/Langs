module iota::f2e;

import std::io;
import std::io::file;
import libc;

fn char[]? load_file(String file_name)
{
	File fh = file::open(file_name, "rb")!;
	defer (void)fh.close();

	char[4096] buf;
	usz total_read = 0;
	char[65536] result;
	
	while (total_read < result.len)
	{
		usz read = (usz)fh.read(buf[:4096])!;
		if (read == 0) break;
		
		if (total_read + read > result.len) break;
		
		libc::memcpy(&result[total_read], &buf, read);
		total_read += read;
	}

	return result[:total_read];
}