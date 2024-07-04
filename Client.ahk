#Include %A_ScriptDir%\resources
#Include WebSockets.ahk
#Include JSON.ahk
#Include FormData.ahk
#Include Gdip_All.ahk
#Include QueryPerformance.ahk
#Include <Console>

Class client {
	__New(intents) {
		this.events := {
			READY: [], GUILD_CREATE: [], GUILD_DELETE: [],
			GUILD_UPDATE: [], GUILD_MEMBER_ADD: [], GUILD_MEMBER_REMOVE: [],
			GUILD_MEMBER_UPDATE: [], GUILD_BAN_ADD: [], GUILD_BAN_REMOVE: [],
			CHANNEL_CREATE: [], CHANNEL_DELETE: [], CHANNEL_UPDATE: [],
			CHANNEL_PINS_UPDATE: [], MESSAGE_CREATE: [], MESSAGE_UPDATE: [],
			MESSAGE_DELETE: [], MESSAGE_REACTION_ADD: [], MESSAGE_REACTION_REMOVE: [],
			MESSAGE_REACTION_REMOVE_ALL: [], USER_UPDATE: [], PRESENCE_UPDATE: [],
			TYPING_START: [], VOICE_STATE_UPDATE: [], SHARD_RESUME: [],
			WARN: [], DEBUG: [], INTERACTION_CREATE: [], ERROR: [],
			SHARD_READY: [], SHARD_DISCONNECT: [], SHARD_RECONNECTING: [],
		}
		this.s := JSON.null
		this.intents := intents
		this.presence := { %"activities"%: [{ %"name"%: "Discord.ahk", %"type"%: 0
		}
		], %"status"%: "online", %"afk"%: JSON.false
		}
		this.ws := WebSocket("wss://gateway.discord.gg/", {
			message: (self, msg) => this.omsg(msg),
			disconnect: (self, code, reason) => MsgBox("Disconnected: " code " " reason)
		})
	}
	login(token) {
        this.BotToken := token
		this.ws.sendText(('{"op":2,"d":{"token":"' token '", "intents":' this.intents ', "properties":{"os":"windows","browser":"ahk","device":"ahk"}}}'))
        this.rest := REST(token)
	}
	omsg(msg) {
		data := JSON.parse(msg, true, false)
		switch data.op {
			case 10:
				this.heartbeatInterval := data.d.heartbeat_interval
				SetTimer(this.sendHeartbeat.bind(this), this.heartbeatInterval)
			case 0:
				this.s := data.s
				this.handleEvent(data)
		}
	}
	handleEvent(data) {
		switch data.t {
			case "READY":
				this.user := data.d.user
				this.sessionId := data.d.session_id
		}
		this.CallEvents(data.t, data.d)
	}
	sendHeartbeat(*) {
		this.ws.sendText('{"op":1,"d":' this.s '}')
	}
	on(event, function) {
		this.events.%event%.push({f:function, once: false})
	}
	once(event, function) {
		this.events.%event%.push({f:function, once: true})
	}
	waitFor(event, callback, timeout:=1000) {
		happened := false, args := []
		this.once(event, (a*) => (happened := true, args := a))
		s := QPC()
		loop {
			if happened
				return (callback(args*), true)
			if (QPC() - s) > timeout
				return false
		}
	}
	CallEvents(event, args*) {
		for i, e in this.events.%event% {
			(e.f)( args* )
			if e.once 
				this.events.%event%.RemoveAt(i)
		}
	}
	setPresence(presence) =>
		this.ws.sendText('{"op":3,"d":' JSON.stringify(presence) '}')
	__Delete() {
		this.ws.close()
	}
}
Class Interaction {
    __New(self, data) {
        this.startCounter := QPC(), this.data := data, this.client := self
    }
    reply(content) {
        contentType := "application/json"
        if !content.hasProp("data")
            content := {type:4,data: content}
        if content.data.hasProp("embeds")
            for i,j in content.data.embeds
                if j is EmbedBuilder
                    content.data.embeds[i] := j.embedObj
        if content.data.hasProp("files") {
            form := FormData()
            for i,j in content.data.files {
                if !j is AttachmentBuilder
                    throw Error("expected AttachmentBuilder")
                if j.isBitmap
                    form.AppendBitmap(j.file, j.fileName)
                else form.AppendFile(j.file, j.contentType)
                content.data.files[i] := j.attachmentName
            }
            form.AppendJSON("payload_json", content)
            contentType := form.contentType, body := form.data()
        }
        return (this.client.rest)("POST", "interactions/" this.data.id "/" this.data.token "/callback", {
            body: body ?? content,
            headers: { %"Content-Type"%: contentType }
        })
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
		DIRECT_MESSAGE_TYPING := 1 << 14,
		MESSAGE_CONTENT := 1 << 15,
		GUILD_SCHEDULED_EVENTS := 1 << 16
}
