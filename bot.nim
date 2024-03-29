import telebot, asyncdispatch, logging, options, os, strutils, random, strformat, httpclient, json, math, asynchttpserver, emerald, db, htmlparser, xmltree, osproc, parseutils

var
  L = newConsoleLogger(fmtStr="$levelname, [$time] ")
  coronaLastCases = 0
  coronaLastDeaths = 0
  coronaLastRecovered = 0
addHandler(L)

const API_KEY = slurp("secret.key").strip()
const USER_ID = 412515181

const jokes = readFile("jokes.txt").splitLines
const jokesPl = readFile("jokes_pl.txt").splitLines

proc broadcastMessage(b: Telebot, message:string) {.async.} =
  for row in db.getChats():
    var id: int64
    discard row[0].parseBiggestInt(id)
    debugEcho id
    debugEcho message
    discard b.sendMessage(id, message)

proc downloadImage(document: PhotoSize): Future[string] {.async.} =
  let
    url_getfile = fmt"https://api.telegram.org/bot{API_KEY}/getFile?file_id="
    api_file = fmt"https://api.telegram.org/file/bot{API_KEY}/"
    file_id = document.fileId
    responz = await newAsyncHttpClient().get(url_getfile & file_id) # file_id > file_path
    responz_body = await responz.body
    file_path = parseJson(responz_body)["result"]["file_path"].getStr()
    responx = await newAsyncHttpClient().get(api_file & file_path)  # file_path > file
    file_content = await responx.body
    fileName = "tmp" & document.fileId

  # debugEcho(url_getfile & file_id)
  writeFile(fileName, file_content)
  return fileName

proc downloadDocument(document: Document): Future[string] {.async.} =
  let
    url_getfile = fmt"https://api.telegram.org/bot{API_KEY}/getFile?file_id="
    api_file = fmt"https://api.telegram.org/file/bot{API_KEY}/"
    file_id = document.fileId
    responz = await newAsyncHttpClient().get(url_getfile & file_id) # file_id > file_path
    responz_body = await responz.body
    file_path = parseJson(responz_body)["result"]["file_path"].getStr()
    responx = await newAsyncHttpClient().get(api_file & file_path)  # file_path > file
    file_content = await responx.body
    fileName = "tmp" & document.fileId

  # debugEcho(url_getfile & file_id)
  writeFile(fileName, file_content)
  return fileName

proc downloadVideo(document: Video): Future[string] {.async.} =
  let
    url_getfile = fmt"https://api.telegram.org/bot{API_KEY}/getFile?file_id="
    api_file = fmt"https://api.telegram.org/file/bot{API_KEY}/"
    file_id = document.fileId
    responz = await newAsyncHttpClient().get(url_getfile & file_id) # file_id > file_path
    responz_body = await responz.body
    file_path = parseJson(responz_body)["result"]["file_path"].getStr()
    responx = await newAsyncHttpClient().get(api_file & file_path)  # file_path > file
    file_content = await responx.body
    fileName = "tmp" & document.fileId

  # debugEcho(url_getfile & file_id)
  writeFile(fileName, file_content)
  return fileName

proc canBotDelete*(b: TeleBot, m: Message): Future[bool] {.async.} =
    let bot = await b.getMe()
    let botChat = await getChatMember(b, $m.chat.id.int, bot.id)
    if botChat.canDeleteMessages.isSome:
        return botChat.canDeleteMessages.get

proc deleteMessageEx(b: Telebot, chat: Chat, message: Message) {.async.} =
  if await b.canBotDelete(message):
    try:
      discard await b.deleteMessage($chat.id, message.messageId)
    except IOError:
      discard
  discard

proc getDiffSting(last, current: int): string =
  var symbol = ""
  if last != current:
    if (current - last) >= 0:
      symbol = "+"
    else:
      symbol = "-"
    result = symbol & $(current - last)
  else:
    result = ""

