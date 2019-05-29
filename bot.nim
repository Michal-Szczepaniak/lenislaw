import telebot, asyncdispatch, logging, options, os, strutils, db_sqlite, random, strformat, httpclient, json, osproc, math

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
  db.exec(sql("""CREATE TABLE IF NOT EXISTS commands_texts (
              id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
              command varchar(255) NOT NULL,
              text TEXT NOT NULL)
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

proc setAudioCommand(c, f: string) =
  db.exec(sql"INSERT INTO commands_audios (command, audio) VALUES (?,?)", c, f)
proc getAudioByCommand(c: string): string =
  result = db.getValue(sql"SELECT audio FROM commands_audios WHERE command = ?", c)
proc removeAudioCommand(c: string) =
  db.exec(sql"DELETE FROM commands_audios WHERE command = ?", c)

proc setTextCommand(c, f: string) =
  db.exec(sql"INSERT INTO commands_texts (command, text) VALUES (?,?)", c, f)
proc getTextByCommand(c: string): string =
  result = db.getValue(sql"SELECT text FROM commands_texts WHERE command = ?", c)
proc removeTextCommand(c: string) =
  db.exec(sql"DELETE FROM commands_texts WHERE command = ?", c)

proc addAdmin(id:int) =
  db.exec(sql"INSERT INTO admins (user_id) VALUES (?)", id)
proc removeAdmin(id:int) =
  db.exec(sql"DELETE FROM admins WHERE user_id = ?", id)
proc isAdmin(id:int): bool =
  result = db.getValue(sql"SELECT id FROM admins WHERE user_id = ?", id) != ""

proc downloadImage(image: PhotoSize): Future[string] {.async.} =
  let
    url_getfile = fmt"https://api.telegram.org/bot{API_KEY}/getFile?file_id="
    api_file = fmt"https://api.telegram.org/file/bot{API_KEY}/"
    file_id = image.fileId
    responz = await newAsyncHttpClient().get(url_getfile & file_id) # file_id > file_path
    responz_body = await responz.body
    file_path = parseJson(responz_body)["result"]["file_path"].getStr()
    responx = await newAsyncHttpClient().get(api_file & file_path)  # file_path > file
    file_content = await responx.body
    fileName = "tmp" & image.fileId

  # debugEcho(url_getfile & file_id)
  writeFile(fileName, file_content)
  return fileName

proc deleteMessageEx(b: Telebot, chatId: int64, messageId: int) {.async.} =
  # try:
    # discard deleteMessage(b, $chatId, messageId)
  # except IOError:
    # discard
  discard

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
              setPhotoCommand(command.params, command.message.replyToMessage.get.photo.get[^1].fileId)
              discard await bot.send(newMessage(chatId, "dodano obrazek"))

          if command.message.replyToMessage.get.voice.isSome:
            if getVoiceByCommand(command.params) == "":
              setVoiceCommand(command.params, command.message.replyToMessage.get.voice.get.fileId)
              discard await bot.send(newMessage(chatId, "dodano voice"))

          if command.message.replyToMessage.get.video.isSome:
            if getVideoByCommand(command.params) == "":
              setVideoCommand(command.params, command.message.replyToMessage.get.video.get.fileId)
              discard await bot.send(newMessage(chatId, "dodano video"))

          if command.message.replyToMessage.get.audio.isSome:
            if getAudioByCommand(command.params) == "":
              setAudioCommand(command.params, command.message.replyToMessage.get.audio.get.fileId)
            discard await bot.send(newMessage(chatId, "dodano audio"))

          if command.message.replyToMessage.get.text.isSome:
            if getTextByCommand(command.params) == "":
              setTextCommand(command.params, command.message.replyToMessage.get.text.get)
            discard await bot.send(newMessage(chatId, "dodano tekst"))
        else:
          discard await bot.send(newMessage(chatId, jokes.sample))

        discard deleteMessageEx(bot, chatId, command.message.messageId)

      of "removeFile":
        discard deleteMessageEx(bot, chatId, command.message.messageId)
        if command.params != "":
          removeFileCommand(command.params)
        else:
          discard await bot.send(newMessage(chatId, jokes.sample))
      of "removeSticker":
        discard deleteMessageEx(bot, chatId, command.message.messageId)
        if command.params != "":
          removeStickerCommand(command.params)
        else:
          discard await bot.send(newMessage(chatId, jokes.sample))
      of "removePhoto":
        discard deleteMessageEx(bot, chatId, command.message.messageId)
        if command.params != "":
          removePhotoCommand(command.params)
        else:
          discard await bot.send(newMessage(chatId, jokes.sample))
      of "removeVoice":
        discard deleteMessageEx(bot, chatId, command.message.messageId)
        if command.params != "":
          removeVoiceCommand(command.params)
        else:
          discard await bot.send(newMessage(chatId, jokes.sample))
      of "removeVideo":
        discard deleteMessageEx(bot, chatId, command.message.messageId)
        if command.params != "":
          removeVideoCommand(command.params)
        else:
          discard await bot.send(newMessage(chatId, jokes.sample))
      of "removeAudio":
        discard deleteMessageEx(bot, chatId, command.message.messageId)
        if command.params != "":
          removeAudioCommand(command.params)
        else:
          discard await bot.send(newMessage(chatId, jokes.sample))
      of "removeTekst":
        discard deleteMessageEx(bot, chatId, command.message.messageId)
        if command.params != "":
          removeTextCommand(command.params)
        else:
          discard await bot.send(newMessage(chatId, jokes.sample))

      of "addAdmin":
        discard deleteMessageEx(bot, chatId, command.message.messageId)
        if command.message.replyToMessage.isSome and command.message.replyToMessage.get.fromUser.isSome:
          if not isAdmin(command.message.replyToMessage.get.fromUser.get.id):
            addAdmin(command.message.replyToMessage.get.fromUser.get.id)
        else:
          discard await bot.send(newMessage(chatId, jokes.sample))
      of "removeAdmin":
        discard deleteMessageEx(bot, chatId, command.message.messageId)
        if command.message.replyToMessage.isSome and command.message.replyToMessage.get.fromUser.isSome:
          if isAdmin(command.message.replyToMessage.get.fromUser.get.id):
            removeAdmin(command.message.replyToMessage.get.fromUser.get.id)
        else:
          discard await bot.send(newMessage(chatId, jokes.sample))
      of "amIAdmin":
        discard deleteMessageEx(bot, chatId, command.message.messageId)
        var message = newMessage(chatId, "yep")
        message.disableNotification = true
        discard await bot.send(message)

  var file = getFileByCommand(commandText)
  if file != "":
    discard deleteMessageEx(bot, chatId, command.message.messageId)
    var message = newDocument(chatId, file)
    if command.message.replyToMessage.isSome:
      message.replyToMessageId = command.message.replyToMessage.get.messageId
    message.disableNotification = true
    discard await bot.send(message)

  var sticker = getStickerByCommand(commandText)
  if sticker != "":
    discard deleteMessageEx(bot, chatId, command.message.messageId)
    var message = newSticker(chatId, sticker)
    if command.message.replyToMessage.isSome:
      message.replyToMessageId = command.message.replyToMessage.get.messageId
    discard await bot.send(message)

  var photo = getPhotoByCommand(commandText)
  if photo != "":
    discard deleteMessageEx(bot, chatId, command.message.messageId)
    var message = newPhoto(chatId, photo)
    if command.message.replyToMessage.isSome:
      message.replyToMessageId = command.message.replyToMessage.get.messageId
    discard await bot.send(message)

  var voice = getVoiceByCommand(commandText)
  if voice != "":
    discard deleteMessageEx(bot, chatId, command.message.messageId)
    var message = newVoice(chatId, voice)
    if command.message.replyToMessage.isSome:
      message.replyToMessageId = command.message.replyToMessage.get.messageId
    discard await bot.send(message)

  var video = getVideoByCommand(commandText)
  if video != "":
    discard deleteMessageEx(bot, chatId, command.message.messageId)
    var message = newVideo(chatId, video)
    if command.message.replyToMessage.isSome:
      message.replyToMessageId = command.message.replyToMessage.get.messageId
    discard await bot.send(message)

  var audio = getAudioByCommand(commandText)
  if audio != "":
    discard deleteMessageEx(bot, chatId, command.message.messageId)
    debugEcho audio
    var message = newAudio(chatId, audio)
    if command.message.replyToMessage.isSome:
      message.replyToMessageId = command.message.replyToMessage.get.messageId
    discard await bot.send(message)

  var text = getTextByCommand(commandText)
  if text != "":
    discard deleteMessageEx(bot, chatId, command.message.messageId)
    var message = newMessage(chatId, text)
    if command.message.replyToMessage.isSome:
      message.replyToMessageId = command.message.replyToMessage.get.messageId
    discard await bot.send(message)


  case commandText:
    of "pis":
      discard execShellCmd("convert PiS.png -font \"font.ttf\" -pointsize 81 -fill white -draw \"text 190,410 '" & multiReplace(toUpper(command.params), [("\'", ""), ("\"", "")]) & "'\" " & $command.message.messageId)
      discard await bot.send(newPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId))
      removeFile($command.message.messageId)

    of "tvp1":
      discard execShellCmd("convert tvp.png -font \"font.ttf\" -pointsize 34 -fill white -draw \"text 142,356 '" & multiReplace(toUpper(command.params), [("\'", ""), ("\"", "")]) & "'\" " & $command.message.messageId)
      discard await bot.send(newPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId))
      removeFile($command.message.messageId)

    of "tvp2":
      discard execShellCmd("convert tvp2.png -font \"font.ttf\" -pointsize 34 -fill white -draw \"text 142,356 '" & multiReplace(toUpper(command.params), [("\'", ""), ("\"", "")]) & "'\" " & $command.message.messageId)
      discard await bot.send(newPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId))
      removeFile($command.message.messageId)

    of "tvp3":
      discard execShellCmd("convert tvp3.png -font \"font.ttf\" -pointsize 34 -fill white -draw \"text 142,356 '" & multiReplace(toUpper(command.params), [("\'", ""), ("\"", "")]) & "'\" " & $command.message.messageId)
      discard await bot.send(newPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId))
      removeFile($command.message.messageId)

    of "mi8":
      if command.message.replyToMessage.isSome and command.message.replyToMessage.get.photo.isSome:
        let
          size = command.message.replyToMessage.get.photo.get[^1].width/3
          fileName = await downloadImage(command.message.replyToMessage.get.photo.get[^1])

        discard execShellCmd("convert " & fileName & " \\( mi8.png -resize " & $size & "x" & $size & " \\) -gravity southwest -geometry +10+10 -composite " & $command.message.messageId)
        discard await bot.send(newPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId))
        removeFile($command.message.messageId)
        removeFile(fileName)

    of "mi9":
      if command.message.replyToMessage.isSome and command.message.replyToMessage.get.photo.isSome:
        let
          size = command.message.replyToMessage.get.photo.get[^1].width/3
          fileName = await downloadImage(command.message.replyToMessage.get.photo.get[^1])

        discard execShellCmd("convert " & fileName & " \\( mi9.png -resize " & $size & "x" & $size & " \\) -gravity southwest -geometry +10+10 -composite " & $command.message.messageId)
        discard await bot.send(newPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId))
        removeFile($command.message.messageId)
        removeFile(fileName)

    of "snap":
      if command.message.replyToMessage.isSome and command.message.replyToMessage.get.photo.isSome:
        let
          width = command.message.replyToMessage.get.photo.get[^1].width
          height = command.message.replyToMessage.get.photo.get[^1].height
          fileName = await downloadImage(command.message.replyToMessage.get.photo.get[^1])

        discard execShellCmd("convert " & fileName & " -fill \"rgba(0, 0, 0, 0.45)\" -draw \"rectangle 0," & $int(round(height/2 - height/18)) & " " & $width & "," & $int(round(height/2 + height/18)) & "\" -pointsize 38 -fill white -gravity center -draw \"text 0,0 '" & multiReplace(command.params, [("\'", ""), ("\"", "")]) & "'\" " & $command.message.messageId)
        discard await bot.send(newPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId))
        removeFile($command.message.messageId)
        removeFile(fileName)

    of "snapbot":
      if command.message.replyToMessage.isSome and command.message.replyToMessage.get.photo.isSome:
        let
          width = command.message.replyToMessage.get.photo.get[^1].width
          height = command.message.replyToMessage.get.photo.get[^1].height
          fileName = await downloadImage(command.message.replyToMessage.get.photo.get[^1])

        discard execShellCmd("convert " & fileName & " -fill \"rgba(0, 0, 0, 0.45)\" -draw \"rectangle 0," & $int(round(float(height)*0.8 - height/18)) & " " & $width & "," & $int(round(float(height)*0.8 + height/18)) & "\" -pointsize 38 -fill white -gravity south -draw \"text 0,+" & $int(round(float(height)*0.2)-20.0) & " '" & multiReplace(command.params, [("\'", ""), ("\"", "")]) & "'\" " & $command.message.messageId)
        discard await bot.send(newPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId))
        removeFile($command.message.messageId)
        removeFile(fileName)

    of "snaptop":
      if command.message.replyToMessage.isSome and command.message.replyToMessage.get.photo.isSome:
        let
          width = command.message.replyToMessage.get.photo.get[^1].width
          height = command.message.replyToMessage.get.photo.get[^1].height
          fileName = await downloadImage(command.message.replyToMessage.get.photo.get[^1])

        discard execShellCmd("convert " & fileName & " -fill \"rgba(0, 0, 0, 0.45)\" -draw \"rectangle 0," & $int(round(float(height)*0.2 - height/18)) & " " & $width & "," & $int(round(float(height)*0.2 + height/18)) & "\" -pointsize 38 -fill white -gravity north -draw \"text 0,+" & $int(round(float(height)*0.2)-16.0) & " '" & multiReplace(command.params, [("\'", ""), ("\"", "")]) & "'\" " & $command.message.messageId)
        discard await bot.send(newPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId))
        removeFile($command.message.messageId)
        removeFile(fileName)

    of "yomomma":
      discard deleteMessageEx(bot, chatId, command.message.messageId)
      discard await bot.send(newMessage(chatId, jokes.sample))

    of "help":
      discard deleteMessageEx(bot, chatId, command.message.messageId)
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
/removeAudio - usun komende audio
/removeTekst - usun komende teks

napisz inba a sie ztriggeruje
      """))

    of "getCommands":
      discard deleteMessageEx(bot, chatId, command.message.messageId)

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

      message &= "\nAudio\n"
      for command in db.fastRows(sql"select command from commands_audios"):
        message &= command[0] & "\n"

      message &= "\nTekst\n"
      for command in db.fastRows(sql"select command from commands_texts"):
        message &= command[0] & "\n"

      discard await bot.send(newMessage(chatId, message))
  discard

