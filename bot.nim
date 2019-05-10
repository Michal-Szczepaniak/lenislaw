import telebot, asyncdispatch, logging, options, os, strutils, db_sqlite, random

const API_KEY = slurp("secret.key").strip()
const USER_ID = 412515181

let db = open("lenek.db", "", "", "")
let jokes = readFile("jokes.txt").splitLines

proc setupDatabase() =
  db.exec(sql("""CREATE TABLE IF NOT EXISTS commands_files (
              id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
              command varchar(255) NOT NULL,
              file varchar(255) NOT NULL)
            """))
  db.exec(sql("""CREATE TABLE IF NOT EXISTS commands_stickers (
              id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
              command varchar(255) NOT NULL,
              sticker varchar(255) NOT NULL)
            """))
  db.exec(sql("""CREATE TABLE IF NOT EXISTS commands_photos (
              id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
              command varchar(255) NOT NULL,
              photo varchar(255) NOT NULL)
            """))
  db.exec(sql("""CREATE TABLE IF NOT EXISTS commands_voices (
              id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
              command varchar(255) NOT NULL,
              voice varchar(255) NOT NULL)
            """))
  db.exec(sql("""CREATE TABLE IF NOT EXISTS commands_videos (
              id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
              command varchar(255) NOT NULL,
              video varchar(255) NOT NULL)
            """))
  db.exec(sql("""CREATE TABLE IF NOT EXISTS commands_audios (
              id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
              command varchar(255) NOT NULL,
              audio varchar(255) NOT NULL)
            """))
  db.exec(sql("""CREATE TABLE IF NOT EXISTS admins (
              id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
              user_id INTEGER NOT NULL)
            """))

proc setFileCommand(c, f: string) =
  db.exec(sql"INSERT INTO commands_files (command, file) VALUES (?,?)", c, f)
proc getFileByCommand(c: string): string =
  result = db.getValue(sql"SELECT file FROM commands_files WHERE command = ?", c)
proc removeFileCommand(c: string) =
  db.exec(sql"DELETE FROM commands_files WHERE command = ?", c)

proc setStickerCommand(c, s: string) =
  db.exec(sql"INSERT INTO commands_stickers (command, sticker) VALUES (?,?)", c, s)
proc getStickerByCommand(c: string): string =
  result = db.getValue(sql"SELECT sticker FROM commands_stickers WHERE command = ?", c)
proc removeStickerCommand(c: string) =
  db.exec(sql"DELETE FROM commands_stickers WHERE command = ?", c)

proc setPhotoCommand(c, f: string) =
  db.exec(sql"INSERT INTO commands_photos (command, photo) VALUES (?,?)", c, f)
proc getPhotoByCommand(c: string): string =
  result = db.getValue(sql"SELECT photo FROM commands_photos WHERE command = ?", c)
proc removePhotoCommand(c: string) =
  db.exec(sql"DELETE FROM commands_photos WHERE command = ?", c)

proc setVoiceCommand(c, f: string) =
  db.exec(sql"INSERT INTO commands_voices (command, voice) VALUES (?,?)", c, f)
proc getVoiceByCommand(c: string): string =
  result = db.getValue(sql"SELECT voice FROM commands_voices WHERE command = ?", c)
proc removeVoiceCommand(c: string) =
  db.exec(sql"DELETE FROM commands_voices WHERE command = ?", c)

proc setVideoCommand(c, f: string) =
  db.exec(sql"INSERT INTO commands_videos (command, video) VALUES (?,?)", c, f)
proc getVideoByCommand(c: string): string =
  result = db.getValue(sql"SELECT video FROM commands_videos WHERE command = ?", c)
proc removeVideoCommand(c: string) =
  db.exec(sql"DELETE FROM commands_videos WHERE command = ?", c)

proc addAdmin(id:int) =
  db.exec(sql"INSERT INTO admins (user_id) VALUES (?)", id)
proc removeAdmin(id:int) =
  db.exec(sql"DELETE FROM admins WHERE user_id = ?", id)
proc isAdmin(id:int): bool =
  result = db.getValue(sql"SELECT id FROM admins WHERE user_id = ?", id) != ""  

