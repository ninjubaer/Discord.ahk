#Include %A_ScriptDir%\resources
#Include WebSockets.ahk
#Include JSON.ahk
#Include FormData.ahk
#Include Gdip_All.ahk

#Include <Console>

Class client {
    static events := ["READY", "MESSAGE_CREATE", "MESSAGE_UPDATE", "MESSAGE_DELETE", "MESSAGE_DELETE_BULK", "MESSAGE_REACTION_ADD", "MESSAGE_REACTION_REMOVE", "MESSAGE_REACTION_REMOVE_ALL", "MESSAGE_REACTION_REMOVE_EMOJI", "CHANNEL_CREATE", "CHANNEL_UPDATE", "CHANNEL_DELETE", "CHANNEL_PINS_UPDATE", "GUILD_CREATE", "GUILD_UPDATE", "GUILD_DELETE", "GUILD_BAN_ADD", "GUILD_BAN_REMOVE", "GUILD_EMOJIS_UPDATE", "GUILD_INTEGRATIONS_UPDATE", "GUILD_MEMBER_ADD", "GUILD_MEMBER_REMOVE", "GUILD_MEMBER_UPDATE", "GUILD_MEMBERS_CHUNK", "GUILD_ROLE_CREATE", "GUILD_ROLE_UPDATE", "GUILD_ROLE_DELETE", "INTEGRATION_CREATE", "INTEGRATION_UPDATE", "INTEGRATION_DELETE", "INTERACTION_CREATE", "INVITE_CREATE", "INVITE_DELETE", "MESSAGE_ACK", "PRESENCE_UPDATE", "TYPING_START", "USER_UPDATE", "VOICE_STATE_UPDATE", "VOICE_SERVER_UPDATE", "WEBHOOKS_UPDATE"]
    __New(intents) {
        for i in client.events
            this.%i% := (*)=>""
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
            message: (self, msg) => this.onMessage(msg),
            disconnect: (self, code, reason) => MsgBox("Disconnected: " code " " reason)
        })
    }
    login(token) {
        this.ws.sendText(('{"op":2,"d":{"token":"' token '", "intents":' this.intents ', "properties":{"os":"windows","browser":"ahk","device":"ahk"}}}'))
    }
    onMessage(msg) {
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
                Console.log("Logged in as " this.user.username " (id: " this.user.id ")")
        }
    }
    sendHeartbeat(*) {
        this.ws.sendText('{"op":1,"d":' (this.hasProp("sessionId") ? this.sessionId : 'null') '}')
    }
    __Delete() {
        this.ws.close()
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

c := client(1)
c.login("MTA2OTYzNzk3ODExNDI0MDYxMg.GvFwIp.yoOUb-U6qKjw_q2jMYn6QD1mQRgQ_TlyjBLuD0")