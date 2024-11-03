import os
import pty
import termios
import fcntl
import tty
import select
import sys
import struct

def _set_pty_size(fd, rows, cols):
    winsize = struct.pack("HHHH", rows, cols, 0, 0)
    fcntl.ioctl(fd, termios.TIOCSWINSZ, winsize)

# Mostly copy pasta from claude 3.5
def spawn_terminal(fifo_path, sh_binary = "bash", cols = 100, rows = 100):
    master, slave = pty.openpty()
    _set_pty_size(master, cols, rows)
    tty.setraw(master)

    pid = os.fork()
    if pid == 0:  # Child
        os.close(master)
        os.setsid()
        fcntl.ioctl(slave, termios.TIOCSCTTY, 0)
        os.dup2(slave, 0)
        os.dup2(slave, 1)
        os.dup2(slave, 2)
        os.execvp(sh_binary, [sh_binary])
    else:
        os.close(slave)
        fifo = os.open(fifo_path, os.O_RDONLY | os.O_NONBLOCK)

        while True:
            r, w, e = select.select([master, fifo], [], [])
            for fd in r:
                if fd == master:
                    try:
                        data = os.read(master, 1024)
                        if data:
                            os.write(sys.stdout.fileno(), data)
                    except OSError:
                        return
                elif fd == fifo:
                    try:
                        cmd = os.read(fifo, 1024)
                        if cmd:
                            os.write(sys.stdout.fileno(), cmd.rstrip(b'\n\r'))
                            os.write(master, cmd)
                        else:
                            # Reset the fifo
                            fifo = os.open(fifo_path, os.O_RDONLY | os.O_NONBLOCK)
                    except OSError:
                        continue

if __name__ == '__main__':
    fifo_path = "/tmp/terminal_control"
    if not os.path.exists(fifo_path):
        os.mkfifo(fifo_path)

    try:
        cols, rows = os.get_terminal_size()
        spawn_terminal(fifo_path, cols=cols, rows=rows)
    finally:
        os.unlink(fifo_path)
