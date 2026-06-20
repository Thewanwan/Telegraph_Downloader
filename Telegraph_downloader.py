import os
import re
import json
import time
import customtkinter as ctk
from tkinter import messagebox, filedialog
from threading import Thread, Event
from concurrent.futures import ThreadPoolExecutor, as_completed
from urllib.parse import urlparse
from dataclasses import dataclass, field
from typing import List, Optional, Callable, Dict
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from bs4 import BeautifulSoup
from PIL import Image
from io import BytesIO
from datetime import datetime

VERSION = "v1.0"
BASE_URL = "https://telegra.ph"
CONFIG_DIR = os.path.join(os.path.expanduser("~"), ".telegraph_downloader")
CONFIG_FILE = os.path.join(CONFIG_DIR, "config.json")
HISTORY_FILE = os.path.join(CONFIG_DIR, "history.json")

ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")

PLACEHOLDER_URLS = "在此输入链接...\n多个链接请换行分隔"

FONT_FAMILY = "Microsoft YaHei" if os.name == "nt" else "Noto Sans CJK SC"


def _notify_sound():
    try:
        if os.name == "nt":
            import winsound
            winsound.MessageBeep(winsound.MB_ICONASTERISK)
        else:
            print("\a", end="", flush=True)
    except Exception:
        pass


def _format_time(seconds: float) -> str:
    if seconds < 60:
        return f"{seconds:.0f}秒"
    m, s = divmod(int(seconds), 60)
    if m < 60:
        return f"{m}分{s}秒"
    h, m = divmod(m, 60)
    return f"{h}时{m}分{s}秒"


def _format_size(size_bytes: int) -> str:
    if size_bytes < 1024:
        return f"{size_bytes}B"
    elif size_bytes < 1024 * 1024:
        return f"{size_bytes / 1024:.1f}KB"
    else:
        return f"{size_bytes / (1024 * 1024):.1f}MB"


