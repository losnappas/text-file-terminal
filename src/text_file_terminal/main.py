import argparse
from .text_file_terminal import spawn_terminal

def main():
  p = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)

  p.add_argument('--commands-fifo', dest='fifo_path', default='/tmp/terminal_control',
      help='FIFO where the program should expect input from. The fifo is expected to exists already.')
  p.add_argument(
      '--sh-binary', dest='sh_binary', default='bash',
      help='Which shell binary to launch.')
  p.add_argument(
      '--rows', dest='rows', type=int,
      default=100, help='Terminal height from e.g. `tput lines`.')
  p.add_argument(
      '--cols', dest='cols', type=int,
      default=100, help='Terminal width from e.g. `tput cols`.')

  opts = p.parse_args()

  spawn_terminal(**vars(opts))


if __name__ == "__main__":
  main()
    # import os
    # fifo_path = "/tmp/terminal_control"
    # if not os.path.exists(fifo_path):
    #     os.mkfifo(fifo_path)

    # try:
    #     # cols, rows = os.get_terminal_size()
    #     spawn_terminal(fifo_path, cols=100, rows=100)
    # finally:
    #     os.unlink(fifo_path)
