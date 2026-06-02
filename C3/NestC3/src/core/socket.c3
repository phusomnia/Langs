module core::socket;

import std::net;
import std::net::tcp;
import std::io;

struct Socket
{
    TcpSocket sock;
}

struct Server
{
    TcpServerSocket sock;
}

// --- Server ---

fn Server listen(String host, int port, net::SocketOption... options)
{
    Server s;
    s.sock = tcp::listen(host, port, 128, ...options) !!;
    return s;
}

fn Socket? Server.accept(&self)
{
    Socket c;
    c.sock = tcp::accept(&self.sock) !;
    return c;
}

fn void Server.close(&self)
{
    (void)self.sock.close();
}

// --- I/O ---

fn sz? Socket.read(&self, char[] buf)
{
    return self.sock.read(buf);
}

fn sz? Socket.read_exact(&self, char[] buf)
{
    sz total;
    while (total < buf.len)
    {
        sz? n = self.sock.read(buf[total..]);
        if (catch err = n) return err~;
        if (!n) return io::EOF~;
        total += n;
    }
    return total;
}

fn sz? Socket.peek(&self, char[] buf)
{
    return self.sock.peek(buf);
}

fn void Socket.write(&self, char[] data)
{
    (void)self.sock.write(data) !!;
}

fn void Socket.write_line(&self, String msg)
{
    (void)self.sock.write(msg) !!;
    (void)self.sock.write("\n") !!;
}

fn String? Socket.read_line(&self)
{
    return io::readline(tmem, &self.sock);
}

fn String? Socket.read_all(&self)
{
    char[] data = io::read_fully(tmem, &self.sock) !!;
    return (String)data;
}

// --- Control ---

fn void Socket.close(&self)
{
    (void)self.sock.close();
}

fn void Socket.shutdown(&self, net::SocketShutdownHow how)
{
    (void)self.sock.shutdown(how);
}

fn void Socket.set_non_blocking(&self, bool value)
{
    (void)self.sock.sock.set_non_blocking(value);
}

fn bool Socket.poll_read(&self, long timeout_ms)
{
    net::Poll p = { self.sock.sock, (net::PollSubscribe)0, (net::PollEvent)0 };
    p.events = net::PollSubscribe.READ;
    ulong? n = net::poll_ms((&p)[:1], timeout_ms);
    if (try n)
    {
        return n > 0 && (p.revents & net::PollEvent.READ) != (net::PollEvent)0;
    }
    return false;
}
