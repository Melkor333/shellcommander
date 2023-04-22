# Basic commands

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
