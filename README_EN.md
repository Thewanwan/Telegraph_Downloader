# Telegraph Image Downloader

A desktop tool built with Tkinter (customtkinter) that uses multithreading to batch download image albums published on `telegra.ph`.

![](images.png)

## Features

- **Multithreaded batch download** — Download multiple links simultaneously, configurable thread count (2~20)
- **Format conversion** — Export as original format, JPG, PNG, WebP, or BMP
- **Dark/Light theme** — One-click toggle with auto-remembered preference
- **Download history** — Automatically saves the last 100 download records
- **Real-time progress** — View download status and progress for each album
- **Keyboard shortcuts** — `Ctrl+V` paste links, `Ctrl+Enter` start download, `Ctrl+S` export log
- **Auto retry** — Built-in retry mechanism for unstable networks
- **Persistent config** — All settings auto-saved and restored on next launch

## Usage

### Requirements

- Python 3.8+

### Install dependencies

```bash
pip install -r requirements.txt
```

### Launch

```bash
python Telegraph_downloader.py
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+V` | Paste links into input field |
| `Ctrl+Enter` | Start download |
| `Ctrl+S` | Export log |

## Network Notes

`telegra.ph` requires a proxy to access in certain regions.

- **macOS**: Enable global proxy
- **Windows**: System global proxy may not work; use tools like `natapp` for traffic forwarding

## Build

See [BUILD.md](BUILD.md) for packaging instructions.

## License

[GNU General Public License v3.0](LICENSE)
