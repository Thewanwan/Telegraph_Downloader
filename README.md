# Telegraph 图片下载器

一个基于 Tkinter (customtkinter) 的桌面工具，使用多线程技术批量下载 `telegra.ph` 上发布的各种图册。

![](images.png)

## 功能特性

- **多线程批量下载** — 支持多链接同时下载，可自定义线程数 (2~20)
- **格式转换** — 支持保持原样、JPG、PNG、WebP、BMP 格式导出
- **暗色/亮色主题** — 一键切换，自动记忆偏好
- **下载历史** — 自动保存最近 100 条下载记录
- **实时进度** — 显示每个图册的下载状态和进度
- **快捷键** — `Ctrl+V` 粘贴链接、`Ctrl+Enter` 开始下载、`Ctrl+S` 导出日志
- **自动重试** — 内置重试机制，应对网络不稳定
- **配置持久化** — 所有设置自动保存，下次启动自动恢复

## 使用方式

### 环境要求

- Python 3.8+

### 安装依赖

```bash
pip install -r requirements.txt
```

### 启动程序

```bash
python Telegraph_downloader.py
```

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+V` | 粘贴链接到输入框 |
| `Ctrl+Enter` | 开始下载 |
| `Ctrl+S` | 导出日志 |

## 网络说明

国内网络环境复杂，`telegra.ph` 需要代理访问。

- **Mac 平台**：需要开启全局代理
- **Windows 平台**：系统全局代理通常无效，需使用 `natapp` 等流量转发工具

## 打包构建

详见 [BUILD.md](BUILD.md)

## 许可证

[GNU General Public License v3.0](LICENSE)
