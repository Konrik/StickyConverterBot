import aiosqlite
import os
import logging
import config
import subprocess

logger = logging.getLogger(__name__)

async def add_user_to_db(user_id):
    async with aiosqlite.connect(config.DATABASE) as db:
        await db.execute("CREATE TABLE IF NOT EXISTS users (user_id INTEGER PRIMARY KEY)")
        await db.execute("INSERT OR IGNORE INTO users (user_id) VALUES (?)", (user_id,))
        await db.commit()

async def convert_to_png(input_file, output_file):
    command = f"magick {input_file} -resize 512x512 {output_file}"
    result = subprocess.run(command, shell=True)
    if result.returncode == 0:
        logger.info(f"Converted {input_file} to {output_file}")
    else:
        logger.error(f"Failed to convert {input_file} to {output_file}")

async def convert_to_webm(input_file, output_file):
    magick_command = f"magick {input_file} -coalesce -resize 512x512 {output_file}"
    magick_result = subprocess.run(magick_command, shell=True)
    
    if magick_result.returncode == 0:
        logger.info(f"Converted {input_file} to {output_file} with ImageMagick")
        
        output_dir = os.path.dirname(output_file)
        temp_output_file = os.path.join(output_dir, "temp_" + os.path.basename(output_file))
        
        ffmpeg_command = f"ffmpeg -y -i {output_file} -t 3 -c copy {temp_output_file}"
        ffmpeg_result = subprocess.run(ffmpeg_command, shell=True)
        
        if ffmpeg_result.returncode == 0:
            logger.info(f"Cropped {output_file} to 3 seconds with FFmpeg")

            os.replace(temp_output_file, output_file)
        else:
            logger.error(f"Failed to crop {output_file} to 3 seconds with FFmpeg")
            if os.path.exists(temp_output_file):
                os.remove(temp_output_file)
    else:
        logger.error(f"Failed to convert {input_file} to {output_file} with ImageMagick")
        
def clean_files(file_paths):
    for file_path in file_paths:
        try:
            os.remove(file_path)
            logger.info(f"Deleted file {file_path}")
        except Exception as e:
            logger.error(f"Error deleting file {file_path}: {e}")

def clean_directory(directory):
    try:
        for file in os.listdir(directory):
            file_path = os.path.join(directory, file)
            os.remove(file_path)
            logger.info(f"Deleted file {file_path}")
        os.rmdir(directory)
        logger.info(f"Deleted directory {directory}")
    except Exception as e:
        logger.error(f"Error cleaning directory {directory}: {e}")