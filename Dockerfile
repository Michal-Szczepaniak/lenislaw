FROM nimlang/nim:1.4.8-alpine
COPY . .
RUN nimble install -y emerald telebot
RUN nim c -d:release bot.nim
CMD ["./bot"]
