module runtime::socket;
import std::net;
import std::net::tcp;
import libc;

struct Socket
{
    net::Socket sock;
}

net::Socket listener;
TcpServerSocket* listener_ptr;
bool listening = false;

fn Socket socket_accept(int port)
{
    if (!listening)
    {
        listener = tcp::listen("127.0.0.1", port, 10, net::SocketOption.REUSEADDR)!!;
        listener_ptr = (TcpServerSocket*)&listener;
        listening = true;
    }
    net::Socket client = tcp::accept(listener_ptr)!!;
    return { .sock = client };
}

fn String socket_read_all(Socket* s)
{
    char[8192] buf;
    sz bytes = s.sock.read(buf[..])!!;
    char[] data = mem::new_array(char, bytes);
    libc::memcpy(data.ptr, &buf, (usz)bytes);
    return (String)data;
}

fn void socket_write(Socket* s, String data)
{
    s.sock.write(data)!!;
}

fn void socket_close(Socket* s)
{
    s.sock.close()!!;
}