proc commandHandler(bot: Telebot, command: Command): Future[bool] {.async.} =
  var commandText = command.command
  var chatId = command.message.chat.id

  if command.message.fromUser.isSome and (command.message.fromUser.get.id == USER_ID or isAdmin(command.message.fromUser.get.id)):
    case commandText:
      of "addCommand":
        if command.message.replyToMessage.isSome and command.params != "":
          if command.message.replyToMessage.get.sticker.isSome:
            if getStickerByCommand(command.params) == "":
              setStickerCommand(command.params, command.message.replyToMessage.get.sticker.get.fileId)
              discard await bot.sendMessage(chatId, "dodano sticker")

          if command.message.replyToMessage.get.document.isSome:
            if getFileByCommand(command.params) == "":
              setFileCommand(command.params, command.message.replyToMessage.get.document.get.fileId)
              discard await bot.sendMessage(chatId, "dodano plik")

          if command.message.replyToMessage.get.photo.isSome:
            if getPhotoByCommand(command.params) == "":
              setPhotoCommand(command.params, command.message.replyToMessage.get.photo.get[^1].fileId)
              discard await bot.sendMessage(chatId, "dodano obrazek")

          if command.message.replyToMessage.get.voice.isSome:
            if getVoiceByCommand(command.params) == "":
              setVoiceCommand(command.params, command.message.replyToMessage.get.voice.get.fileId)
              discard await bot.sendMessage(chatId, "dodano voice")

          if command.message.replyToMessage.get.video.isSome:
            if getVideoByCommand(command.params) == "":
              setVideoCommand(command.params, command.message.replyToMessage.get.video.get.fileId)
              discard await bot.sendMessage(chatId, "dodano video")

          if command.message.replyToMessage.get.audio.isSome:
            if getAudioByCommand(command.params) == "":
              setAudioCommand(command.params, command.message.replyToMessage.get.audio.get.fileId)
            discard await bot.sendMessage(chatId, "dodano audio")

          if command.message.replyToMessage.get.text.isSome:
            if getTextByCommand(command.params) == "":
              setTextCommand(command.params, command.message.replyToMessage.get.text.get)
            discard await bot.sendMessage(chatId, "dodano tekst")
        else:
          discard await bot.sendMessage(chatId, jokes.sample)

        discard deleteMessageEx(bot, command.message.chat, command.message)

      of "removeFile":
        discard deleteMessageEx(bot, command.message.chat, command.message)
        if command.params != "":
          removeFileCommand(command.params)
        else:
          discard await bot.sendMessage(chatId, jokes.sample)
      of "removeSticker":
        discard deleteMessageEx(bot, command.message.chat, command.message)
        if command.params != "":
          removeStickerCommand(command.params)
        else:
          discard await bot.sendMessage(chatId, jokes.sample)
      of "removePhoto":
        discard deleteMessageEx(bot, command.message.chat, command.message)
        if command.params != "":
          removePhotoCommand(command.params)
        else:
          discard await bot.sendMessage(chatId, jokes.sample)
      of "removeVoice":
        discard deleteMessageEx(bot, command.message.chat, command.message)
        if command.params != "":
          removeVoiceCommand(command.params)
        else:
          discard await bot.sendMessage(chatId, jokes.sample)
      of "removeVideo":
        discard deleteMessageEx(bot, command.message.chat, command.message)
        if command.params != "":
          removeVideoCommand(command.params)
        else:
          discard await bot.sendMessage(chatId, jokes.sample)
      of "removeAudio":
        discard deleteMessageEx(bot, command.message.chat, command.message)
        if command.params != "":
          removeAudioCommand(command.params)
        else:
          discard await bot.sendMessage(chatId, jokes.sample)
      of "removeTekst":
        discard deleteMessageEx(bot, command.message.chat, command.message)
        if command.params != "":
          removeTextCommand(command.params)
        else:
          discard await bot.sendMessage(chatId, jokes.sample)

      of "addAdmin":
        discard deleteMessageEx(bot, command.message.chat, command.message)
        if command.message.replyToMessage.isSome and command.message.replyToMessage.get.fromUser.isSome:
          if not isAdmin(command.message.replyToMessage.get.fromUser.get.id):
            addAdmin(command.message.replyToMessage.get.fromUser.get.id)
        else:
          discard await bot.sendMessage(chatId, jokes.sample)

      of "whitelist":
        discard deleteMessageEx(bot, command.message.chat, command.message)
        if not isFeatureEnabled(command.params, command.message.chat.id):
          addFeatureToWhitelist(command.params, command.message.chat.id)
        else:
          discard await bot.sendMessage(chatId, jokes.sample)

      of "unwhitelist":
        discard deleteMessageEx(bot, command.message.chat, command.message)
        if isFeatureEnabled(command.params, command.message.chat.id):
          removeFeatureFromWhitelist(command.params, command.message.chat.id)
        else:
          discard await bot.sendMessage(chatId, jokes.sample)

      of "removeAdmin":
        discard deleteMessageEx(bot, command.message.chat, command.message)
        if command.message.replyToMessage.isSome and command.message.replyToMessage.get.fromUser.isSome:
          if isAdmin(command.message.replyToMessage.get.fromUser.get.id):
            removeAdmin(command.message.replyToMessage.get.fromUser.get.id)
        else:
          discard await bot.sendMessage(chatId, jokes.sample)
      of "amIAdmin":
        discard deleteMessageEx(bot, command.message.chat, command.message)
        discard await bot.sendMessage(chatId, "yep", disableNotification = true)
      of "broadcast":
        discard deleteMessageEx(bot, command.message.chat, command.message)
        if command.params != "":
          discard broadcastMessage(bot, command.params)

  var file = getFileByCommand(commandText)
  if file != "":
    discard deleteMessageEx(bot, command.message.chat, command.message)
    var replyId = 0
    if command.message.replyToMessage.isSome:
      replyId = command.message.replyToMessage.get.messageId
    discard await bot.sendDocument(chatId, file, replyToMessageId = replyId, disableNotification = true)

  var sticker = getStickerByCommand(commandText)
  if sticker != "":
    discard deleteMessageEx(bot, command.message.chat, command.message)
    var replyId = 0
    if command.message.replyToMessage.isSome:
      replyId = command.message.replyToMessage.get.messageId
    discard await bot.sendSticker(chatId, sticker, replyToMessageId = replyId)

  var photo = getPhotoByCommand(commandText)
  if photo != "":
    discard deleteMessageEx(bot, command.message.chat, command.message)
    var replyId = 0
    if command.message.replyToMessage.isSome:
      replyId = command.message.replyToMessage.get.messageId
    discard await bot.sendPhoto(chatId, photo, replyToMessageId = replyId)

  var voice = getVoiceByCommand(commandText)
  if voice != "":
    discard deleteMessageEx(bot, command.message.chat, command.message)
    debugEcho voice
    var replyId = 0
    if command.message.replyToMessage.isSome:
      replyId = command.message.replyToMessage.get.messageId
    discard await bot.sendVoice(chatId, voice, replyToMessageId = replyId)

  var video = getVideoByCommand(commandText)
  if video != "":
    discard deleteMessageEx(bot, command.message.chat, command.message)
    var replyId = 0
    if command.message.replyToMessage.isSome:
      replyId = command.message.replyToMessage.get.messageId
    discard await bot.sendVideo(chatId, video, replyToMessageId = replyId)

  var audio = getAudioByCommand(commandText)
  if audio != "":
    discard deleteMessageEx(bot, command.message.chat, command.message)
    debugEcho audio
    var replyId = 0
    if command.message.replyToMessage.isSome:
      replyId = command.message.replyToMessage.get.messageId
    discard await bot.sendAudio(chatId, audio, replyToMessageId = replyId)

  var text = getTextByCommand(commandText)
  if text != "":
    discard deleteMessageEx(bot, command.message.chat, command.message)
    debugEcho text
    var replyId = 0
    if command.message.replyToMessage.isSome:
      replyId = command.message.replyToMessage.get.messageId
    discard await bot.sendMessage(chatId, text, replyToMessageId = replyId)


  case commandText:
    of "korona", "koronachan", "korona-chan", "corona", "coronachan", "corona-chan":
      var
        numbers: seq[string]

      let
        client = newHttpClient()
        coronachan = client.getContent("https://www.worldometers.info/coronavirus/")
        html = parseHtml(coronachan)

      for node in html.findAll("div"):
        if node.attr("class") == "maincounter-number":
          for span in node.findAll("span"):
            numbers.add(span.innerText().strip())

      var
        coronaCurrentCases = replace(numbers[0], ",", "").parseInt()
        coronaCurrentDeaths = replace(numbers[1], ",", "").parseInt()
        coronaCurrentRecovered = replace(numbers[2], ",", "").parseInt()
        text = "*Wszystkie przypadki:* " & numbers[0] & getDiffSting(coronaLastCases, coronaCurrentCases) & " *Zgony:* " & numbers[1] & getDiffSting(coronaLastDeaths, coronaCurrentDeaths) & " *Wyleczeni:* " & numbers[2] & getDiffSting(coronaLastRecovered, coronaCurrentRecovered)

      coronaLastCases = coronaCurrentCases
      coronaLastDeaths = coronaCurrentDeaths
      coronaLastRecovered = coronaCurrentRecovered

      var replyId = 0
      if command.message.replyToMessage.isSome:
        replyId = command.message.replyToMessage.get.messageId

      discard deleteMessageEx(bot, command.message.chat, command.message)
      discard await bot.sendMessage(chatId, text, replyToMessageId = replyId, parseMode = "markdown")


    of "pis":
      discard deleteMessageEx(bot, command.message.chat, command.message)
      discard execShellCmd("convert PiS.png -font \"font.ttf\" -pointsize 81 -fill white -draw 'text 190,410 \"" & multiReplace(toUpper(command.params), [("\'", ""), ("\"", "\\\"")]) & "\"' " & $command.message.messageId)

      var replyId = 0
      if command.message.replyToMessage.isSome:
        replyId = command.message.replyToMessage.get.messageId
      discard await bot.sendPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId, replyToMessageId = replyId)
      removeFile($command.message.messageId)

    of "tvp1":
      discard deleteMessageEx(bot, command.message.chat, command.message)
      discard execShellCmd("convert tvp.png -font \"font.ttf\" -pointsize 34 -fill white -draw 'text 142,356 \"" & multiReplace(toUpper(command.params), [("\'", ""), ("\"", "\\\"")]) & "\"' " & $command.message.messageId)

      var replyId = 0
      if command.message.replyToMessage.isSome:
        replyId = command.message.replyToMessage.get.messageId
      discard await bot.sendPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId, replyToMessageId = replyId)
      removeFile($command.message.messageId)

    of "tvp2":
      discard deleteMessageEx(bot, command.message.chat, command.message)
      discard execShellCmd("convert tvp2.png -font \"font.ttf\" -pointsize 34 -fill white -draw 'text 142,356 \"" & multiReplace(toUpper(command.params), [("\'", ""), ("\"", "\\\"")]) & "\"' " & $command.message.messageId)

      var replyId = 0
      if command.message.replyToMessage.isSome:
        replyId = command.message.replyToMessage.get.messageId
      discard await bot.sendPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId, replyToMessageId = replyId)
      removeFile($command.message.messageId)

    of "tvp3":
      discard deleteMessageEx(bot, command.message.chat, command.message)
      discard execShellCmd("convert tvp3.png -font \"font.ttf\" -pointsize 34 -fill white -draw 'text 142,356 \"" & multiReplace(toUpper(command.params), [("\'", ""), ("\"", "\\\"")]) & "\"' " & $command.message.messageId)

      var replyId = 0
      if command.message.replyToMessage.isSome:
        replyId = command.message.replyToMessage.get.messageId
      discard await bot.sendPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId, replyToMessageId = replyId)
      removeFile($command.message.messageId)

    of "tvp4":
      discard deleteMessageEx(bot, command.message.chat, command.message)
      discard execShellCmd("convert tvp4.png -font \"Roboto-Bold.ttf\" -pointsize 37 -fill \"#dcdce5\" -draw 'text 195,488 \"" & multiReplace(toUpper(command.params), [("\'", ""), ("\"", "\\\"")]) & "\"' " & $command.message.messageId)

      var replyId = 0
      if command.message.replyToMessage.isSome:
        replyId = command.message.replyToMessage.get.messageId
      discard await bot.sendPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId, replyToMessageId = replyId)
      removeFile($command.message.messageId)

    of "tvp5":
      discard deleteMessageEx(bot, command.message.chat, command.message)
      discard execShellCmd("convert tvp5.png -font \"Roboto-Bold.ttf\" -pointsize 37 -fill \"#dcdce5\" -draw 'text 195,488 \"" & multiReplace(toUpper(command.params), [("\'", ""), ("\"", "\\\"")]) & "\"' " & $command.message.messageId)

      var replyId = 0
      if command.message.replyToMessage.isSome:
        replyId = command.message.replyToMessage.get.messageId
      discard await bot.sendPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId, replyToMessageId = replyId)
      removeFile($command.message.messageId)

    of "ss1":
      discard deleteMessageEx(bot, command.message.chat, command.message)
      var
        text = multiReplace(toUpper(command.params), [("\'", ""), ("\"", "\\\"")]).split('\n')
        topText = text[0]
        bottomText = if len(text) > 1: text[1] else: ""

      discard execShellCmd("convert ss1.png -font \"SemplicitaPro-Bold.otf\" -pointsize 19 -fill \"#1c1c1c\" -draw 'text 263,441 \"" & topText & "\"' " & $command.message.messageId & "-tmp")
      discard execShellCmd("convert " & $command.message.messageId & "-tmp" & " -font \"SemplicitaPro-Medium.otf\" -pointsize 14 -fill \"#1c1c1c\" -draw 'text 263,462 \"" & bottomText & "\"' " & $command.message.messageId)

      var replyId = 0
      if command.message.replyToMessage.isSome:
        replyId = command.message.replyToMessage.get.messageId
      discard await bot.sendPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId, replyToMessageId = replyId)
      removeFile($command.message.messageId)
      removeFile($command.message.messageId & "-tmp")

    of "ss2":
      discard deleteMessageEx(bot, command.message.chat, command.message)
      let
        text = multiReplace(toUpper(command.params), [("\'", ""), ("\"", "\\\"")])

      discard execShellCmd("convert ss2.png -font \"SemplicitaPro-Medium.otf\" -pointsize 30 -fill \"#483e25\" -draw 'text 266,455 \"" & text & "\"' " & $command.message.messageId)

      var replyId = 0
      if command.message.replyToMessage.isSome:
        replyId = command.message.replyToMessage.get.messageId
      discard await bot.sendPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId, replyToMessageId = replyId)
      removeFile($command.message.messageId)

    of "mi8":
      if command.message.replyToMessage.isSome and command.message.replyToMessage.get.photo.isSome:
        discard deleteMessageEx(bot, command.message.chat, command.message)

        let
          size = command.message.replyToMessage.get.photo.get[^1].width/3
          fileName = await downloadImage(command.message.replyToMessage.get.photo.get[^1])

        discard execShellCmd("convert " & fileName & " \\( mi8.png -resize " & $size & "x" & $size & " \\) -gravity southwest -geometry +10+10 -composite " & $command.message.messageId)

        var replyId = 0
        if command.message.replyToMessage.isSome:
          replyId = command.message.replyToMessage.get.messageId
        discard await bot.sendPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId, replyToMessageId = replyId)
        removeFile($command.message.messageId)
        removeFile(fileName)

    of "mi9":
      if command.message.replyToMessage.isSome and command.message.replyToMessage.get.photo.isSome:
        discard deleteMessageEx(bot, command.message.chat, command.message)
        let
          size = command.message.replyToMessage.get.photo.get[^1].width/3
          fileName = await downloadImage(command.message.replyToMessage.get.photo.get[^1])

        discard execShellCmd("convert " & fileName & " \\( mi9.png -resize " & $size & "x" & $size & " \\) -gravity southwest -geometry +10+10 -composite " & $command.message.messageId)

        var replyId = 0
        if command.message.replyToMessage.isSome:
          replyId = command.message.replyToMessage.get.messageId
        discard await bot.sendPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId, replyToMessageId = replyId)
        removeFile($command.message.messageId)
        removeFile(fileName)

    of "snap":
      if command.message.replyToMessage.isSome and command.message.replyToMessage.get.photo.isSome:
        discard deleteMessageEx(bot, command.message.chat, command.message)
        let
          width = command.message.replyToMessage.get.photo.get[^1].width
          height = command.message.replyToMessage.get.photo.get[^1].height
          fileName = await downloadImage(command.message.replyToMessage.get.photo.get[^1])

        discard execShellCmd("convert " & fileName & " -fill \"rgba(0, 0, 0, 0.45)\" -draw \"rectangle 0," & $int(round(height/2 - height/18)) & " " & $width & "," & $int(round(height/2 + height/18)) & "\" -pointsize 38 -fill white -gravity center -draw 'text 0,0 \"" & multiReplace(command.params, [("\'", ""), ("\"", "\\\"")]) & "\"' " & $command.message.messageId)

        var replyId = 0
        if command.message.replyToMessage.isSome:
          replyId = command.message.replyToMessage.get.messageId
        discard await bot.sendPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId, replyToMessageId = replyId)
        removeFile($command.message.messageId)
        removeFile(fileName)

    of "snapbot":
      if command.message.replyToMessage.isSome and command.message.replyToMessage.get.photo.isSome:
        discard deleteMessageEx(bot, command.message.chat, command.message)
        let
          width = command.message.replyToMessage.get.photo.get[^1].width
          height = command.message.replyToMessage.get.photo.get[^1].height
          fileName = await downloadImage(command.message.replyToMessage.get.photo.get[^1])

        discard execShellCmd("convert " & fileName & " -fill \"rgba(0, 0, 0, 0.45)\" -draw \"rectangle 0," & $int(round(float(height)*0.8 - height/18)) & " " & $width & "," & $int(round(float(height)*0.8 + height/18)) & "\" -pointsize 38 -fill white -gravity south -draw 'text 0,+" & $int(round(float(height)*0.2)-20.0) & " \"" & multiReplace(command.params, [("\'", ""), ("\"", "\\\"")]) & "\"' " & $command.message.messageId)

        var replyId = 0
        if command.message.replyToMessage.isSome:
          replyId = command.message.replyToMessage.get.messageId
        discard await bot.sendPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId, replyToMessageId = replyId)
        removeFile($command.message.messageId)
        removeFile(fileName)

    of "snaptop":
      if command.message.replyToMessage.isSome and command.message.replyToMessage.get.photo.isSome:
        discard deleteMessageEx(bot, command.message.chat, command.message)
        let
          width = command.message.replyToMessage.get.photo.get[^1].width
          height = command.message.replyToMessage.get.photo.get[^1].height
          fileName = await downloadImage(command.message.replyToMessage.get.photo.get[^1])

        discard execShellCmd("convert " & fileName & " -fill \"rgba(0, 0, 0, 0.45)\" -draw \"rectangle 0," & $int(round(float(height)*0.2 - height/18)) & " " & $width & "," & $int(round(float(height)*0.2 + height/18)) & "\" -pointsize 38 -fill white -gravity north -draw 'text 0,+" & $int(round(float(height)*0.2)-16.0) & " \"" & multiReplace(command.params, [("\'", ""), ("\"", "\\\"")]) & "\"' " & $command.message.messageId)

        var replyId = 0
        if command.message.replyToMessage.isSome:
          replyId = command.message.replyToMessage.get.messageId
        discard await bot.sendPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId, replyToMessageId = replyId)
        removeFile($command.message.messageId)
        removeFile(fileName)

    of "yomomma":
      discard deleteMessageEx(bot, command.message.chat, command.message)
      discard await bot.sendMessage(chatId, jokes.sample)

    of "twojastara":
      discard deleteMessageEx(bot, command.message.chat, command.message)
      discard await bot.sendMessage(chatId, jokesPl.sample)

    of "hypercam":
      if command.message.replyToMessage.get.video.isSome and command.message.replyToMessage.get.video.get.mimeType.isSome and command.message.replyToMessage.get.video.get.mimeType.get.startsWith("video"):
        let
          fileName = await downloadVideo(command.message.replyToMessage.get.video.get)

        discard deleteMessageEx(bot, command.message.chat, command.message)
        discard execShellCmd("timeout 20 ffmpeg -i  " & fileName & " -vf \"drawbox=x=0:y=0:w=260:h=22:color=white:t=max,drawtext=x=2:y=2:fontfile=fixedsys.ttf:fontsize=20:fontcolor=black:text='Unregistered HyperCam 2'\" " & $command.message.messageId & ".mp4")
        discard await bot.sendVideo(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId & ".mp4")
        removeFile($command.message.messageId & ".mp4")
        removeFile(fileName)


    of "nk":
      if command.message.replyToMessage.isSome and command.message.replyToMessage.get.photo.isSome:
        discard deleteMessageEx(bot, command.message.chat, command.message)


        let
          size = command.message.replyToMessage.get.photo.get[^1].width/3
          fileName = await downloadImage(command.message.replyToMessage.get.photo.get[^1])
          params = command.params.split(' ')
          orientation = params[0]

        var
          sizeRatio = 1.5

        if params.len >= 2:
          try:
            sizeRatio = parseFloat(params[1])
          except ValueError:
            discard

        let
          outputs = execProcess("/usr/bin/face_detection --cpus 2 " & fileName).strip().split('\n')

        debugEcho(orientation)
        debugEcho(sizeRatio)
        copyFile(fileName, $command.message.messageId)

        for unparsedOutput in outputs:
          let output = unparsedOutput.split(',')
          if output.len < 5:
            continue

          let
            faceOffsetRatioWidth = 1.297491039426523
            faceOffsetRatioHeight = 1.625454545454545
            width = float(parseInt(output[2]) - parseInt(output[4]))
            height = float(parseInt(output[3]) - parseInt(output[1]))
            faceWidth = width*faceOffsetRatioWidth
            faceHeight = faceWidth*1.234806629834254
            faceXOffset = if orientation == "left": int((faceWidth*1.1)-faceWidth) else: int(faceWidth-width)
            resizedYOffset = int(abs(height - faceHeight))
            x1 = parseInt(output[2])
            x2 = parseInt(output[4])
            y1 = parseInt(output[1])
            y2 = parseInt(output[3])

          discard execShellCmd("convert " & $command.message.messageId & " \\( papaj.png -resize " & $faceWidth & (if orientation == "left": " -flop" else: "") & " \\) -gravity northwest -geometry +" & $(x2-faceXOffset) & "+" & $(y1-resizedYOffset) & " -composite " & $command.message.messageId)

        var replyId = 0
        if command.message.replyToMessage.isSome:
          replyId = command.message.replyToMessage.get.messageId
        discard await bot.sendPhoto(chatId, "file://" & getCurrentDir() & "/" & $command.message.messageId, replyToMessageId = replyId)
        removeFile($command.message.messageId)
        removeFile(fileName)        

    of "help":
      discard deleteMessageEx(bot, command.message.chat, command.message)
      discard await bot.sendMessage(chatId, """
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
/snap /snaptop /snapbot - komendy do snapa
/tvp1 /tvp2 /tvp3 /tvp4 /tvp5 - generuj tvp
/ss1 /ss2 - generuj superstacje
/pis - billboard z pis
/yommoma - żart o twojej starej
/mi8 /mi9 - zdjęcie zriobione z mi8/mi9
/twojastara - żart o twojej starej
/hypercam - HyperCam na video
/koronachan, /korona, /korona-chan, /corona, /coronachan, /corona-chan - Info o korona-chan""")

    of "getCommands":
      discard deleteMessageEx(bot, command.message.chat, command.message)
      discard await bot.sendMessage(chatId, getCommands(false))
  discard

