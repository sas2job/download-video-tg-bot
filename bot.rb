#!/usr/bin/env ruby

require 'telegram/bot'
require 'json'
require 'open3'
require 'fileutils'
require 'dotenv/load'
require 'securerandom'

# ================= CONFIG =================

TOKEN = ENV.fetch('TG_BOT_TOKEN')
DOWNLOAD_DIR = ENV.fetch('DOWNLOAD_DIR', './downloads')

FileUtils.mkdir_p(DOWNLOAD_DIR)

# user_id => { url:, formats: [] }
USER_STATE = {}

# ================= HELPERS =================

def extract_url(message)
  return message.text if message.text&.match?(%r{https?://})

  message.entities&.each do |e|
    if e.type == 'url'
      return message.text[e.offset, e.length]
    end
  end

  nil
end

def get_formats(url)
  stdout, stderr, status = Open3.capture3(
    "yt-dlp", "-J", "--no-warnings", url
  )
  raise stderr unless status.success?

  json = JSON.parse(stdout)

  json["formats"]
    .select { |f| f["vcodec"] != "none" && f["height"] }
    .uniq { |f| f["height"] }
    .sort_by { |f| -f["height"] }
    .map do |f|
      {
        id: f["format_id"],
        height: f["height"],
        ext: f["ext"],
        size: f["filesize"] || f["filesize_approx"]
      }
    end
end

def download_video(url, format_id, user_id)
  filename = "#{user_id}_#{SecureRandom.hex(4)}.mp4"
  path = File.join(DOWNLOAD_DIR, filename)

  system(
    "yt-dlp",
    "-f", format_id,
    "--merge-output-format", "mp4",
    "-o", path,
    url
  )

  path
end

def human_size(bytes)
  return "?" unless bytes
  "#{(bytes / 1024 / 1024).round} MB"
end

# ================= BOT =================

Telegram::Bot::Client.run(TOKEN) do |bot|
  puts "🤖 Bot started"

  bot.listen do |update|

    # -------- MESSAGE --------
    if update.is_a?(Telegram::Bot::Types::Message)
      chat_id = update.chat.id
      url = extract_url(update)

      if url&.match?(%r{(youtube\.com|youtu\.be)})
        bot.api.send_message(
          chat_id: chat_id,
          text: "🔍 Получаю доступные качества…"
        )

        begin
          formats = get_formats(url)
          USER_STATE[chat_id] = { url: url, formats: formats }

          buttons = formats.map do |f|
            label = "#{f[:height]}p (#{human_size(f[:size])})"
            Telegram::Bot::Types::InlineKeyboardButton.new(
              text: label,
              callback_data: "fmt:#{f[:id]}"
            )
          end

          keyboard = Telegram::Bot::Types::InlineKeyboardMarkup.new(
            inline_keyboard: buttons.each_slice(2).to_a
          )

          bot.api.send_message(
            chat_id: chat_id,
            text: "Выбери качество:",
            reply_markup: keyboard
          )

        rescue => e
          bot.api.send_message(
            chat_id: chat_id,
            text: "❌ Ошибка:\n#{e.message}"
          )
        end
      else
        bot.api.send_message(
          chat_id: chat_id,
          text: "Пришли ссылку на YouTube / Shorts"
        )
      end
    end

    # -------- CALLBACK --------
    if update.is_a?(Telegram::Bot::Types::CallbackQuery)
      chat_id = update.message.chat.id
      data = update.data

      next unless data.start_with?("fmt:")

      state = USER_STATE[chat_id]
      next unless state

      format_id = data.split(":")[1]

      bot.api.answer_callback_query(
        callback_query_id: update.id,
        text: "⬇️ Скачиваю…"
      )

      file = download_video(state[:url], format_id, chat_id)

      bot.api.send_video(
        chat_id: chat_id,
        video: Faraday::UploadIO.new(file, "video/mp4")
      )

      File.delete(file) if File.exist?(file)
      USER_STATE.delete(chat_id)
    end
  end
end
