module core::log;

import std::io;

const String RESET = "\x1b[0m";
const String RED   = "\x1b[31m";
const String GREEN = "\x1b[32m";
const String YELLOW= "\x1b[33m";
const String BLUE  = "\x1b[34m";
const String GRAY  = "\x1b[90m";

struct BufData { char[4096] buf; sz written; }

fn void? buf_write(void* data, char c)
{
    BufData* b = data;
    if (b.written >= 1024) return io::BUFFER_EXCEEDED~;
    b.buf[b.written++] = c;
}

fn void info(String fmt, args...)
{
    BufData bd;
    io::Formatter f;
    f.init(&buf_write, &bd);
    f.printf("%s[INFO] ", BLUE) !!;
    f.vprintf(fmt, args) !!;
    f.printf("%s\n", RESET) !!;
    io::print((String)bd.buf[:bd.written]);
}

fn void warn(String fmt, args...)
{
    BufData bd;
    io::Formatter f;
    f.init(&buf_write, &bd);
    f.printf("%s[WARN] ", YELLOW) !!;
    f.vprintf(fmt, args) !!;
    f.printf("%s\n", RESET) !!;
    io::print((String)bd.buf[:bd.written]);
}

fn void error(String fmt, args...)
{
    BufData bd;
    io::Formatter f;
    f.init(&buf_write, &bd);
    f.printf("%s[ERROR] ", RED) !!;
    f.vprintf(fmt, args) !!;
    f.printf("%s\n", RESET) !!;
    io::print((String)bd.buf[:bd.written]);
}

fn void success(String fmt, args...)
{
    BufData bd;
    io::Formatter f;
    f.init(&buf_write, &bd);
    f.printf("%s[SUCCESS] ", GREEN) !!;
    f.vprintf(fmt, args) !!;
    f.printf("%s\n", RESET) !!;
    io::print((String)bd.buf[:bd.written]);
}

fn void debug(String fmt, args...)
{
    BufData bd;
    io::Formatter f;
    f.init(&buf_write, &bd);
    f.printf("%s[DEBUG] ", GRAY) !!;
    f.vprintf(fmt, args) !!;
    f.printf("%s\n", RESET) !!;
    io::print((String)bd.buf[:bd.written]);
}