#Include resources\WebSockets.ahk
#Include resources\JSON.ahk
Class client {
    __New(intents) {
        this.intents := intents
        this.presence := {
            %"activities"%: [
                {
                    %"name"%: "Discord.ahk",
                    %"type"%: 0
                }
            ],
            %"status"%: "online",
            %"afk"%: false
        }
        this.ws := WebSocket("wss://gateway.discord.gg/", {
            message: (self, msg) => this.onMessage.call(this,msg),
            disconnect: (self, code, reason) => MsgBox("Disconnected: " code " " reason)
        })
    }
    login(token) {
        this.ws.sendText(('{"op":2,"d":{"token":"' token '", "intents":' this.intents ', "properties":{"$os":"windows","$browser":"ahk","$device":"ahk"}}'))
    }
    onMessage(msg) {
        msgbox msg
        data := JSON.parse(msg, true, false)
        switch data.op {
            case 10:
                this.heartbeatInterval := data.d.heartbeat_interval
                SetTimer(this.sendHeartbeat.bind(this), this.heartbeatInterval)
            case 0:
                this.handleEvent(data)
        }
    }
    handleEvent(data) {
        switch data.t {
            case "READY":
                this.user := data.d.user
                this.sessionId := data.d.session_id
                msgbox this.user.id
        }
    }
    sendHeartbeat(*) {
        this.ws.sendText('{"op":1,"d":null}')
    }
}
Class presence {
    static playing := 0,
    streaming := 1,
    listening := 2,
    watching := 3
}
Class intents {
    static GUILDS := 1 << 0,
    GUILD_MEMBERS := 1 << 1,
    GUILD_BANS := 1 << 2,
    GUILD_EMOJIS_AND_STICKERS := 1 << 3,
    GUILD_INTEGRATIONS := 1 << 4,
    GUILD_WEBHOOKS := 1 << 5,
    GUILD_INVITES := 1 << 6,
    GUILD_VOICE_STATES := 1 << 7,
    GUILD_PRESENCES := 1 << 8,
    GUILD_MESSAGES := 1 << 9,
    GUILD_MESSAGE_REACTIONS := 1 << 10,
    GUILD_MESSAGE_TYPING := 1 << 11,
    DIRECT_MESSAGES := 1 << 12,
    DIRECT_MESSAGE_REACTIONS := 1 << 13,
    DIRECT_MESSAGE_TYPING := 1 << 14
    MESSAGE_CONTENT := 1 << 15,
    GUILD_SCHEDULED_EVENTS := 1 << 16
}

#SingleInstance Force
Persistent

c := client(intents.GUILDS | intents.GUILD_MEMBERS | intents.GUILD_MESSAGES)
c.login("MTA2OTYzNzk3ODExNDI0MDYxMg.GvFwIp.yoOUb-U6qKjw_q2jMYn6QD1mQRgQ_TlyjBLuD0")