proc inlineHandler(b: Telebot, u: InlineQuery) {.async.} =
  debugEcho u.query
  try:
    case u.query:
      of "t":
        var results: seq[InlineQueryResultArticle]
        for command in db.fastRows(sql"select id, command, text from commands_texts"):
          var res: InlineQueryResultArticle
          res.kind = "article"
          res.title = command[1]
          res.id = command[0]
          res.inputMessageContent = InputTextMessageContent(command[2]).some
          results.add(res)
        discard waitFor b.answerInlineQuery(u.id, results)
      of "a":
        var results: seq[InlineQueryResultCachedAudio]
        for command in db.fastRows(sql"select id, command, audio from commands_audios LIMIT 1"):
          var res: InlineQueryResultCachedAudio
          res.kind = "audio"
          res.audioFileId = command[2]
          res.id = command[0]
          results.add(res)
        discard waitFor b.answerInlineQuery(u.id, results)
      of "vi":
        var results: seq[InlineQueryResultCachedVideo]
        for command in db.fastRows(sql"select id, command, video from commands_videos"):
          var res: InlineQueryResultCachedVideo
          res.kind = "video"
          res.videoFileId = command[2]
          res.title = command[1]
          res.id = command[0]
          results.add(res)
        discard waitFor b.answerInlineQuery(u.id, results)
      of "v":
        var results: seq[InlineQueryResultCachedVoice]
        for command in db.fastRows(sql"select id, command, voice from commands_voices"):
          var res: InlineQueryResultCachedVoice
          res.kind = "voice"
          res.voiceFileId = command[2]
          res.title = command[1]
          res.id = command[0]
          results.add(res)
        discard waitFor b.answerInlineQuery(u.id, results)
      of "p":
        var results: seq[InlineQueryResultCachedPhoto]
        for command in db.fastRows(sql"select id, command, photo from commands_photos"):
          var res: InlineQueryResultCachedPhoto
          res.kind = "photo"
          res.photoFileId = command[2]
          res.id = command[0]
          results.add(res)
        discard waitFor b.answerInlineQuery(u.id, results)
      of "s":
        var results: seq[InlineQueryResultCachedSticker]
        for command in db.fastRows(sql"select id, command, sticker from commands_stickers"):
          var res: InlineQueryResultCachedSticker
          res.kind = "sticker"
          res.stickerFileId = command[2]
          res.id = command[0]
          results.add(res)
        discard waitFor b.answerInlineQuery(u.id, results)
      of "f":
        var results: seq[InlineQueryResultCacchedDocument]
        for command in db.fastRows(sql"select id, command, file from commands_files"):
          var res: InlineQueryResultCacchedDocument
          res.kind = "document"
          res.documentFileId = command[2]
          res.title = command[1]
          res.id = command[0]
          results.add(res)
        discard waitFor b.answerInlineQuery(u.id, results)
  except IOError:
    echo getCurrentExceptionMsg()