proc inlineHandler(b: Telebot, u: InlineQuery): Future[bool] {.async.} =
  debugEcho u.query
  try:
    case u.query:
      of "t":
        var results: seq[InlineQueryResultArticle]

        for command in db.getTextCommands():
          var res: InlineQueryResultArticle
          res.kind = "article"
          res.title = command[1]
          res.id = command[0]
          res.inputMessageContent = InputTextMessageContent(command[2]).some
          results.add(res)
        discard waitFor b.answerInlineQuery(u.id, results)
      of "a":
        var results: seq[InlineQueryResultCachedAudio]
        for command in db.getAudioCommands():
          var res: InlineQueryResultCachedAudio
          res.kind = "audio"
          res.audioFileId = command[2]
          res.id = command[0]
          results.add(res)
        discard waitFor b.answerInlineQuery(u.id, results)
      of "vi":
        var results: seq[InlineQueryResultCachedVideo]
        for command in db.getVideoCommands():
          var res: InlineQueryResultCachedVideo
          res.kind = "video"
          res.videoFileId = command[2]
          res.title = command[1]
          res.id = command[0]
          results.add(res)
        discard waitFor b.answerInlineQuery(u.id, results)
      of "v":
        var results: seq[InlineQueryResultCachedVoice]
        for command in db.getVoiceCommands():
          var res: InlineQueryResultCachedVoice
          res.kind = "voice"
          res.voiceFileId = command[2]
          res.title = command[1]
          res.id = command[0]
          results.add(res)
        discard waitFor b.answerInlineQuery(u.id, results)
      of "p":
        var results: seq[InlineQueryResultCachedPhoto]
        for command in db.getPhotoCommands():
          var res: InlineQueryResultCachedPhoto
          res.kind = "photo"
          res.photoFileId = command[2]
          res.id = command[0]
          results.add(res)
        discard waitFor b.answerInlineQuery(u.id, results)
      of "s":
        var results: seq[InlineQueryResultCachedSticker]
        for command in db.getStickerCommands():
          var res: InlineQueryResultCachedSticker
          res.kind = "sticker"
          res.stickerFileId = command[2]
          res.id = command[0]
          results.add(res)
        discard waitFor b.answerInlineQuery(u.id, results)
      of "f":
        var results: seq[InlineQueryResultCachedDocument]
        for command in db.getFileCommands():
          var res: InlineQueryResultCachedDocument
          res.kind = "document"
          res.documentFileId = command[2]
          res.title = command[1]
          res.id = command[0]
          results.add(res)
        discard waitFor b.answerInlineQuery(u.id, results)
  except IOError:
    echo getCurrentExceptionMsg()

