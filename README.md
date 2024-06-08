# [Sticky, The Converter Telegram Bot](https://t.me/StickyConverterBot) 🫠 - Convert enote links from 7TV to Sticker type files in Telegram easily 

Sticky is a Telegram bot that converts 7TV emotes into sticker-ready formats based on Telegram standards. Send a 7TV emote link to the bot, and it will provide you with a downloadable sticker file.

## 🌟 Features

- Convert static 7TV emotes to PNG.
- Convert animated 7TV emotes to WEBM.
- Automatically resizes to 512 pixels on the larger side of the source file.
- Ensures animated stickers are within 3 seconds.

## ⚙️ Setup and Installation

### Requirements 

- Python 3.8+ (Tested on 3.10.12)
- [FFmpeg](https://ffmpeg.org/)
- [ImageMagick](https://imagemagick.org/)

### Installation

1. Clone the repository:
    ```sh
    git clone https://github.com/Konrik/StickyConverterBot
    cd StickyConverterBot
    ```

2. Install dependencies:
    ```sh
    pip install -r requirements.txt
    ```

3. Configure your bot:
    - Create a `config.py` file with the following content:
        ```python
        import os

        API_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN', 'PASTE BOT TOKEN HERE')  # Go to @BotFather to get your bot token
        DATABASE = 'users.db'  # You can leave it default
        TMP_DIR = 'tmp'  # You can leave it default
        LOG_FILE = 'bot.log'  # You can leave it default
        ```

4. Ensure FFmpeg and ImageMagick are installed and available in your system's PATH.

### Installation on Windows

1. Download and install [FFmpeg](https://ffmpeg.org/download.html).
2. Download and install [ImageMagick](https://imagemagick.org/script/download.php).

Ensure both `ffmpeg` and `magick` commands are added to your system's PATH.

### Installation on Linux

1. Install FFmpeg:
    ```sh
    sudo apt update
    sudo apt install ffmpeg
    ```

2. Build and install ImageMagick with all necessary dependencies and libraries using the provided script:
    ```sh
    chmod +x build_imagemagick.sh
    ./build_imagemagick.sh
    ```

Ensure both `ffmpeg` and `magick` commands are available in your system's PATH.

### 🚀 Running the Bot

#### Windows:
```bat
python main.py
```

#### Linux:
```sh
python3 main.py
```

## 📖 Usage

1. Start the bot on Telegram by sending `/start`.
2. Send a 7TV emote link to the bot.
3. The bot will process the emote and send back the converted file.
4. Send the message with the file to the official Telegram bot @stickers to upload the future sticker into the sticker pack.

## 📷 Example

**Send a 7TV emote link:**
```
https://7tv.app/emotes/60ae32f9163f5d5d5192fbe5
```

**Bot's response:**
```
## CONVERTED FILE ##
📦 **Emote name:** CoolCat
🆔 **ID:** 60ae32f9163f5d5d5192fbe5
👤 **Owner:** 7TV

To upload this to your stickerpack, use the official @stickers bot by Telegram. (Transfer this message to it)
```

## 📝 Logging

The bot uses Python's built-in logging module. Logs are displayed in the console.

## 🤝 Contributing

1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Commit your changes (`git commit -m 'Add some feature'`).
4. Push to the branch (`git push origin feature-branch`).
5. Open a pull request.

## 📜 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgements

- [aiogram](https://github.com/aiogram/aiogram) - Telegram Bot API framework for Python.
- [FFmpeg](https://ffmpeg.org/) - A complete, cross-platform solution to record, convert, and stream audio and video.
- [ImageMagick](https://imagemagick.org/) - Software suite to create, edit, compose, or convert bitmap images.
- [7TV](https://7tv.app/) - Emote platform for Twitch.

---

*Happy Sticker Making!* 🎨