proc updateHandler(b: Telebot, u: Update) {.async.} =
  if u.message.isSome:
    var response = u.message.get

    if response.text.isSome and "inba" in response.text.get:
      let this_file = "file://" & getCurrentDir() & "/audio_2019-05-09_16-11-53.ogg"

      var document = newVoice(u.message.get.chat.id, this_file)
      document.caption = "🎉 INBA"
      discard await b.send(document)

    if response.text.isSome and (" Xd" in response.text.get or response.text.get.startsWith("Xd ") or response.text.get == "Xd"):
      var message = newMessage(u.message.get.chat.id, """
Serio, mało rzeczy mnie triggeruje tak jak to chore „Xd”. Kombinacji x i d można używać na wiele wspaniałych sposobów. Coś cię śmieszy? Stawiasz „xD”. Coś się bardzo śmieszy? Śmiało: „XD”! Coś doprowadza Cię do płaczu ze śmiechu? „XDDD” i załatwione. Uśmiechniesz się pod nosem? „xd”. Po kłopocie.
A co ma do tego ten bękart klawiaturowej ewolucji, potwór i zakała ludzkiej estetyki - „Xd”? Co to w ogóle ma wyrażać? Martwego człowieka z wywalonym jęzorem? Powiem Ci, co to znaczy. To znaczy, że masz w telefonie włączone zaczynanie zdań dużą literą, ale szkoda Ci klikać capsa na jedno „d” później. Korona z głowy spadnie? Nie sondze. „Xd” to symptom tego, że masz mnie, jako rozmówcę, gdzieś, bo Ci się nawet kliknąć nie chce, żeby mi wysłać poprawny emotikon. Szanujesz mnie? Używaj „xd”, „xD”, „XD”, do wyboru. Nie szanujesz mnie? Okaż to. Wystarczy, że wstawisz to zjebane „Xd” w choć jednej wiadomości. Nie pozdrawiam
""")
      message.replyToMessageId = response.messageId
      discard await b.send(message)

setupDatabase()
randomize()

let bot = newTeleBot(API_KEY)

bot.onUpdate(updateHandler)
bot.onUnknownCommand(commandHandler)
bot.onInlineQuery(inlineHandler)
bot.poll(timeout=300)