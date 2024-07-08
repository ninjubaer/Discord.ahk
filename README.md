# Discord.ahk
_An easy-to-use discord bot library for AutoHotkey v2.0+_
*****

### Installation:
Download the library from the [Github Repository](https://github.com/ninjubaer/discord.ahk)\
Download AutoHotkey v2 from [the official website](https://autohotkey.com/download/ahk-v2.exe)

*****

### Getting Started
install everything you need and place everything inside your lib folder
then include either `BOT.ahk` or `WEBHOOK.ahk` depending on what you need:
```ahk
#include lib\BOT.ahk
```
or
```ahk
#include lib\WEBHOOK.ahk
```

**To create a Webhook** you can do following:
```ahk
#include lib\WEBHOOK.ahk
webhook := WebHookBuilder("YOU_WEBHOOK_URL")
```
then you can simply send stuff through webhook like that:
```ahk
webhook.send({
    content: "Hello World!"
})
```
**To create a Bot** you can do it like this:
```ahk
#include lib\BOT.ahk
bot := Client(intents)
bot.once("READY", (*) => msgbox("logged in as " bot.user.username))
bot.login(BotToken)
```
replace the `intents` with the intents you want. You can view all intents in the Intents Class that is included in the Client.ahk file  
and replace the `BotToken` with your own Bot Token. Make sure you dont put your BotToken in any files that are visible to the public

this will also create a REST client which you can access with `bot.rest` 


## WebHookBuilder
_methods and properties_

**Methods**
```
(WebHookBuilder) __New(webhookURL)       creates a new WebHookBuilder object
(WebHookBuilder) Call(method, options)   performs an http request to your WebHook url
(WebHookBuilder) send(obj)               sends the content of the object to your webhook
```
**Properties**
```
(WebHookBuilder) webhookURL              holds the webhook url
```

## Client
_methods and properties_

**Methods**
```
(Client) __New(intents)                     creates a new client
(Client) login(token)                       logs in to the client
(Client) omsg(msg)                          onMessage event methods, not meant to be used by the user
(Client) handleEvent(data)                  gets called if omsg's op code is 0 and an event is included
(Client) sendHeartbeat(*)                   heartbeat is handled by the library
(Client) on(event, function)                appends an event to the given events callback list
(Client) once(event, function)              appends an event to the given events callback list but only triggers once
(Client) waitFor(event, callback, timeout)  waits for an event for a given amount of time
(Client) setPresence(presence)              sets the bots presence
```

**Properties**
```
(Client) s                  holds the last sequence number received by the client
(Client) intents            holds the intents as integer
(Client) presence           holds the presence as an object
(Client) ws                 holds the WebSocket object
(Client) BotToken           holds the token of the bot, added once logged in with Client.login(BotToken)
(Client) rest               holds the REST object of the client with version 10
(Client) heartbeatInterval  holds the heartbeat interval of the session
(Client) user               holds the user object received by "READY" event
(Client) events             holds an object of all events where each of those has an array of callbacks
```