# Basic commands

There should be 3 kinds of commands:
- Start or modify a connection (`sc start` and `sc command`)
- TODO: Start a non-interactive command (`sc run` or `sc`)
  - Separate output in a file
  - possibly with input
- TODO: Start an interactive (tty) command (`sc interactive`)
  - Separate output, possibly use
  - definitively with input, attachable

## Background interactive

`sc start COMMAND`

- run the command in the background, open a connection
- Prints out the path to the background command infos

## send command

`sc run PATH COMMAND`

- Run the command, store all output
- If connection is 0, run as "simple" subprocess
- Otherwise, send the command to the interactive shell

`sc last COMMAND`

- send the command to the newest opened background process
