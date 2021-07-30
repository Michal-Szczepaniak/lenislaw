import db_sqlite, strutils

let db* = open("lenek.db", "", "", "")

proc setupDatabase*() =
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
  db.exec(sql("""CREATE TABLE IF NOT EXISTS commands_texts (
              id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
              command varchar(255) NOT NULL,
              text TEXT NOT NULL)
            """))
  db.exec(sql("""CREATE TABLE IF NOT EXISTS admins (
              id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
              user_id INTEGER NOT NULL)
            """))
  db.exec(sql("""CREATE TABLE IF NOT EXISTS features_whitelist (
              id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
              feature varchar(2) NOT NULL,
              chat INT NOT NULL)
            """))
  db.exec(sql("""CREATE TABLE IF NOT EXISTS statistics_chats (
              id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
              chat_name varchar(255))
            """))

proc setFileCommand*(c, f: string) =
  db.exec(sql"INSERT INTO commands_files (command, file) VALUES (?,?)", c, f)
proc getFileByCommand*(c: string): string =
  result = db.getValue(sql"SELECT file FROM commands_files WHERE command = ?", c)
proc removeFileCommand*(c: string) =
  db.exec(sql"DELETE FROM commands_files WHERE command = ?", c)
iterator getFileCommands*(): Row =
  for i in db.fastRows(sql"select id, command, file from commands_files"):
    yield i

proc setStickerCommand*(c, s: string) =
  db.exec(sql"INSERT INTO commands_stickers (command, sticker) VALUES (?,?)", c, s)
proc getStickerByCommand*(c: string): string =
  result = db.getValue(sql"SELECT sticker FROM commands_stickers WHERE command = ?", c)
proc removeStickerCommand*(c: string) =
  db.exec(sql"DELETE FROM commands_stickers WHERE command = ?", c)
iterator getStickerCommands*(): Row =
  for i in db.fastRows(sql"select id, command, sticker from commands_stickers"):
    yield i

proc setPhotoCommand*(c, f: string) =
  db.exec(sql"INSERT INTO commands_photos (command, photo) VALUES (?,?)", c, f)
proc getPhotoByCommand*(c: string): string =
  result = db.getValue(sql"SELECT photo FROM commands_photos WHERE command = ?", c)
proc removePhotoCommand*(c: string) =
  db.exec(sql"DELETE FROM commands_photos WHERE command = ?", c)
iterator getPhotoCommands*(): Row =
  for i in db.fastRows(sql"select id, command, photo from commands_photos"):
    yield i

proc setVoiceCommand*(c, f: string) =
  db.exec(sql"INSERT INTO commands_voices (command, voice) VALUES (?,?)", c, f)
proc getVoiceByCommand*(c: string): string =
  result = db.getValue(sql"SELECT voice FROM commands_voices WHERE command = ?", c)
proc removeVoiceCommand*(c: string) =
  db.exec(sql"DELETE FROM commands_voices WHERE command = ?", c)
iterator getVoiceCommands*(): Row =
  for i in db.fastRows(sql"select id, command, voice from commands_voices"):
    yield i

proc setVideoCommand*(c, f: string) =
  db.exec(sql"INSERT INTO commands_videos (command, video) VALUES (?,?)", c, f)
proc getVideoByCommand*(c: string): string =
  result = db.getValue(sql"SELECT video FROM commands_videos WHERE command = ?", c)
proc removeVideoCommand*(c: string) =
  db.exec(sql"DELETE FROM commands_videos WHERE command = ?", c)
iterator getVideoCommands*(): Row =
  for i in db.fastRows(sql"select id, command, video from commands_videos"):
    yield i

proc setAudioCommand*(c, f: string) =
  db.exec(sql"INSERT INTO commands_audios (command, audio) VALUES (?,?)", c, f)
proc getAudioByCommand*(c: string): string =
  result = db.getValue(sql"SELECT audio FROM commands_audios WHERE command = ?", c)
proc removeAudioCommand*(c: string) =
  db.exec(sql"DELETE FROM commands_audios WHERE command = ?", c)
iterator getAudioCommands*(): Row =
  for i in db.fastRows(sql"select id, command, audio from commands_audios"):
    yield i

proc setTextCommand*(c, f: string) =
  db.exec(sql"INSERT INTO commands_texts (command, text) VALUES (?,?)", c, f)
proc getTextByCommand*(c: string): string =
  result = db.getValue(sql"SELECT text FROM commands_texts WHERE command = ?", c)
proc removeTextCommand*(c: string) =
  db.exec(sql"DELETE FROM commands_texts WHERE command = ?", c)
iterator getTextCommands*(): Row =
  for i in db.fastRows(sql"select id, command, text from commands_texts"):
    yield i

proc addAdmin*(id:int) =
  db.exec(sql"INSERT INTO admins (user_id) VALUES (?)", id)
proc removeAdmin*(id:int) =
  db.exec(sql"DELETE FROM admins WHERE user_id = ?", id)
proc isAdmin*(id:int): bool =
  result = db.getValue(sql"SELECT id FROM admins WHERE user_id = ?", id) != ""

proc addFeatureToWhitelist*(feature:string, chatId:int64) =
  db.exec(sql"INSERT INTO features_whitelist (feature,chat) VALUES (?,?)", feature, chatId)
proc removeFeatureFromWhitelist*(feature:string, chatId:int64) =
  db.exec(sql"DELETE FROM features_whitelist WHERE feature = ? AND chat = ?", feature, chatId)
proc isFeatureEnabled*(feature:string, chatId:int64): bool =
  result = db.getValue(sql"SELECT id FROM features_whitelist WHERE feature = ? AND chat = ?", feature, chatId) != ""

iterator getChats*(): Row =
  for row in db.fastRows(sql"SELECT id FROM statistics_chats;"):
    yield row

proc addChatToStatistics*(chatId:int64, chatName:string) =
  try:
    db.exec(sql"INSERT INTO statistics_chats (id,chat_name) VALUES (?,?)", chatId, chatName)
  except:
    discard
proc getChatsCount*(): string =
  return db.getValue(sql"SELECT count(id) FROM statistics_chats;")

proc getCommands*(html: bool): string =
  var message = "@Pliki$\n"
  for command in db.fastRows(sql"select command from commands_files"):
    message &= command[0] & "\n"

  message &= "\n@Stickery$\n"
  for command in db.fastRows(sql"select command from commands_stickers"):
    message &= command[0] & "\n"

  message &= "\n@Obrazki$\n"
  for command in db.fastRows(sql"select command from commands_photos"):
    message &= command[0] & "\n"

  message &= "\n@Voice$\n"
  for command in db.fastRows(sql"select command from commands_voices"):
    message &= command[0] & "\n"

  message &= "\n@Filmy$\n"
  for command in db.fastRows(sql"select command from commands_videos"):
    message &= command[0] & "\n"

  message &= "\n@Audio$\n"
  for command in db.fastRows(sql"select command from commands_audios"):
    message &= command[0] & "\n"

  message &= "\n@Tekst$\n"
  for command in db.fastRows(sql"select command from commands_texts"):
    message &= command[0] & "\n"

  if html:
    return message.replace("\n", "<br/>").replace("@", "<h2>").replace("$", "</h2>")
  else:
    return message.replace("@", "").replace("$", "")