proc updateHandler(b: Telebot, u: Update): Future[bool] {.async.} =
  if u.message.isSome:
    var response = u.message.get

    var chatName = ""
    if response.chat.title.isSome:
        chatName = response.chat.title.get
    addChatToStatistics(response.chat.id, chatName)

    if response.document.isSome and response.document.get.mimeType.isSome and response.document.get.mimeType.get == "video/webm" and isFeatureEnabled("webm", response.chat.id):
        let
          fileName = await downloadDocument(response.document.get)

        discard execShellCmd("timeout 20 ffmpeg -i  " & fileName & " " & $response.messageId & ".mp4")
        discard await b.sendVideo(u.message.get.chat.id, "file://" & getCurrentDir() & "/" & $response.messageId & ".mp4")
        removeFile($response.messageId & ".mp4")
        removeFile(fileName)

    if response.text.isSome and "inba" in response.text.get.toLower:
      let this_file = "file://" & getCurrentDir() & "/audio_2019-05-09_16-11-53.ogg"

      discard await b.sendVoice(u.message.get.chat.id, this_file, caption = "🎉 INBA")

proc templ(chatsCount: string, allCommands: string) {.html_templ.} =
  html(lang="en"):
    {. filters = nil .}
    "<meta charset=\"utf-8\">"
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1, shrink-to-fit=no\">"
    {. filters = escape_html() .}
    head:
      title: "Lenisław Statystyki"
      link(rel="stylesheet", href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css")
    body:
      {. filters = nil .}
      """
      <main role="main" class="container">
        <h1 class="mt-5">Statystyki</h1>
        <p class="lead">"""
      "Lenisław jest na " & chatsCount & " chatach."
      h1: "Lista komend"
      p: allCommands
      "</main>"
      script(src="https://code.jquery.com/jquery-3.3.1.slim.min.js")
      script(src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.7/umd/popper.min.js")
      script(src="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/js/bootstrap.min.js")

proc cb(req: Request) {.async.} =
  var
    ss = newStringStream()
    myTempl = newTempl()
  myTempl.chatsCount = getChatsCount()
  myTempl.allCommands = getCommands(true)
  myTempl.render(ss)
  ss.flush()
  await req.respond(Http200, ss.data)

setupDatabase()
randomize()

let server = newAsyncHttpServer()

asyncCheck server.serve(Port(2137), cb)

let bot = newTeleBot(API_KEY)

bot.onUpdate(updateHandler)
bot.onUnknownCommand(commandHandler)
bot.onInlineQuery(inlineHandler)
asyncCheck bot.pollAsync(timeout=300)

runForever()
