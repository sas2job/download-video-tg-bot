# Download Video Telegram Bot

This is a Telegram bot that allows users to download videos from YouTube and Shorts by providing a link. The bot fetches available video qualities and lets users choose the desired quality for download.

## Prerequisites
- Ruby (>= 2.7)
- `yt-dlp` installed on your system.
- A Telegram bot token.

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd download-video-tg-bot
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Install `yt-dlp`:
   ```bash
   sudo apt update && sudo apt install -y yt-dlp
   ```

4. Set up environment variables:
   - Copy `.env.sample` to `.env`:
     ```bash
     cp .env.sample .env
     ```
   - Add your Telegram bot token to the `.env` file:
     ```env
     TG_BOT_TOKEN=your_bot_token_here
     ```

5. Create the downloads directory:
   ```bash
   mkdir -p downloads
   ```

## Usage

Start the bot by running:
```bash
ruby bot.rb
```

The bot will listen for messages and respond to YouTube links.

## File Structure
- `bot.rb`: Main bot logic.
- `Gemfile` and `Gemfile.lock`: Ruby dependencies.
- `.env`: Environment variables (ignored by Git).
- `.env.sample`: Sample environment file.
- `downloads/`: Directory for temporary video storage.

## Notes
- Ensure `yt-dlp` is installed and accessible in your system's PATH.
- The bot automatically deletes downloaded videos after sending them to the user.

## License
This project is licensed under the MIT License.