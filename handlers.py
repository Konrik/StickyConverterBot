import aiohttp
import logging
from aiogram import types
from aiogram.dispatcher import Dispatcher
from aiogram.types import ParseMode, InputFile
from utils import add_user_to_db, convert_to_webm, convert_to_png, clean_files, clean_directory
import config
import os

logger = logging.getLogger(__name__)

async def send_welcome(message: types.Message):
    await add_user_to_db(message.from_user.id)
    await message.reply("👋 Hello! I'm *Sticky* - The Sticker Converter Bot.🫠 \nSend me a 7TV emote link to get started.", parse_mode=ParseMode.MARKDOWN)

async def handle_emote_link(message: types.Message):
    await message.reply("_Processing..._", parse_mode=ParseMode.MARKDOWN)
    url = message.text
    emote_id = url.split('/')[-1]
    api_url = f"https://7tv.io/v3/emotes/{emote_id}"

    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(api_url) as response:
                if response.status == 200:
                    emote_data = await response.json()
                    await process_emote(emote_data, message)
                else:
                    await message.reply("❌ Failed to fetch emote data. Please check the link and try again.")
    except Exception as e:
        logger.error(f"Error handling emote link: {e}")
        await message.reply("❌ An error occurred while processing your request.")

async def process_emote(emote_data, message: types.Message):
    emote_name = emote_data["name"]
    emote_id = emote_data["id"]
    owner_name = emote_data["owner"]["display_name"]
    is_animated = emote_data["animated"]

    base_url = "https:" + emote_data["host"]["url"]
    file_url = base_url + "/3x.webp"

    tmp_file = f"{config.TMP_DIR}/{emote_id}.webp"
    output_file = f"{config.TMP_DIR}/{emote_id}.png" if not is_animated else f"{config.TMP_DIR}/{emote_id}.webm"

    async with aiohttp.ClientSession() as session:
        async with session.get(file_url) as response:
            if response.status == 200:
                with open(tmp_file, 'wb') as f:
                    f.write(await response.read())
                logger.info(f"Downloaded file to {tmp_file}")
            else:
                await message.reply("❌ Failed to download emote file.")
                return

    if os.path.getsize(tmp_file) == 0:
        logger.error("Downloaded file is empty")
        await message.reply("❌ Downloaded file is empty.")
        return

    if is_animated:
        await convert_to_webm(tmp_file, output_file)
    else:
        await convert_to_png(tmp_file, output_file)

    caption = (f"📦 **Emote name:** {escape_markdown(emote_name)}\n"
               f"🆔 **ID:** {escape_markdown(emote_id)}\n"
               f"👤 **Owner:** {escape_markdown(owner_name)}\n\n"
               "To upload this to your stickerpack, use the official @stickers bot by Telegram. (Transfer this message to it)")

    input_file = InputFile(output_file)
    await message.reply_document(input_file, caption=caption, parse_mode=ParseMode.MARKDOWN)

    clean_files([tmp_file, output_file])

def escape_markdown(text: str) -> str:
    escape_chars = r'\_*[]()~`>#+-=|{}.!'
    return ''.join(f'\\{char}' if char in escape_chars else char for char in text)

def setup_handlers(dp: Dispatcher):
    dp.register_message_handler(send_welcome, commands=['start'])
    dp.register_message_handler(handle_emote_link, regexp=r'https://7tv\.app/emotes/\w+')

if __name__ == "__main__":
    from aiogram import executor
    from config import dp

    setup_handlers(dp)
    executor.start_polling(dp, skip_updates=True)
