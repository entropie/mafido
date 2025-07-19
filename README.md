# Mafido

**Mafido** is a lightweight, parallelized file processing tool with no dependencies except ruby 3.x. It recursively scans a directory for files with a specific extension and executes a user-defined shell command for each file. The command supports simple templating via placeholders like `%input%` and `%output%`.

## Installation

```sh
git clone https://example.com/mafido.git
cd mafido
chmod +x bin/mafido.rb
```

## Example

```sh
./bin/mafido.rb \
  --path ./input \
  --extension flac \
  --jobs 4 \
  --command "ffmpeg -i %input% %output%.mp3" \
  --remove
```

## Placeholders

- `%input%` — full path to the input file
- `%output%` — path without the original extension (can be extended by appending `.ext` in the command, e.g. `%output%.mp3`)

## ⚙️ Options

| Option              | Description                                      |
|---------------------|--------------------------------------------------|
| `-p`, `--path`      | Root path to search for input files              |
| `-e`, `--extension` | File extension to process (e.g., `flac`)         |
| `-j`, `--jobs`      | Number of parallel threads (default: 1)          |
| `-c`, `--command`   | Shell command to execute per file                |
| `-r`, `--remove`    | Delete input file after processing               |
| `-m`, `--mock`      | Dry run; simulate command execution              |
| `-l`, `--list`      | Print matching files and exit                    |
| `-v`, `--verbose`   | Enable verbose logging                           |

## ommand via STDIN

You can also pass the command via standard input:

```sh
echo ffmpeg -v quiet -i %input% -codec:a libmp3lame -qscale:a 2 %output%.mp3 | ruby ./bin/mafido.rb -e flac -j 4 --path ~/music --remove
```

## License

MIT — see [LICENSE](./LICENSE)