proc commandHandler(bot: Telebot, command: CatchallCommand) {.async.} =
  var commandText = command.command
  var chatId = command.message.chat.id

  if command.message.fromUser.isSome and (command.message.fromUser.get.id == USER_ID or isAdmin(command.message.fromUser.get.id)):
    case commandText:
      of "addCommand":
        if command.message.replyToMessage.isSome and command.params != "":
          if command.message.replyToMessage.get.sticker.isSome:
            if getStickerByCommand(command.params) == "":
              setStickerCommand(command.params, command.message.replyToMessage.get.sticker.get.fileId)
              discard await bot.send(newMessage(chatId, "dodano sticker"))
        
          if command.message.replyToMessage.get.document.isSome:
            if getFileByCommand(command.params) == "":
              setFileCommand(command.params, command.message.replyToMessage.get.document.get.fileId)
              discard await bot.send(newMessage(chatId, "dodano plik"))
        
          if command.message.replyToMessage.get.photo.isSome:
            if getPhotoByCommand(command.params) == "":
              setPhotoCommand(command.params, command.message.replyToMessage.get.photo.get[0].fileId)
              discard await bot.send(newMessage(chatId, "dodano obrazek"))

          if command.message.replyToMessage.get.voice.isSome:
            if getVoiceByCommand(command.params) == "":
              setVoiceCommand(command.params, command.message.replyToMessage.get.voice.get.fileId)
              discard await bot.send(newMessage(chatId, "dodano voice"))

          if command.message.replyToMessage.get.video.isSome:
            if getVideoByCommand(command.params) == "":
              setVideoCommand(command.params, command.message.replyToMessage.get.video.get.fileId)
              discard await bot.send(newMessage(chatId, "dodano video"))
        else:
          discard await bot.send(newMessage(chatId, jokes.sample))

      of "removeFile":
        if command.params != "":
          removeFileCommand(command.params)
        else:
          discard await bot.send(newMessage(chatId, jokes.sample))
      of "removeSticker":
        if command.params != "":
          removeStickerCommand(command.params)
        else:
          discard await bot.send(newMessage(chatId, jokes.sample))
      of "removePhoto":
        if command.params != "":
          removePhotoCommand(command.params)
        else:
          discard await bot.send(newMessage(chatId, jokes.sample))
      of "removeVoice":
        if command.params != "":
          removeVoiceCommand(command.params)
        else:
          discard await bot.send(newMessage(chatId, jokes.sample))
      of "removeVideo":
        if command.params != "":
          removeVideoCommand(command.params)
        else:
          discard await bot.send(newMessage(chatId, jokes.sample))

      of "addAdmin":
        if command.message.replyToMessage.isSome and command.message.replyToMessage.get.fromUser.isSome:
          if not isAdmin(command.message.replyToMessage.get.fromUser.get.id):
            addAdmin(command.message.replyToMessage.get.fromUser.get.id)
        else:
          discard await bot.send(newMessage(chatId, jokes.sample))
      of "removeAdmin":
        if command.message.replyToMessage.isSome and command.message.replyToMessage.get.fromUser.isSome:
          if isAdmin(command.message.replyToMessage.get.fromUser.get.id):
            removeAdmin(command.message.replyToMessage.get.fromUser.get.id)
        else:
          discard await bot.send(newMessage(chatId, jokes.sample))
      of "amIAdmin":
        var message = newMessage(chatId, "yep")
        message.disableNotification = true
        discard await bot.send(message)

  var file = getFileByCommand(commandText)
  if file != "":
    var message = newDocument(chatId, file)
    if command.message.replyToMessage.isSome:
      message.replyToMessageId = command.message.replyToMessage.get.messageId
    message.disableNotification = true
    discard await bot.send(message)

  var sticker = getStickerByCommand(commandText)
  if sticker != "":
    var message = newSticker(chatId, sticker)
    if command.message.replyToMessage.isSome:
      message.replyToMessageId = command.message.replyToMessage.get.messageId
    discard await bot.send(message)

  var photo = getPhotoByCommand(commandText)
  if photo != "":
    var message = newPhoto(chatId, photo)
    if command.message.replyToMessage.isSome:
      message.replyToMessageId = command.message.replyToMessage.get.messageId
    discard await bot.send(message)

  var voice = getVoiceByCommand(commandText)
  if voice != "":
    var message = newVoice(chatId, voice)
    if command.message.replyToMessage.isSome:
      message.replyToMessageId = command.message.replyToMessage.get.messageId
    discard await bot.send(message)

  var video = getVideoByCommand(commandText)
  if video != "":
    var message = newVideo(chatId, video)
    if command.message.replyToMessage.isSome:
      message.replyToMessageId = command.message.replyToMessage.get.messageId
    discard await bot.send(message)

  if commandText == "help":
    discard await bot.send(newMessage(chatId, """
/addAdmin - dodaj admina
/amIAdmin - czy jestem adminem
/removeAdmin - usun admina

/addCommand - dodaj komende
/getCommands - lista komend
/removeFile - usun komende plik
/removeSticker - usun komende sticker
/removePhoto - usun komende obrazek
/removeVoice - usun komende voice
/removeVideo - usun komende film

napisz inba a sie ztriggeruje
      """))

  if commandText == "getCommands":
    var message = "Pliki\n"
    for command in db.fastRows(sql"select command from commands_files"):
      message &= command[0] & "\n"

    message &= "\nStickery\n"
    for command in db.fastRows(sql"select command from commands_stickers"):
      message &= command[0] & "\n"

    message &= "\nObrazki\n"
    for command in db.fastRows(sql"select command from commands_photos"):
      message &= command[0] & "\n"

    message &= "\nVoice\n"
    for command in db.fastRows(sql"select command from commands_voices"):
      message &= command[0] & "\n"

    message &= "\nFilmy\n"
    for command in db.fastRows(sql"select command from commands_videos"):
      message &= command[0] & "\n"

    discard await bot.send(newMessage(chatId, message))

proc updateHandler(b: Telebot, u: Update) {.async.} =
  if u.message.isSome:
    var response = u.message.get

    if response.text.isSome and "inba" in response.text.get:
      let this_file = "file://" & getCurrentDir() & "/audio_2019-05-09_16-11-53.ogg"

      var document = newVoice(u.message.get.chat.id, this_file)
      document.caption = "🎉 INBA"
      discard await b.send(document)

setupDatabase()
randomize()

let bot = newTeleBot(API_KEY)

bot.onUpdate(updateHandler)
bot.onUnknownCommand(commandHandler)
bot.poll(timeout=300)