class AppConfig:
    def __init__(self):
        os.makedirs(CONFIG_DIR, exist_ok=True)
        self.data = self._load()
        self.history = self._load_history()

    def _load(self) -> dict:
        defaults = {
            "save_path": os.path.join(os.path.expanduser("~"), "Downloads"),
            "max_workers": 8,
            "timeout": 15,
            "save_format": "保持原样",
            "quality": 95,
            "theme": "dark",
            "window_geometry": "1000x750",
        }
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                saved = json.load(f)
                defaults.update(saved)
        except Exception:
            pass
        return defaults

    def _load_history(self) -> list:
        try:
            with open(HISTORY_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return []

    def save(self):
        try:
            with open(CONFIG_FILE, "w", encoding="utf-8") as f:
                json.dump(self.data, f, ensure_ascii=False, indent=2)
        except Exception:
            pass

    def save_history(self):
        try:
            with open(HISTORY_FILE, "w", encoding="utf-8") as f:
                json.dump(self.history[-100:], f, ensure_ascii=False, indent=2)
        except Exception:
            pass

    def add_history(self, entry: dict):
        self.history.append(entry)
        self.save_history()

    def get(self, key: str, default=None):
        return self.data.get(key, default)

    def set(self, key: str, value):
        self.data[key] = value
        self.save()


@dataclass
class DownloadConfig:
    max_workers: int = 8
    request_timeout: int = 15
    download_timeout: int = 30
    max_retries: int = 3
    retry_backoff: float = 0.5
    chunk_size: int = 8192
    user_agent: str = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    save_format: str = "original"
    image_quality: int = 95


@dataclass
class AlbumProgress:
    title: str = ""
    total_images: int = 0
    downloaded: int = 0
    failed: int = 0
    status: str = "等待中"


@dataclass
class DownloadResult:
    success: int = 0
    failed: int = 0
    skipped: int = 0
    total_images: int = 0
    elapsed: float = 0.0
    total_bytes: int = 0


class NetworkClient:
    def __init__(self, config: DownloadConfig):
        self.config = config
        self.session = self._create_session()

    def _create_session(self) -> requests.Session:
        session = requests.Session()
        retry = Retry(total=self.config.max_retries, backoff_factor=self.config.retry_backoff,
                      status_forcelist=[429, 500, 502, 503, 504])
        adapter = HTTPAdapter(max_retries=retry, pool_maxsize=self.config.max_workers)
        session.mount("https://", adapter)
        session.mount("http://", adapter)
        session.headers.update({"User-Agent": self.config.user_agent})
        return session

    def fetch_page(self, url: str) -> str:
        resp = self.session.get(url, timeout=self.config.request_timeout)
        resp.raise_for_status()
        return resp.text

    def download_image(self, url: str, save_path: str, save_format: str = "original", quality: int = 95) -> int:
        resp = self.session.get(url, timeout=self.config.download_timeout, stream=True)
        resp.raise_for_status()

        if save_format == "original":
            total = 0
            with open(save_path, "wb") as f:
                for chunk in resp.iter_content(self.config.chunk_size):
                    f.write(chunk)
                    total += len(chunk)
            return total

        img_data = resp.content
        try:
            img = Image.open(BytesIO(img_data))
            if img.mode == "RGBA" and save_format.upper() in ("JPG", "JPEG"):
                img = img.convert("RGB")

            base, _ = os.path.splitext(save_path)
            ext_map = {"JPG": ".jpg", "JPEG": ".jpg", "PNG": ".png", "WEBP": ".webp", "BMP": ".bmp"}
            new_path = base + ext_map.get(save_format.upper(), ".png")

            save_kwargs = {}
            if save_format.upper() in ("JPG", "JPEG"):
                save_kwargs["quality"] = quality
                save_kwargs["optimize"] = True
            elif save_format.upper() == "WEBP":
                save_kwargs["quality"] = quality

            img.save(new_path, **save_kwargs)
            return len(img_data)
        except Exception:
            with open(save_path, "wb") as f:
                f.write(img_data)
            return len(img_data)

    def close(self):
        self.session.close()


class PageParser:
    @staticmethod
    def extract_title(html: str, fallback: str = "untitled") -> str:
        soup = BeautifulSoup(html, "html.parser")
        h1 = soup.find("h1")
        title = h1.get_text(strip=True) if h1 else fallback
        title = re.sub(r'[<>:"/\\|?*]', "", title).strip()
        return title or fallback

    @staticmethod
    def extract_image_urls(html: str) -> List[str]:
        soup = BeautifulSoup(html, "html.parser")
        urls = []
        for img in soup.find_all("img"):
            src = img.get("src", "")
            if src:
                full_url = BASE_URL + src if src.startswith("/") else src
                urls.append(full_url)
        return urls


class DownloadManager:
    def __init__(self, config: DownloadConfig, on_log: Callable, on_progress: Callable,
                 on_album_start: Callable = None, on_album_done: Callable = None):
        self.config = config
        self.client = NetworkClient(config)
        self.parser = PageParser()
        self.on_log = on_log
        self.on_progress = on_progress
        self.on_album_start = on_album_start or (lambda *a: None)
        self.on_album_done = on_album_done or (lambda *a: None)
        self._cancel_event = Event()

    def cancel(self):
        self._cancel_event.set()

    def is_cancelled(self) -> bool:
        return self._cancel_event.is_set()

    def download_all(self, urls: List[str], base_path: str) -> DownloadResult:
        self._cancel_event.clear()
        result = DownloadResult()
        start = time.time()
        total = len(urls)

        for i, url in enumerate(urls, 1):
            if self.is_cancelled():
                self.on_log("已取消下载")
                break

            self.on_progress(i, total, "")
            self.on_log(f"[{i}/{total}] 正在解析: {url[:80]}")

            try:
                html = self.client.fetch_page(url)
                title = self.parser.extract_title(html, f"未命名_{i}")
                folder = os.path.join(base_path, title)
                os.makedirs(folder, exist_ok=True)

                img_urls = self.parser.extract_image_urls(html)
                if not img_urls:
                    self.on_log(f"  ⚠ 未找到图片: {title}")
                    result.skipped += 1
                    continue

                self.on_log(f"  📁 {title} ({len(img_urls)} 张图片)")
                album = AlbumProgress(title=title, total_images=len(img_urls), status="下载中")
                self.on_album_start(album)

                downloaded, failed, total_bytes = self._download_images(img_urls, folder, album)
                result.success += 1
                result.total_images += downloaded
                result.total_bytes += total_bytes

                album.downloaded = downloaded
                album.failed = failed
                album.status = "完成" if failed == 0 else f"部分失败({failed})"
                self.on_album_done(album)

            except requests.exceptions.RequestException as e:
                self.on_log(f"  ❌ 网络错误: {e}")
                result.failed += 1
            except Exception as e:
                self.on_log(f"  ❌ 错误: {e}")
                result.failed += 1

        result.elapsed = time.time() - start
        return result

    def _download_images(self, urls: List[str], folder: str, album: AlbumProgress):
        seen_names = {}
        total = len(urls)
        downloaded = 0
        failed = 0
        total_bytes = 0

        def unique_path(idx: int, url: str) -> str:
            name = os.path.basename(urlparse(url).path) or f"image_{idx}.jpg"
            if name in seen_names:
                seen_names[name] += 1
                base, ext = os.path.splitext(name)
                name = f"{base}_{seen_names[name]}{ext}"
            else:
                seen_names[name] = 0
            return os.path.join(folder, name)

        with ThreadPoolExecutor(max_workers=self.config.max_workers) as pool:
            futures = {}
            for idx, url in enumerate(urls, 1):
                if self.is_cancelled():
                    break
                path = unique_path(idx, url)
                futures[pool.submit(self._download_one, url, path, idx, total)] = idx

            for future in as_completed(futures):
                try:
                    success, path, size = future.result()
                    if success:
                        downloaded += 1
                        total_bytes += size
                    else:
                        failed += 1
                    album.downloaded = downloaded
                    album.failed = failed
                    self.on_progress(downloaded + failed, total, os.path.basename(path) if path else "")
                except Exception:
                    failed += 1
                    album.failed = failed

        return downloaded, failed, total_bytes

    def _download_one(self, url: str, path: str, current: int, total: int):
        try:
            size = self.client.download_image(url, path, self.config.save_format, self.config.image_quality)
            return True, path, size
        except Exception:
            return False, path, 0

    def close(self):
        self.client.close()


class App(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.app_config = AppConfig()

        self.title(f"Telegraph 图片下载器 {VERSION}")
        self.geometry(self.app_config.get("window_geometry", "1000x750"))
        self.minsize(850, 650)
        self.protocol("WM_DELETE_WINDOW", self._on_close)

        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(0, weight=1)

        self.config = DownloadConfig()
        self.manager: Optional[DownloadManager] = None
        self.is_downloading = False
        self._log_lines: List[str] = []
        self._album_widgets: Dict[str, ctk.CTkFrame] = {}

        self._build_ui()
        self._load_settings()
        self.bind("<Control-v>", self._paste_urls)
        self.bind("<Control-s>", lambda e: self._export_log())
        self.bind("<Control-Return>", lambda e: self._start_download())

        self.after(100, self._apply_theme)

    def _apply_theme(self):
        theme = self.app_config.get("theme", "dark")
        ctk.set_appearance_mode(theme)
        if hasattr(self, "theme_switch"):
            self.theme_switch.select() if theme == "dark" else self.theme_switch.deselect()

    def _build_ui(self):
        main = ctk.CTkFrame(self, fg_color="transparent")
        main.grid(row=0, column=0, padx=16, pady=16, sticky="nsew")
        main.grid_columnconfigure(0, weight=1)
        main.grid_rowconfigure(2, weight=1)
        main.grid_rowconfigure(3, weight=1)

        self._build_header(main)
        self._build_input_card(main)
        self._build_progress_card(main)
        self._build_log_card(main)
        self._build_footer(main)

    def _build_header(self, parent):
        header = ctk.CTkFrame(parent, fg_color="transparent")
        header.grid(row=0, column=0, sticky="ew", pady=(0, 12))
        header.grid_columnconfigure(1, weight=1)

        left = ctk.CTkFrame(header, fg_color="transparent")
        left.pack(side="left")
        ctk.CTkLabel(left, text="Telegraph 图片下载器",
                     font=ctk.CTkFont(family=FONT_FAMILY, size=22, weight="bold")).pack(side="left")
        ctk.CTkLabel(left, text=VERSION, font=ctk.CTkFont(size=12),
                     text_color="gray60").pack(side="left", padx=(8, 0), pady=(6, 0))

        right = ctk.CTkFrame(header, fg_color="transparent")
        right.pack(side="right")

        self.theme_switch = ctk.CTkSwitch(right, text="深色模式", command=self._toggle_theme,
                                          onvalue=True, offvalue=False, font=ctk.CTkFont(family=FONT_FAMILY, size=12))
        self.theme_switch.pack(side="left", padx=(0, 8))
        self.theme_switch.select()

        ctk.CTkButton(right, text="历史记录", width=80, height=32, font=ctk.CTkFont(family=FONT_FAMILY, size=12),
                      command=self._show_history, fg_color="gray40",
                      hover_color="gray50").pack(side="left")

    def _build_input_card(self, parent):
        card = ctk.CTkFrame(parent, corner_radius=12)
        card.grid(row=1, column=0, sticky="ew", pady=(0, 10))
        card.grid_columnconfigure(0, weight=3)
        card.grid_columnconfigure(1, weight=2)
        card.grid_rowconfigure(1, weight=1)

        ctk.CTkLabel(card, text="📥 下载配置", font=ctk.CTkFont(family=FONT_FAMILY, size=15, weight="bold"),
                     anchor="w").grid(row=0, column=0, columnspan=2, padx=16, pady=(12, 8), sticky="w")

        left = ctk.CTkFrame(card, fg_color="transparent")
        left.grid(row=1, column=0, padx=(16, 8), pady=(0, 12), sticky="nsew")
        left.grid_rowconfigure(1, weight=1)
        left.grid_columnconfigure(0, weight=1)

        ctk.CTkLabel(left, text="链接列表 (每行一个)", font=ctk.CTkFont(family=FONT_FAMILY, size=12, weight="bold"),
                     anchor="w").grid(row=0, column=0, sticky="w", pady=(0, 4))

        self.url_text = ctk.CTkTextbox(left, font=ctk.CTkFont(family="Consolas", size=12), corner_radius=8)
        self.url_text.grid(row=1, column=0, sticky="nsew")
        self.url_text.insert("1.0", PLACEHOLDER_URLS)
        self.url_text.configure(text_color="gray60")
        self.url_text.bind("<FocusIn>", self._clear_url_placeholder)
        self.url_text.bind("<FocusOut>", self._restore_url_placeholder)
        self.url_text.bind("<KeyRelease>", self._on_url_change)

        right = ctk.CTkFrame(card, fg_color="transparent")
        right.grid(row=1, column=1, padx=(8, 16), pady=(0, 12), sticky="nsew")
        right.grid_rowconfigure(3, weight=1)
        right.grid_columnconfigure(0, weight=1)

        path_card = ctk.CTkFrame(right, fg_color=("gray92", "gray20"), corner_radius=8)
        path_card.grid(row=0, column=0, sticky="ew", pady=(0, 8))
        path_card.grid_columnconfigure(0, weight=1)

        ctk.CTkLabel(path_card, text="保存路径", font=ctk.CTkFont(family=FONT_FAMILY, size=12, weight="bold"),
                     anchor="w").grid(row=0, column=0, padx=12, pady=(8, 4), sticky="w")

        path_row = ctk.CTkFrame(path_card, fg_color="transparent")
        path_row.grid(row=1, column=0, padx=12, pady=(0, 10), sticky="ew")
        path_row.grid_columnconfigure(0, weight=1)

        self.path_text = ctk.CTkEntry(path_row, font=ctk.CTkFont(family=FONT_FAMILY, size=12), corner_radius=6)
        self.path_text.grid(row=0, column=0, sticky="ew", padx=(0, 6))
        self.path_text.insert(0, self.app_config.get("save_path", ""))
        self.path_text.bind("<FocusIn>", self._clear_path_placeholder)
        self.path_text.bind("<FocusOut>", self._restore_path_placeholder)

        ctk.CTkButton(path_row, text="浏览", width=60, height=32, font=ctk.CTkFont(family=FONT_FAMILY, size=12),
                      command=self._browse_folder).grid(row=0, column=1)

        settings_card = ctk.CTkFrame(right, fg_color=("gray92", "gray20"), corner_radius=8)
        settings_card.grid(row=1, column=0, sticky="ew", pady=(0, 8))
        settings_card.grid_columnconfigure((0, 2), weight=1)
        settings_card.grid_columnconfigure((1, 3), weight=1)

        row_s = 0
        ctk.CTkLabel(settings_card, text="线程数", font=ctk.CTkFont(family=FONT_FAMILY, size=11),
                     anchor="w").grid(row=row_s, column=0, padx=(12, 4), pady=(10, 2), sticky="w")
        self.workers_var = ctk.StringVar(value=str(self.app_config.get("max_workers", 8)))
        ctk.CTkOptionMenu(settings_card, values=["2", "4", "8", "12", "16", "20"],
                          variable=self.workers_var, width=80, font=ctk.CTkFont(family=FONT_FAMILY, size=12),
                          corner_radius=6).grid(row=row_s + 1, column=0, padx=(12, 4), pady=(0, 10), sticky="w")

        ctk.CTkLabel(settings_card, text="超时(秒)", font=ctk.CTkFont(family=FONT_FAMILY, size=11),
                     anchor="w").grid(row=row_s, column=1, padx=(4, 12), pady=(10, 2), sticky="w")
        self.timeout_var = ctk.StringVar(value=str(self.app_config.get("timeout", 15)))
        ctk.CTkOptionMenu(settings_card, values=["5", "10", "15", "30", "60"],
                          variable=self.timeout_var, width=80, font=ctk.CTkFont(family=FONT_FAMILY, size=12),
                          corner_radius=6).grid(row=row_s + 1, column=1, padx=(4, 12), pady=(0, 10), sticky="w")

        ctk.CTkLabel(settings_card, text="保存格式", font=ctk.CTkFont(family=FONT_FAMILY, size=11),
                     anchor="w").grid(row=row_s + 2, column=0, padx=(12, 4), pady=(2, 2), sticky="w")
        self.format_var = ctk.StringVar(value=self.app_config.get("save_format", "保持原样"))
        ctk.CTkOptionMenu(settings_card, values=["保持原样", "JPG", "PNG", "WebP", "BMP"],
                          variable=self.format_var, width=100, font=ctk.CTkFont(family=FONT_FAMILY, size=12),
                          corner_radius=6, command=self._on_format_change
                          ).grid(row=row_s + 3, column=0, padx=(12, 4), pady=(0, 10), sticky="w")

        ctk.CTkLabel(settings_card, text="质量", font=ctk.CTkFont(family=FONT_FAMILY, size=11),
                     anchor="w").grid(row=row_s + 2, column=1, padx=(4, 12), pady=(2, 2), sticky="w")
        self.quality_var = ctk.StringVar(value=str(self.app_config.get("quality", 95)))
        self.quality_menu = ctk.CTkOptionMenu(settings_card, values=["60", "70", "80", "85", "90", "95", "100"],
                                              variable=self.quality_var, width=80,
                                              font=ctk.CTkFont(family=FONT_FAMILY, size=12), corner_radius=6)
        self.quality_menu.grid(row=row_s + 3, column=1, padx=(4, 12), pady=(0, 10), sticky="w")
        self._on_format_change(self.format_var.get())

        url_count_card = ctk.CTkFrame(right, fg_color=("gray92", "gray20"), corner_radius=8)
        url_count_card.grid(row=2, column=0, sticky="ew", pady=(0, 8))

        self.url_count_label = ctk.CTkLabel(url_count_card, text="0 个链接",
                                            font=ctk.CTkFont(family=FONT_FAMILY, size=12),
                                            text_color="gray60")
        self.url_count_label.pack(padx=12, pady=8, anchor="w")

    def _build_progress_card(self, parent):
        card = ctk.CTkFrame(parent, corner_radius=12)
        card.grid(row=2, column=0, sticky="ew", pady=(0, 10))
        card.grid_columnconfigure(0, weight=1)

        ctk.CTkLabel(card, text="📊 下载进度", font=ctk.CTkFont(family=FONT_FAMILY, size=15, weight="bold"),
                     anchor="w").grid(row=0, column=0, padx=16, pady=(12, 8), sticky="w")

        stats_row = ctk.CTkFrame(card, fg_color="transparent")
        stats_row.grid(row=1, column=0, padx=16, sticky="ew")

        self.stat_albums = ctk.CTkLabel(stats_row, text="相册: 0/0",
                                        font=ctk.CTkFont(family=FONT_FAMILY, size=12), text_color="gray60")
        self.stat_albums.pack(side="left", padx=(0, 20))

        self.stat_images = ctk.CTkLabel(stats_row, text="图片: 0",
                                        font=ctk.CTkFont(family=FONT_FAMILY, size=12), text_color="gray60")
        self.stat_images.pack(side="left", padx=(0, 20))

        self.stat_size = ctk.CTkLabel(stats_row, text="大小: 0B",
                                      font=ctk.CTkFont(family=FONT_FAMILY, size=12), text_color="gray60")
        self.stat_size.pack(side="left", padx=(0, 20))

        self.stat_time = ctk.CTkLabel(stats_row, text="耗时: 0秒",
                                      font=ctk.CTkFont(family=FONT_FAMILY, size=12), text_color="gray60")
        self.stat_time.pack(side="left")

        progress_frame = ctk.CTkFrame(card, fg_color="transparent")
        progress_frame.grid(row=2, column=0, padx=16, pady=(8, 4), sticky="ew")
        progress_frame.grid_columnconfigure(0, weight=1)

        self.progress_bar = ctk.CTkProgressBar(progress_frame, height=20, corner_radius=10)
        self.progress_bar.grid(row=0, column=0, sticky="ew", padx=(0, 12))
        self.progress_bar.set(0)

        self.progress_label = ctk.CTkLabel(progress_frame, text="0%", font=ctk.CTkFont(size=11),
                                           text_color="gray60", width=50)
        self.progress_label.grid(row=0, column=1)

        self.current_label = ctk.CTkLabel(card, text="就绪", font=ctk.CTkFont(family=FONT_FAMILY, size=11),
                                          text_color="gray60", anchor="w")
        self.current_label.grid(row=3, column=0, padx=16, pady=(2, 8), sticky="w")

    def _build_log_card(self, parent):
        card = ctk.CTkFrame(parent, corner_radius=12)
        card.grid(row=3, column=0, sticky="nsew", pady=(0, 10))
        card.grid_columnconfigure(0, weight=1)
        card.grid_rowconfigure(1, weight=1)

        header = ctk.CTkFrame(card, fg_color="transparent")
        header.grid(row=0, column=0, sticky="ew", padx=16, pady=(12, 4))
        header.grid_columnconfigure(0, weight=1)

        ctk.CTkLabel(header, text="📝 运行日志", font=ctk.CTkFont(family=FONT_FAMILY, size=15, weight="bold"),
                     anchor="w").grid(row=0, column=0, sticky="w")

        btn_row = ctk.CTkFrame(header, fg_color="transparent")
        btn_row.grid(row=0, column=1, sticky="e")

        ctk.CTkButton(btn_row, text="导出", width=60, height=28, font=ctk.CTkFont(family=FONT_FAMILY, size=11),
                      fg_color="gray40", hover_color="gray50",
                      command=self._export_log).pack(side="left", padx=(0, 4))
        ctk.CTkButton(btn_row, text="清空", width=60, height=28, font=ctk.CTkFont(family=FONT_FAMILY, size=11),
                      fg_color="gray40", hover_color="gray50",
                      command=self._clear_log).pack(side="left")

        self.log_text = ctk.CTkTextbox(card, font=ctk.CTkFont(family="Consolas", size=12),
                                       state="disabled", corner_radius=8)
        self.log_text.grid(row=1, column=0, padx=12, pady=(4, 12), sticky="nsew")
        self._log(f"Telegraph 图片下载器 {VERSION} 就绪。")

    def _build_footer(self, parent):
        footer = ctk.CTkFrame(parent, fg_color="transparent")
        footer.grid(row=4, column=0, sticky="ew")
        footer.grid_columnconfigure(0, weight=1)

        self.run_button = ctk.CTkButton(footer, text="▶ 开始下载", command=self._start_download,
                                        font=ctk.CTkFont(family=FONT_FAMILY, size=16, weight="bold"),
                                        height=44, width=160, corner_radius=10,
                                        fg_color="#2563eb", hover_color="#1d4ed8")
        self.run_button.pack(side="right")

        self.cancel_button = ctk.CTkButton(footer, text="■ 停止", command=self._cancel_download,
                                           font=ctk.CTkFont(family=FONT_FAMILY, size=14),
                                           height=44, width=100, corner_radius=10,
                                           fg_color="#dc2626", hover_color="#b91c1c",
                                           state="disabled")
        self.cancel_button.pack(side="right", padx=(0, 10))

    def _toggle_theme(self):
        mode = "light" if ctk.get_appearance_mode() == "Dark" else "dark"
        ctk.set_appearance_mode(mode)
        self.app_config.set("theme", mode)

    def _on_format_change(self, format_name):
        if format_name == "保持原样":
            self.quality_menu.configure(state="disabled")
        else:
            self.quality_menu.configure(state="normal")

    def _on_url_change(self, _):
        urls = self._get_urls()
        count = len(urls)
        self.url_count_label.configure(text=f"{count} 个链接" + (" ✓" if count > 0 else ""),
                                       text_color="#22c55e" if count > 0 else "gray60")

    def _cancel_download(self):
        if self.manager and self.is_downloading:
            self.manager.cancel()

    def _clear_log(self):
        self._log_lines.clear()
        self.log_text.configure(state="normal")
        self.log_text.delete("1.0", "end")
        self.log_text.configure(state="disabled")

    def _export_log(self):
        path = filedialog.asksaveasfilename(
            defaultextension=".txt",
            filetypes=[("文本文件", "*.txt"), ("所有文件", "*.*")],
            initialfile=f"log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
        )
        if path:
            try:
                with open(path, "w", encoding="utf-8") as f:
                    f.write("\n".join(self._log_lines))
                self._log(f"日志已导出: {path}")
            except Exception as e:
                self._log(f"导出失败: {e}")

    def _browse_folder(self):
        path = filedialog.askdirectory()
        if path:
            self.path_text.delete(0, "end")
            self.path_text.insert(0, path)
            self.app_config.set("save_path", path)

    def _clear_url_placeholder(self, _):
        if self.url_text.get("1.0", "end-1c").strip() == PLACEHOLDER_URLS:
            self.url_text.delete("1.0", "end")
            self.url_text.configure(text_color=("black", "white"))

    def _restore_url_placeholder(self, _):
        if not self.url_text.get("1.0", "end-1c").strip():
            self.url_text.insert("1.0", PLACEHOLDER_URLS)
            self.url_text.configure(text_color="gray60")

    def _clear_path_placeholder(self, _):
        pass

    def _restore_path_placeholder(self, _):
        pass

    def _paste_urls(self, _):
        try:
            clip = self.clipboard_get()
            if clip:
                existing = self.url_text.get("1.0", "end-1c").strip()
                if existing == PLACEHOLDER_URLS or not existing:
                    self.url_text.delete("1.0", "end")
                    self.url_text.insert("1.0", clip)
                else:
                    self.url_text.insert("end", "\n" + clip)
                self.url_text.configure(text_color=("black", "white"))
                self._on_url_change(None)
        except Exception:
            pass

    def _log(self, msg: str):
        self.after(0, self._log_impl, msg)

    def _log_impl(self, msg: str):
        ts = datetime.now().strftime("%H:%M:%S")
        line = f"[{ts}] {msg}"
        self._log_lines.append(line)
        self.log_text.configure(state="normal")
        self.log_text.insert("end", f"{line}\n")
        self.log_text.see("end")
        self.log_text.configure(state="disabled")

    def _update_progress(self, current: int, total: int, item_name: str = ""):
        self.after(0, self._update_progress_impl, current, total, item_name)

    def _update_progress_impl(self, current: int, total: int, item_name: str):
        if total > 0:
            pct = current / total
            self.progress_bar.set(pct)
            self.progress_label.configure(text=f"{pct:.0%}")
        if item_name:
            self.current_label.configure(text=f"正在处理: {item_name}")
        self.stat_albums.configure(text=f"相册: {current}/{total}")

    def _on_album_start(self, album: AlbumProgress):
        self.after(0, self._on_album_start_impl, album)

    def _on_album_start_impl(self, album: AlbumProgress):
        self._log(f"  开始下载: {album.title} ({album.total_images} 张)")

    def _on_album_done(self, album: AlbumProgress):
        self.after(0, self._on_album_done_impl, album)

    def _on_album_done_impl(self, album: AlbumProgress):
        status = "✓" if album.failed == 0 else f"⚠ {album.failed}张失败"
        self._log(f"  完成: {album.title} [{album.downloaded}/{album.total_images}] {status}")

    def _get_urls(self) -> List[str]:
        raw = self.url_text.get("1.0", "end-1c").strip()
        if not raw or raw == PLACEHOLDER_URLS:
            return []
        lines = [l.strip() for l in raw.splitlines() if l.strip()]
        valid = []
        for url in lines:
            p = urlparse(url)
            if p.scheme and p.netloc:
                valid.append(url)
        return valid

    def _get_save_path(self) -> Optional[str]:
        path = self.path_text.get().strip()
        if not path:
            return None
        if not os.path.isdir(path):
            try:
                os.makedirs(path, exist_ok=True)
            except Exception:
                return None
        return path if path.endswith(("/", "\\")) or os.name == "nt" else path + "/"

    def _load_settings(self):
        self.app_config.save()

    def _save_all_settings(self):
        self.app_config.set("save_path", self.path_text.get().strip())
        self.app_config.set("max_workers", int(self.workers_var.get()))
        self.app_config.set("timeout", int(self.timeout_var.get()))
        self.app_config.set("save_format", self.format_var.get())
        self.app_config.set("quality", int(self.quality_var.get()))
        self.app_config.set("window_geometry", self.geometry())
        self.app_config.save()

    def _start_download(self):
        if self.is_downloading:
            return

        urls = self._get_urls()
        save_path = self._get_save_path()

        if not urls:
            messagebox.showwarning("输入错误", "请至少输入一个有效链接。")
            return
        if not save_path:
            messagebox.showwarning("输入错误", "请选择一个有效的保存文件夹。")
            return

        self._save_all_settings()

        format_map = {"保持原样": "original", "JPG": "JPG", "PNG": "PNG", "WebP": "WEBP", "BMP": "BMP"}
        self.config.max_workers = int(self.workers_var.get())
        self.config.request_timeout = int(self.timeout_var.get())
        self.config.save_format = format_map.get(self.format_var.get(), "original")
        self.config.image_quality = int(self.quality_var.get())

        self.is_downloading = True
        self.run_button.configure(state="disabled", text="下载中...")
        self.cancel_button.configure(state="normal")

        self.progress_bar.set(0)
        self.progress_label.configure(text="0%")
        self.stat_albums.configure(text=f"相册: 0/{len(urls)}")
        self.stat_images.configure(text="图片: 0")
        self.stat_size.configure(text="大小: 0B")
        self.stat_time.configure(text="耗时: 0秒")
        self.current_label.configure(text="准备开始...")

        self._log(f"开始下载 {len(urls)} 个链接, {self.config.max_workers} 线程")

        Thread(target=self._run_download, args=(urls, save_path), daemon=True).start()

    def _run_download(self, urls: List[str], save_path: str):
        start_time = time.time()
        self.manager = DownloadManager(
            self.config,
            self._log,
            self._update_progress,
            self._on_album_start,
            self._on_album_done
        )
        try:
            result = self.manager.download_all(urls, save_path)

            elapsed = result.elapsed
            self._update_progress(len(urls), len(urls))
            self.current_label.configure(text="下载完成")

            self.stat_albums.configure(text=f"相册: {result.success}/{len(urls)}")
            self.stat_images.configure(text=f"图片: {result.total_images}")
            self.stat_size.configure(text=f"大小: {_format_size(result.total_bytes)}")
            self.stat_time.configure(text=f"耗时: {_format_time(elapsed)}")

            summary = (
                f"下载完成!\n"
                f"  成功: {result.success} 个相册\n"
                f"  失败: {result.failed} 个\n"
                f"  跳过: {result.skipped} 个\n"
                f"  图片: {result.total_images} 张\n"
                f"  大小: {_format_size(result.total_bytes)}\n"
                f"  耗时: {_format_time(elapsed)}"
            )
            self._log(f"\n{'=' * 40}\n{summary}\n{'=' * 40}")

            self.app_config.add_history({
                "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "urls": urls,
                "path": save_path,
                "success": result.success,
                "failed": result.failed,
                "images": result.total_images,
                "size": result.total_bytes,
                "elapsed": elapsed,
            })

            _notify_sound()

        finally:
            self.manager.close()
            self.after(0, self._on_download_done)

    def _on_download_done(self):
        self.is_downloading = False
        self.run_button.configure(state="normal", text="▶ 开始下载")
        self.cancel_button.configure(state="disabled")

    def _show_history(self):
        dialog = ctk.CTkToplevel(self)
        dialog.title("下载历史")
        dialog.geometry("600x500")
        dialog.transient(self)
        dialog.grab_set()

        ctk.CTkLabel(dialog, text="下载历史", font=ctk.CTkFont(family=FONT_FAMILY, size=18, weight="bold")
                     ).pack(padx=20, pady=(16, 8), anchor="w")

        scroll = ctk.CTkScrollableFrame(dialog, corner_radius=8)
        scroll.pack(fill="both", expand=True, padx=20, pady=(0, 16))

        history = list(reversed(self.app_config.history))
        if not history:
            ctk.CTkLabel(scroll, text="暂无历史记录", text_color="gray60",
                         font=ctk.CTkFont(family=FONT_FAMILY, size=13)).pack(pady=40)
            return

        for entry in history:
            item = ctk.CTkFrame(scroll, corner_radius=8, fg_color=("gray92", "gray20"))
            item.pack(fill="x", pady=4)

            ctk.CTkLabel(item, text=entry.get("time", ""),
                         font=ctk.CTkFont(family=FONT_FAMILY, size=11),
                         text_color="gray60").pack(anchor="w", padx=12, pady=(8, 2))

            info = f"相册: {entry.get('success', 0)} | 图片: {entry.get('images', 0)} | 大小: {_format_size(entry.get('size', 0))} | 耗时: {_format_time(entry.get('elapsed', 0))}"
            ctk.CTkLabel(item, text=info, font=ctk.CTkFont(family=FONT_FAMILY, size=12),
                         anchor="w").pack(anchor="w", padx=12)

            path_text = entry.get("path", "")
            if path_text:
                ctk.CTkLabel(item, text=f"📁 {path_text}", font=ctk.CTkFont(family=FONT_FAMILY, size=10),
                             text_color="gray60", anchor="w").pack(anchor="w", padx=12, pady=(0, 8))

        ctk.CTkButton(dialog, text="关闭", command=dialog.destroy, width=80).pack(pady=(0, 16))

    def _on_close(self):
        self._save_all_settings()
        if self.is_downloading:
            if not messagebox.askyesno("退出", "下载正在进行中，确定要退出吗？"):
                return
            if self.manager:
                self.manager.cancel()
        self.destroy()


if __name__ == "__main__":
    App().mainloop()
