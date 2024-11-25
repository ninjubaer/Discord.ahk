#Include .\..\natromacro\lib\JSON.ahk
Class Discord {
    Class Bot {
        __user:={}, __intents:=0, __token := "", s:="null", events:={}
        __New(intents) {
            if !IsInteger(intents)
                throw TypeError("Expected an integer but received a " Type(intents))
            this.__intents := intents
            this.__ws := Discord.WebSocket('wss://gateway.discord.gg/', {
                message: (self, message) => this.__omsg(message),
                close: (*)=>MsgBox("Close")
            })
        }
        Intents=>this.__intents
        User=>this.__user
        Token=>this.__token
        login(token) {
            if !token is String
                throw TypeError("Invalid token")
            if !RegExMatch(token, 'i)^[\w-.]{50,83}$')
                throw TypeError("Invalid token")
            this.__token := token
            this.__ws.sendText(('{"op":2,"d":{"token":"' token '", "intents":' this.intents ', "properties":{"os":"windows","browser":"ahk","device":"ahk"}}}'))
            this.rest := Discord.Bot.REST(token)
        }
        __omsg(data) {
            data := JSON.parse(data, true, false)
            switch data.op {
                case 10:
                    this.heartbeat_interval := data.d.heartbeat_interval
                    SetTimer((*)=>this.__ws.sendText('{"op":1,"d":' this.s '}'), this.heartbeat_interval)
                case 0:
                    switch data.t {
                        case "READY":
                            this.__user := data.d.user
                    }
                    if !this.events.HasProp(data.t)
                        return
                    for i, j in this.events.%data.t%
                        j.callback(this, j, data.d)

            }
        }
        /**
         * add an event listener
         * @callback (bot, event, data)
         * @param {String} event one of the Discord.Event.EventEnum
         * @param {Func} callback 
         */
        on(event, callback) {
            event := Discord.Event(event, callback, this.__intents)
            if !this.events.HasProp(event.name)
                this.events.%event.name% := []
            this.events.%event.name%.Push(event)
            return event
        }
        getUser(id) => this.rest.getUser(id)
        Class REST {
            token := "", version := 'v10',baseURL := 'https://discord.com/api/v10', headers := {Authorization: "", %"User-Agent"%: "Discord.ahk by ninju"}, whr := ComObject("WinHttp.WinHttpRequest.5.1")
            __New(token, version?) {
                if !token is String
                    throw TypeError("Expected a string but received a " Type(token))
                if !RegExMatch(token, 'i)^[\w-.]{50,83}$')
                    throw TypeError("Invalid token")
                this.token := token, this.headers.Authorization := "Bot " token
                if IsSet(version) {
                    if !version is String
                        throw TypeError("Expected a string but received a " Type(version))
                    if !RegExMatch(version, 'i)^v\d+$')
                        throw TypeError("Invalid version identifier")
                    this.version := version, this.endpoint := 'https://discord.com/api/' version
                }
            }
            Call(method, endpoint, data?, headers?) {
                if !method is String
                    throw TypeError('Expected a String but got a ' Type(method))
                if !((method:=StrUpper(method)) ~= '^(GET|POST|PUT|PATCH|DELETE)$')
                    throw TypeError('Invalid method')
                if !endpoint is String
                    throw TypeError('Expected a String but got a ' Type(endpoint))
                if !RegExMatch(endpoint, 'i)^/[^\s]+/?$')
                    throw TypeError('Invalid endpoint')
                if IsSet(data) && !(data is String || data is ComObjArray)
                    throw TypeError('Expected a String or a ComObjArray but got a ' Type(data))

                this.whr.Open(method, this.baseURL (SubStr(endpoint,1,1) = '/' ? endpoint : '/' endpoint), false)
                for i, j in this.headers.OwnProps()
                    this.whr.setRequestHeader(i, j)
                if IsSet(headers) {
                    if !(headers is Object || headers is Map)
                        throw TypeError('Expected an Object or a Map but got a ' Type(headers))
                    for i, j in headers is Map ? headers : headers.OwnProps()
                        this.whr.setRequestHeader(i, j)
                }
                this.whr.option[9] := 2720
                this.whr.Send(data?)
                return this.whr.ResponseText                
            }
            getUser(id) {
                if !(id is String || id is Integer)
                    throw TypeError("Expected a string or an integer but received a " Type(id))
                if !RegExMatch(id, 'i)^\d{17,20}$')
                    throw TypeError("Invalid user id")
                return Discord.User(JSON.parse(this('GET', '/users/' id),,false))

            }
            sendMessage(channel, message) {
                if !(channel is String || channel is Integer)
                    throw TypeError("Expected a string or an integer but received a " Type(channel))
                if !RegExMatch(channel, 'i)^\d{17,20}$')
                    throw TypeError("Invalid channel id")
                if !message is Discord.Message
                    throw TypeError("Expected a Discord.Message but received a " Type(message))
                if message.attachments.length = 0 {
                    out := JSON.parse(this('POST', '/channels/' channel '/messages', JSON.stringify(message.obj), {%"Content-Type"%: "application/json"}),,false)
                    if !out.HasProp('id')
                        return out
                    message.id := out.id
                    message.channel_id := out.channel_id
                    return message
                }
                fd := Discord.FormData()
                fd.append('payload_json', s:=JSON.stringify(message.obj), StrLen(s), "application/json")
                for i, j in message.attachments {
                    fd.append('files[' i-1 ']', j.ptr, j.size,j.contentType, j.filename)
                }
                out := JSON.parse(this('POST', '/channels/' channel '/messages', fd.data, {%"Content-Type"%: fd.contentType}),,false)
                if !out.HasProp('id')
                    return out
                message.id := out.id
                message.channel_id := out.channel_id
                return message
            }
            deleteMessage(channel, message) {
                if !(channel is String || channel is Integer)
                    throw TypeError("Expected a string or an integer but received a " Type(channel))
                if !RegExMatch(channel, 'i)^\d{17,20}$')
                    throw TypeError("Invalid channel id")
                if !(message is Discord.Message || message is String || message is Integer)
                    throw TypeError("Expected a Discord.Message, a string or an integer but received a " Type(message))
                if message is Discord.Message {
                    if !message.id
                        throw TypeError("Message must be sent before deleting")
                    message := message.id
                }
                if !RegExMatch(message, 'i)^\d{17,20}$')
                    throw TypeError("Invalid message id")
                return this('DELETE', '/channels/' channel '/messages/' message)
            }
        }

    }
    Class User {
        class Flags {
            static STAFF := 1 << 0
            static PARTNER := 1 << 1
            static HYPESQUAD := 1 << 2
            static BUGHUNTER_LEVEL_1 := 1 << 3
            static HYPESQUAD_ONLINE_HOUSE_1	 := 1 << 6 ; HypeSquad Bravery
            static HYPESQUAD_ONLINE_HOUSE_2	 := 1 << 7 ; HypeSquad Brilliance
            static HYPESQUAD_ONLINE_HOUSE_3	 := 1 << 8 ; HypeSquad Balance
            static PREMIUM_EARLY_SUPPORTER := 1 << 9
            static TEAM_PSEUDO_USER := 1 << 10
            static BUG_HUNTER_LEVEL_2 := 1 << 14
            static VERIFIED_BOT := 1 << 16
            static VERIFIED_DEVELOPER := 1 << 17
            static CERTIFIED_MODERATOR := 1 << 18
            static BOT_HTTP_INTERACTIONS := 1 << 19
            static ACTIVE_DEVELOPER := 1 << 22
        }
        class PremiumTypes {
            static NONE := 0
            static NITRO_CLASSIC := 1
            static NITRO := 2
            static NITRO_BASIC := 3
        }
        class AvatarDecoration {
            asset:="", sku_id:="", expires_at:=""
        }
        class Clan {
            identity_guild_id:="",identity_enabled:=0, tag:="", badge := ""
        }
        __private:={__id:0,__username:"",__discriminator:"",__avatar:"",__flags:0,__banner:"",__accent_color:0,__public_flags:0,__avatar_decoration_data:0, __banner_color: 0, __clan: 0, __bot : 0}
        id => this.__private.__id
        username => this.__private.__username
        discriminator => this.__private.__discriminator
        avatar => this.__private.__avatar
        flags => this.__private.__flags
        banner => this.__private.__banner
        accent_color => this.__private.__accent_color
        premium_type => this.__private.__premium_type
        public_flags => this.__private.__public_flags
        avatar_decoration_data => this.__private.__avatar_decoration_data
        banner_color => this.__private.__banner_color
        clan => this.__private.__clan
        bot => this.__private.__bot
        /**
         * a Discord User object retrieved from /users/{id} 
         * @param {Object} obj a Discord User object retrieved from /users/{id} 
         */
        __New(obj) {
            if Type(obj) != "Object"
                Throw TypeError("Expected an object but received a " Type(obj))
            obj.bot := obj.HasProp("bot") ? obj.bot : 0
            for i, j in obj.OwnProps()
                if this.__private.HasProp("__" i)
                    this.__private.%("__" i)% := j
            for i,j in this.__private.OwnProps()
                if !obj.HasProp(SubStr(i, 3))
                    Throw TypeError("Missing property " i)
        }
    }
/*     Class Channel {

    } */
    Class Message {
        obj := {}, attachments:=[], id:=0, channel_id:=0
        __New(obj) {
            if !Type(obj) = "Object"
                throw TypeError("Expected an object but received a " Type(obj))
            for i, j in obj.OwnProps()
                if !(i = "attachments" || i = "embeds" || i = "content" || i = "components")
                    throw TypeError("Invalid property " i)

            if obj.HasProp("embeds") {
                this.obj.embeds := []
                for i, j in obj.embeds {
                    if !j is Discord.Embed
                        throw TypeError("Expected a Discord.Embed but received a " Type(j))
                    this.obj.embeds.Push(j.embed)
                    for k, l in j.mpfd
                        this.updateAttachments(l)
                }
            }
            if obj.HasProp("attachments") {
                this.obj.attachments := []
                for i,j in obj.attachments {
                    if !j is Discord.Attachment
                        throw TypeError("Expected a Discord.Attachment but received a " Type(j))
                    this.updateAttachments(j)
                    this.obj.attachments.Push({filename: j.filename, url: "attachment://" j.filename, id: 0, description: j.description})
                }
            }
            if obj.HasProp("content") {
                if !obj.content is String
                    throw TypeError("Expected a string but received a " Type(obj.content))
                this.obj.content := obj.content
            }
            if obj.HasProp("components") {
                this.obj.components := []
                for i,j in obj.components {
                    if !j is Discord.Component
                        throw TypeError("Expected a Discord.Component but received a " Type(j))
                    this.obj.components.Push(j)
                }
            }
        }
        updateAttachments(attachment) {
            if !attachment is Discord.Attachment
                throw TypeError("Expected a Discord.Attachment but received a " Type(attachment))
            for i, j in this.attachments {
                if attachment = j
                    return
                if j.filename = attachment.filename
                    throw TypeError("Can't have two attachments with the same filename")
            }
            this.attachments.Push(attachment)
        }
        send(REST, channel) {
            if !REST is Discord.Bot.REST
                throw TypeError("Expected a Discord.Bot.REST but received a " Type(REST))
            if !channel is String
                throw TypeError("Expected a string but received a " Type(channel))
            if !RegExMatch(channel, 'i)^\d{17,20}$')
                throw TypeError("Invalid channel id")
            return REST.sendMessage(channel, this)
        }
        edit(REST, obj) {
            if !REST is Discord.Bot.REST
                throw TypeError("Expected a Discord.Bot.REST but received a " Type(REST))
            if !this.id || !this.channel_id
                throw TypeError("Message must be sent before editing")
            if !obj is Object
                throw TypeError("Expected an object but received a " Type(obj))
            this.obj.content := '', this.obj.embeds := [], this.obj.attachments := [], this.obj.components := [], this.attachments := []
            if obj.HasProp("content") {
                if !obj.content is String
                    throw TypeError("Expected a string but received a " Type(obj.content))
                this.obj.content := obj.content
            }
            if obj.HasProp("embeds") {
                this.obj.embeds := []
                for i, j in obj.embeds {
                    if !j is Discord.Embed
                        throw TypeError("Expected a Discord.Embed but received a " Type(j))
                    this.obj.embeds.Push(j.embed)
                    for k, l in j.mpfd
                        this.updateAttachments(l)
                }
            }
            if obj.HasProp("attachments") {
                this.obj.attachments := []
                for i,j in obj.attachments {
                    if !j is Discord.Attachment
                        throw TypeError("Expected a Discord.Attachment but received a " Type(j))
                    this.updateAttachments(j)
                    this.obj.attachments.Push({filename: j.filename, url: "attachment://" j.filename, id: 0, description: j.description})
                }
            }
            if obj.HasProp("components") {
                this.obj.components := []
                for i,j in obj.components {
                    if !j is Discord.Component
                        throw TypeError("Expected a Discord.Component but received a " Type(j))
                    this.obj.components.Push(j)
                }
            }
            return REST("PATCH", "/channels/" this.channel_id "/messages/" this.id, JSON.stringify(this.obj), {%"Content-Type"%: "application/json"})
        }
        delete(REST) {
            if !REST is Discord.Bot.REST
                throw TypeError("Expected a Discord.Bot.REST but received a " Type(REST))
            if !this.id || !this.channel_id
                throw TypeError("Message must be sent before deleting")
            return REST.deleteMessage(this.channel_id, this.id)
        }
    }
    Class Embed {
        embed := {}, mpfd := []
        setTitle(title) {
            if !title is String
                throw TypeError("Expected a string but received a " Type(title))
            if StrLen(title) > 256
                throw TypeError("Title must be less than 256 characters")
            this.embed.title := title
            return this
        }
        setDescription(description) {
            if !description is String
                throw TypeError("Expected a string but received a " Type(description))
            if StrLen(description) > 4096
                throw TypeError("Description must be less than 4096 characters")
            this.embed.description := description
            return this
        }
        setUrl(url) {
            if !url is String
                throw TypeError("Expected a string but received a " Type(url))
            if !RegExMatch(url, 'i)^https?://[^\s]+\.\w{2,6}[^\s]*$')
                throw TypeError("Invalid url")
            this.embed.url := url
            return this
        }
        setTimestamp(timestamp?) {
            if IsSet(timestamp) {
                if !timestamp is Discord.TimeStamp
                    throw TypeError("Expected a Discord.TimeStamp but received a " Type(timestamp))
            }
            else {
                timestamp := Discord.TimeStamp.Now()
            }
            this.embed.timestamp := timestamp.timestamp
            return this
        }
        setColor(color) {
            if (color is Integer) {
                if (color < 0 || color > 0xFFFFFF)
                    throw TypeError("Invalid color")
            }
            else if (color is String) {
                if RegExMatch(color, 'i)^(#|0x)([0-9A-F]{6})$', &rmi)
                    color := Integer("0x" rmi.2)
                else throw TypeError("Invalid color")
            }
            else throw TypeError("Invalid color")
            this.embed.color := color
            return this
        }
        setFooter(text, icon_url?) {
            if !text is String
                throw TypeError("Expected a string but received a " Type(text))
            if StrLen(text) > 2048
                throw TypeError("Text must be less than 2048 characters")
            if IsSet(icon_url) {
                if !(icon_url is String || icon_url is Discord.Attachment)
                    throw TypeError("Expected an URL or Discord.Attachment but received a " Type(icon_url))
                if icon_url is String {
                    if !RegExMatch(icon_url, 'i)^https?://[^\s]+\.\w{2,6}[^\s]*$')
                        throw TypeError("Invalid url")
                }
                else {
                    this.mpfd.Push(icon_url)
                    icon_url := "attachment://" icon_url.filename
                }
                this.embed.footer := {text: text, icon_url: icon_url}
                return this
            }
            this.embed.footer := {text: text}
            return this
        }
        setImage(url) {
            if !(url is String || url is Discord.Attachment)
                throw TypeError("Expected an URL or Discord.Attachment but received a " Type(url))
            if url is String {
                if !RegExMatch(url, 'i)^https?://[^\s]+\.\w{2,6}[^\s]*$')
                    throw TypeError("Invalid url")
            }
            else {
                this.mpfd.Push(url)
                url := "attachment://" url.filename
            }
            this.embed.image := {url: url}
            return this
        }
        setThumbnail(url) {
            if !(url is String || url is Discord.Attachment)
                throw TypeError("Expected an URL or Discord.Attachment but received a " Type(url))
            if url is String {
                if !RegExMatch(url, 'i)^https?://[^\s]+\.\w{2,6}[^\s]*$')
                    throw TypeError("Invalid url")
            }
            else {
                this.mpfd.Push(url)
                url := "attachment://" url.filename
            }
            this.embed.thumbnail := {url: url}
            return this
        }
        setAuthor(name, url?, icon_url?) {
            if !name is String
                throw TypeError("Expected a string but received a " Type(name))
            if StrLen(name) > 256
                throw TypeError("Name must be less than 256 characters")
            if IsSet(url) {
                if !url is String
                    throw TypeError("Expected a string but received a " Type(url))
                if !RegExMatch(url, 'i)^https?://[^\s]+\.\w{2,6}[^\s]*$')
                    throw TypeError("Invalid url")
            }
            if IsSet(icon_url) {
                if !(icon_url is String || icon_url is Discord.Attachment)
                    throw TypeError("Expected a string or a Discord.Attachment but received a " Type(icon_url))
                if icon_url is String {
                    if !RegExMatch(icon_url, 'i)^https?://[^\s]+\.\w{2,6}[^\s]*$')
                        throw TypeError("Invalid url")
                }
                else {
                    this.mpfd.Push(icon_url)
                    icon_url := "attachment://" icon_url.filename
                }
            }
            this.embed.author := {name: name}
            if IsSet(url)
                this.embed.author.url := url
            if IsSet(icon_url)
                this.embed.author.icon_url := icon_url
            return this
        }
        addField(name, value, inline := false) {
            if !name is String
                throw TypeError("Expected a string but received a " Type(name))
            if !value is String
                throw TypeError("Expected a string but received a " Type(value))
            if StrLen(name) > 256
                throw TypeError("Name must be less than 256 characters")
            if StrLen(value) > 1024
                throw TypeError("Value must be less than 1024 characters")
            if this.embed.fields.MaxIndex() >= 25
                throw TypeError("Fields limit reached")
            this.embed.fields.Push({name: name, value: value, inline: JSON.false})
            return this
        }
    }
    Class TimeStamp {
        static Call(timestamp) {
            if !timestamp is String
                throw TypeError("Expected a string but received a " Type(timestamp))
            if RegExMatch(timestamp, 'i)^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{3}Z$')
                return {base: Discord.TimeStamp.Prototype, timestamp: timestamp}
            else if RegExMatch(timestamp, 'i)^\d{14}')
                return {base: Discord.TimeStamp.Prototype, timestamp: FormatTime(timestamp, "yyyy-MM-ddTHH:mm:ss.000Z")}
            else
                throw TypeError("Invalid timestamp")
        }
        Class Now extends Discord.TimeStamp {
            static Call() {
                now := A_Now
                return {base: Discord.TimeStamp.Prototype, timestamp: FormatTime(now, "yyyy-MM-ddTHH:mm:ss.000Z")}
            }
        }
    }
    Class Reaction {

    }
    Class Role {

    }
    Class Guild {

    }
    Class Command {
        static CommandEnum := {
            SUB_COMMAND: 1,
            SUB_COMMAND_GROUP: 2,
            STRING: 3,
            INTEGER: 4,
            BOOLEAN: 5,
            USER: 6,
            CHANNEL: 7,
            ROLE: 8,
            MENTIONABLE: 9,
            NUMBER: 10
        }
        guild_id := 0
        __New(name, description, guild_id?) {
            if IsSet(guild_id) {
                this.guild_id := guild_id
            }
            this.command := {name: name, description: description}
        }
        addStringOption() {
            if !this.command.hasProp('options')
                this.command.options := [{type:3}]
            else
                this.command.options.push({type:3})
            return Discord.Command.Option()
        }
        addIntegerOption() {

        }
        addBooleanOption() {

        }

        class Option {

        }
        class SUB_COMMAND {

        }
        class SUB_COMMAND_GROUP {

        }
    }
    Class Event {
        static EventEnum := {
            ;* GUILDS
            GUILD_CREATE: Discord.Intents.GUILDS,
            GUILD_UPDATE: Discord.Intents.GUILDS,
            GUILD_DELETE: Discord.Intents.GUILDS,
            GUILD_ROLE_CREATE: Discord.Intents.GUILDS,
            GUILD_ROLE_UPDATE: Discord.Intents.GUILDS,
            GUILD_ROLE_DELETE: Discord.Intents.GUILDS,
            CHANNEL_CREATE: Discord.Intents.GUILDS,
            CHANNEL_UPDATE: Discord.Intents.GUILDS,
            CHANNEL_DELETE: Discord.Intents.GUILDS,
            CHANNEL_PINS_UPDATE: Discord.Intents.GUILDS,
            THREAD_CREATE: Discord.Intents.GUILDS,
            THREAD_UPDATE: Discord.Intents.GUILDS,
            THREAD_DELETE: Discord.Intents.GUILDS,
            THREAD_LIST_SYNC: Discord.Intents.GUILDS,
            THREAD_MEMBER_UPDATE: Discord.Intents.GUILDS,
            THREAD_MEMBERS_UPDATE: Discord.Intents.GUILDS,
            STAGE_INSTANCE_CREATE: Discord.Intents.GUILDS,
            STAGE_INSTANCE_UPDATE: Discord.Intents.GUILDS,
            STAGE_INSTANCE_DELETE: Discord.Intents.GUILDS,
        
            ;* GUILD_MEMBERS
            GUILD_MEMBER_ADD: Discord.Intents.GUILD_MEMBERS,
            GUILD_MEMBER_UPDATE: Discord.Intents.GUILD_MEMBERS,
            GUILD_MEMBER_REMOVE: Discord.Intents.GUILD_MEMBERS,
            THREAD_MEMBERS_UPDATE: Discord.Intents.GUILD_MEMBERS,
        
            ;* GUILD_MODERATION
            GUILD_AUDIT_LOG_ENTRY_CREATE: Discord.Intents.GUILD_MODERATION,
            GUILD_BAN_ADD: Discord.Intents.GUILD_MODERATION,
            GUILD_BAN_REMOVE: Discord.Intents.GUILD_MODERATION,
        
            ;* GUILD_EXPRESSIONS
            GUILD_EMOJIS_UPDATE: Discord.Intents.GUILD_EXPRESSIONS,
            GUILD_STICKERS_UPDATE: Discord.Intents.GUILD_EXPRESSIONS,
            GUILD_SOUNDBOARD_SOUND_CREATE: Discord.Intents.GUILD_EXPRESSIONS,
            GUILD_SOUNDBOARD_SOUND_UPDATE: Discord.Intents.GUILD_EXPRESSIONS,
            GUILD_SOUNDBOARD_SOUND_DELETE: Discord.Intents.GUILD_EXPRESSIONS,
            GUILD_SOUNDBOARD_SOUNDS_UPDATE: Discord.Intents.GUILD_EXPRESSIONS,
        
            ;* GUILD_INTEGRATIONS
            GUILD_INTEGRATIONS_UPDATE: Discord.Intents.GUILD_INTEGRATIONS,
            INTEGRATION_CREATE: Discord.Intents.GUILD_INTEGRATIONS,
            INTEGRATION_UPDATE: Discord.Intents.GUILD_INTEGRATIONS,
            INTEGRATION_DELETE: Discord.Intents.GUILD_INTEGRATIONS,
        
            ;* GUILD_WEBHOOKS
            WEBHOOKS_UPDATE: Discord.Intents.GUILD_WEBHOOKS,
        
            ;* GUILD_INVITES
            INVITE_CREATE: Discord.Intents.GUILD_INVITES,
            INVITE_DELETE: Discord.Intents.GUILD_INVITES,
        
            ;* GUILD_VOICE_STATES
            VOICE_CHANNEL_EFFECT_SEND: Discord.Intents.GUILD_VOICE_STATES,
            VOICE_STATE_UPDATE: Discord.Intents.GUILD_VOICE_STATES,
        
            ;* GUILD_PRESENCES
            PRESENCE_UPDATE: Discord.Intents.GUILD_PRESENCES,
        
            ;* GUILD_MESSAGES
            MESSAGE_CREATE: Discord.Intents.GUILD_MESSAGES,
            MESSAGE_UPDATE: Discord.Intents.GUILD_MESSAGES,
            MESSAGE_DELETE: Discord.Intents.GUILD_MESSAGES,
            MESSAGE_DELETE_BULK: Discord.Intents.GUILD_MESSAGES,
        
            ;* GUILD_MESSAGE_REACTIONS
            MESSAGE_REACTION_ADD: Discord.Intents.GUILD_MESSAGE_REACTIONS,
            MESSAGE_REACTION_REMOVE: Discord.Intents.GUILD_MESSAGE_REACTIONS,
            MESSAGE_REACTION_REMOVE_ALL: Discord.Intents.GUILD_MESSAGE_REACTIONS,
            MESSAGE_REACTION_REMOVE_EMOJI: Discord.Intents.GUILD_MESSAGE_REACTIONS,
        
            ;* GUILD_MESSAGE_TYPING
            TYPING_START: Discord.Intents.GUILD_MESSAGE_TYPING,
        
            ;* DIRECT_MESSAGES
            DIRECT_MESSAGE_CREATE: Discord.Intents.DIRECT_MESSAGES,
            DIRECT_MESSAGE_UPDATE: Discord.Intents.DIRECT_MESSAGES,
            DIRECT_MESSAGE_DELETE: Discord.Intents.DIRECT_MESSAGES,
            DIRECT_CHANNEL_PINS_UPDATE: Discord.Intents.DIRECT_MESSAGES,
        
            ;* DIRECT_MESSAGE_REACTIONS
            DIRECT_MESSAGE_REACTION_ADD: Discord.Intents.DIRECT_MESSAGE_REACTIONS,
            DIRECT_MESSAGE_REACTION_REMOVE: Discord.Intents.DIRECT_MESSAGE_REACTIONS,
            DIRECT_MESSAGE_REACTION_REMOVE_ALL: Discord.Intents.DIRECT_MESSAGE_REACTIONS,
            DIRECT_MESSAGE_REACTION_REMOVE_EMOJI: Discord.Intents.DIRECT_MESSAGE_REACTIONS,
        
            ;* DIRECT_MESSAGE_TYPING
            DIRECT_TYPING_START: Discord.Intents.DIRECT_MESSAGE_TYPING,
        
            ;* MESSAGE_CONTENT
            MESSAGE_CONTENT: Discord.Intents.MESSAGE_CONTENT,
        
            ;* GUILD_SCHEDULED_EVENTS
            GUILD_SCHEDULED_EVENT_CREATE: Discord.Intents.GUILD_SCHEDULED_EVENTS,
            GUILD_SCHEDULED_EVENT_UPDATE: Discord.Intents.GUILD_SCHEDULED_EVENTS,
            GUILD_SCHEDULED_EVENT_DELETE: Discord.Intents.GUILD_SCHEDULED_EVENTS,
            GUILD_SCHEDULED_EVENT_USER_ADD: Discord.Intents.GUILD_SCHEDULED_EVENTS,
            GUILD_SCHEDULED_EVENT_USER_REMOVE: Discord.Intents.GUILD_SCHEDULED_EVENTS,
        
            ;* AUTO_MODERATION_CONFIGURATION
            AUTO_MODERATION_RULE_CREATE: Discord.Intents.AUTO_MODERATION_CONFIGURATION,
            AUTO_MODERATION_RULE_UPDATE: Discord.Intents.AUTO_MODERATION_CONFIGURATION,
            AUTO_MODERATION_RULE_DELETE: Discord.Intents.AUTO_MODERATION_CONFIGURATION,
        
            ;* AUTO_MODERATION_EXECUTION
            AUTO_MODERATION_ACTION_EXECUTION: Discord.Intents.AUTO_MODERATION_EXECUTION,
        
            ;* GUILD_MESSAGE_POLLS
            MESSAGE_POLL_VOTE_ADD: Discord.Intents.GUILD_MESSAGE_POLLS,
            MESSAGE_POLL_VOTE_REMOVE: Discord.Intents.GUILD_MESSAGE_POLLS,
        
            ;* DIRECT_MESSAGE_POLLS
            DIRECT_MESSAGE_POLL_VOTE_ADD: Discord.Intents.DIRECT_MESSAGE_POLLS,
            DIRECT_MESSAGE_POLL_VOTE_REMOVE: Discord.Intents.DIRECT_MESSAGE_POLLS,

            ;* Other
            HELLO: 0,
            READY: 0,
            RESUMED: 0,
            INVALID_SESSION: 0,
            APPLICATION_COMMAND_PERMISSIONS_UPDATE: 0,
            APPLICATION_COMMAND_CREATE: 0,
            APPLICATION_COMMAND_UPDATE: 0,
            APPLICATION_COMMAND_DELETE: 0,
            INTERACTION_CREATE: 0
        }
        name := "", callback := 0
        __New(name, callback, intents) {
            if !callback is Func
                throw TypeError("Expected a function but received a " Type(callback))
            if !name is String or !Discord.Event.EventEnum.HasProp(name)
                throw TypeError("Invalid event name")
            if callback.MaxParams < 3 || callback.MinParams > 3
                throw TypeError("Invalid callback")
            if (Discord.Event.EventEnum.%name%) && !(Discord.Event.EventEnum.%name% & intents)
                throw TypeError("Missing intent: " Discord.Event.EventEnum.%name%)
            this.name := name, this.callback := (ev,args*) => callback(args*)           
        }
        
    }
    Class Webhook {

    }
    Class Intents {
        static GUILDS := 1 << 0
        static GUILD_MEMBERS := 1 << 1
        static GUILD_MODERATION := 1 << 2
        static GUILD_EXPRESSIONS := 1 << 3
        static GUILD_INTEGRATIONS := 1 << 4
        static GUILD_WEBHOOKS := 1 << 5
        static GUILD_INVITES := 1 << 6
        static GUILD_VOICE_STATES := 1 << 7
        static GUILD_PRESENCES := 1 << 8
        static GUILD_MESSAGES := 1 << 9
        static GUILD_MESSAGE_REACTIONS := 1 << 10
        static GUILD_MESSAGE_TYPING := 1 << 11
        static DIRECT_MESSAGES := 1 << 12
        static DIRECT_MESSAGE_REACTIONS := 1 << 13
        static DIRECT_MESSAGE_TYPING := 1 << 14
        static MESSAGE_CONTENT := 1 << 15
        static GUILD_SCHEDULED_EVENTS := 1 << 16
        static AUTO_MODERATION_CONFIGURATION := 1 << 20
        static AUTO_MODERATION_EXECUTION := 1 << 21
        static GUILD_MESSAGE_POLLS := 1 << 22
        static DIRECT_MESSAGE_POLLS := 1 << 23
    }
    Class Presence {
        static playing := 0
        static streaming := 1
        static listening := 2
        static watching := 3
        static custom := 4 ; not for bots
        static competing := 5
    }
    Class Attachment {
        ptr := 0, size := 0, contentType := '', filename:='', description:=''
        Class File extends Discord.Attachment {
            __New(path, contentType?, description?) {
                if !path is String
                    throw TypeError("Expected a string but received a " Type(path))
                if !FileExist(path)
                    throw TypeError("File does not exist")
                if IsSet(description) && description is String
                    this.description := description
                f := FileOpen(path, "R")
                f.RawRead(buf := Buffer(this.size:=f.Length,0)), this.ptr:=buf.Ptr
                if !IsSet(contentType) || !contentType {
                    this.contentType := (n:=f.ReadUInt() = 0x474E5089) ? "image/png"
                    : n=0x38464947 ? "image/gif"
                    : n=0x25504446 ? "application/pdf"
                    : n=0x504B0304 ? "application/zip"
                    : n=0x504B0506 ? "application/zip"
                    : n=0x504B0708 ? "application/zip"
                    : n & 0xFFFF = 0x4D42 ? "image/bmp"
                    : n & 0xFFFF = 0xD8FF ? "image/jpeg"
                    : n & 0xFFFF = 0x4949 ? "image/tiff"
                    : n & 0xFFFF = 0x4D4D ? "image/tiff"
                    : 'application/octet-stream'
                }
                else this.contentType := contentType
                SplitPath(path, &filename)
                this.filename := filename
                f.Close()
            }
        }
        Class Bitmap extends Discord.Attachment {
            contentType := "image/png", hGlobal := 0
            __New(pBitmap, filename := 'image.png', description?) {
                if !(pBitmap is Integer)
                    throw TypeError("Expected an integer but received a " Type(pBitmap))
                if !(filename is String)
                    throw TypeError("Expected a string but received a " Type(filename))
                if IsSet(description) && description is String
                    this.description := description
                DllCall("gdiplus\GdipGetImageEncodersSize", "uintp", &n:=0, "uintp", &s:=0)
                if !n || !s
                    throw OSError("Failed to get GdipGetImageEncodersSize")
                buf := Buffer(s)
                DllCall("GdiPlus\GdipGetImageEncoders", "uint", n, "uint", s, "ptr", buf)
                loop n
                    if InStr(StrGet(NumGet(buf, (idx := (48+7*A_PtrSize)*(A_Index-1))+32+3*A_PtrSize, "UPtr"), "UTF-16"), "*.PNG")
                        this.hGlobal:=DllCall("GlobalAlloc", "uint", 0x2, "uint", 0), DllCall("ole32\CreateStreamOnHGlobal", "ptr", this.hGlobal, "int", 1, "ptrp", &pStream:=0), DllCall("GdiPlus\GdipSaveImageToStream", "ptr", pBitmap, "ptr", pStream, "ptr", buf.ptr+idx, "ptr", 0)
                if !this.HasProp('hGlobal')
                    throw OSError('Can`'t find PNG encoder')
                this.ptr := DllCall("GlobalLock", "ptr", this.hGlobal), this.size := DllCall("GlobalSize", "ptr", this.hGlobal), this.filename := filename
            }
            __Delete() {
                if !this.hGlobal
                    return
                if !this.ptr
                    return DllCall("GlobalFree", "ptr", this.hGlobal)
                DllCall("GlobalUnlock", "ptr", this.ptr), DllCall("GlobalFree", "ptr", this.hGlobal)
            }
        }
    }
    Class Component {

    }
    Class Interaction {
        static Call(self, obj) {
            if !self is Discord.Bot
                throw TypeError("Expected a Discord.Bot but received a " Type(self))
            if !obj is Object
                throw TypeError("Expected an object but received a " Type(obj))
            for i, j in ["id", "type", "data", "guild_id", "channel_id"]
                if !obj.HasProp(j)
                    throw TypeError("Missing property " j)
            data := obj
            data.timestamp := Discord.TimeStamp.Now()
            data.startCount := (DllCall("QueryPerformanceCounter", "int64p", &_:=0), _)
            data.self := self
            data.reply := ObjBindMethod(this, "Reply")
            data.deferReply := ObjBindMethod(this, "DeferReply")
            data.EditReply := ObjBindMethod(this, "EditReply")
            return data
        }
        static Reply(data, Message) {
            if !Message is Discord.Message
                throw TypeError("Expected a Discord.Message but received a " Type(Message))
            if !data is Object
                throw TypeError("Expected an object but received a " Type(data))
            for i, j in ["id", "type", "data", "guild_id", "channel_id"]
                if !data.HasProp(j)
                    throw TypeError("Missing property " j)
            rest := data.self.rest
            if !Message.attachments.length
                return rest("POST", "/interactions/" data.id "/" data.token "/callback", JSON.stringify({type: 4, data: Message.obj}), {%"Content-Type"%: "application/json"})
            fd := Discord.FormData()
            fd.append("payload_json", s:=JSON.stringify({type: 4, data: Message.obj}), StrLen(s), "application/json")
            for i, j in Message.attachments
                fd.append("files[" i-1 "]", j.ptr, j.size, j.contentType, j.filename)
            return rest("POST", "/interactions/" data.id "/" data.token "/callback", fd.data, {%"Content-Type"%: fd.contentType})
        }
        static DeferReply(data) {
            if !data is Object
                throw TypeError("Expected an object but received a " Type(data))
            for i, j in ["id", "type", "data", "guild_id", "channel_id"]
                if !data.HasProp(j)
                    throw TypeError("Missing property " j)
            rest := data.self.rest
            return rest("POST", "/interactions/" data.id "/" data.token "/callback", JSON.stringify({type: 5}), {%"Content-Type"%: "application/json"})
        }
        static EditReply(data, Message) {
            if !Message is Discord.Message
                throw TypeError("Expected a Discord.Message but received a " Type(Message))
            if !data is Object
                throw TypeError("Expected an object but received a " Type(data))
            for i, j in ["id", "type", "data", "guild_id", "channel_id"]
                if !data.HasProp(j)
                    throw TypeError("Missing property " j)
            rest := data.self.rest
            if !Message.attachments.length
                return rest("PATCH", "/webhooks/" data.self.user.id "/" data.token "/messages/@original", JSON.stringify(Message.obj), {%"Content-Type"%: "application/json"})
            fd := Discord.FormData()
            fd.append("payload_json", s:=JSON.stringify(Message.obj), StrLen(s), "application/json")
            for i, j in Message.attachments
                fd.append("files[" i-1 "]", j.ptr, j.size, j.contentType, j.filename)
            return rest("PATCH", "/webhooks/" data.self.user.id "/" data.token "/messages/@original", fd.data, {%"Content-Type"%: fd.contentType})
        }
    }

    class WebSocket {
        Ptr := 0, async := 0, readyState := 0, url := ''
    
        ; The array of HINTERNET handles, [hSession, hConnect, hRequest(onOpen) | hWebSocket?]
        HINTERNETs := []
    
        ; when request is opened
        onOpen() => 0
        ; when server sent a close frame
        onClose(status, reason) => 0
        ; when server sent binary message
        onData(data, size) => 0
        ; when server sent UTF-8 message
        onMessage(msg) => 0
        reconnect() => 0

        /**
         * @param {String} Url the url of websocket
         * @param {Object} Events an object of `{open:(this)=>void,data:(this, data, size)=>bool,message:(this, msg)=>bool,close:(this, status, reason)=>void}`
         * @param {Integer} Async Use asynchronous mode
         * @param {Object|Map|String} Headers Additional request headers to use when creating connections
         * @param {Integer} TimeOut Set resolve, connect, send and receive timeout
         */
        __New(Url, Events := 0, Async := true, Headers := '', TimeOut := 0, InitialSize := 8192) {
            static contexts := Map()
            if (!RegExMatch(Url, 'i)^((?<SCHEME>wss?)://)?((?<USERNAME>[^:]+):(?<PASSWORD>.+)@)?(?<HOST>[^/:\s]+)(:(?<PORT>\d+))?(?<PATH>/\S*)?$', &m))
                Throw Discord.WebSocket.Error('Invalid websocket url')
            if !hSession := DllCall('Winhttp\WinHttpOpen', 'ptr', 0, 'uint', 0, 'ptr', 0, 'ptr', 0, 'uint', Async ? 0x10000000 : 0, 'ptr')
                Throw Discord.WebSocket.Error()
            this.async := Async := !!Async, this.url := Url
            this.HINTERNETs.Push(hSession)
            port := m.PORT ? Integer(m.PORT) : m.SCHEME = 'ws' ? 80 : 443
            dwFlags := m.SCHEME = 'wss' ? 0x800000 : 0
            if TimeOut
                DllCall('Winhttp\WinHttpSetTimeouts', 'ptr', hSession, 'int', TimeOut, 'int', TimeOut, 'int', TimeOut, 'int', TimeOut, 'int')
            if !hConnect := DllCall('Winhttp\WinHttpConnect', 'ptr', hSession, 'wstr', m.HOST, 'ushort', port, 'uint', 0, 'ptr')
                Throw Discord.WebSocket.Error()
            this.HINTERNETs.Push(hConnect)
            switch Type(Headers) {
                case 'Object', 'Map':
                    s := ''
                    for k, v in Headers is Map ? Headers : Headers.OwnProps()
                        s .= '`r`n' k ': ' v
                    Headers := LTrim(s, '`r`n')
                case 'String':
                default:
                    Headers := ''
            }
            if (Events) {
                for k, v in Events.OwnProps()
                    if (k ~= 'i)^(open|data|message|close)$')
                        this.DefineProp('on' k, { call: v })
            }
            if (Async) {
                this.DefineProp('shutdown', { call: async_shutdown })
                    .DefineProp('receive', { call: receive })
                    .DefineProp('_send', { call: async_send })
            } else this.__cache_size := InitialSize
            connect(this), this.DefineProp('reconnect', { call: connect })
    
            connect(self) {
                if !self.HINTERNETs.Length
                    Throw Discord.WebSocket.Error('The connection is closed')
                self.shutdown()
                if !hRequest := DllCall('Winhttp\WinHttpOpenRequest', 'ptr', hConnect, 'wstr', 'GET', 'wstr', m.PATH, 'ptr', 0, 'ptr', 0, 'ptr', 0, 'uint', dwFlags, 'ptr')
                    Throw Discord.WebSocket.Error()
                self.HINTERNETs.Push(hRequest), self.onOpen()
                if (Headers)
                    DllCall('Winhttp\WinHttpAddRequestHeaders', 'ptr', hRequest, 'wstr', Headers, 'uint', -1, 'uint', 0x20000000, 'int')
                if (!DllCall('Winhttp\WinHttpSetOption', 'ptr', hRequest, 'uint', 114, 'ptr', 0, 'uint', 0, 'int')
                    || !DllCall('Winhttp\WinHttpSendRequest', 'ptr', hRequest, 'ptr', 0, 'uint', 0, 'ptr', 0, 'uint', 0, 'uint', 0, 'uptr', 0, 'int')
                    || !DllCall('Winhttp\WinHttpReceiveResponse', 'ptr', hRequest, 'ptr', 0)
                    || !DllCall('Winhttp\WinHttpQueryHeaders', 'ptr', hRequest, 'uint', 19, 'ptr', 0, 'wstr', status := '00000', 'uint*', 10, 'ptr', 0, 'int')
                    || status != '101')
                    Throw IsSet(status) ? Discord.WebSocket.Error('Invalid status: ' status) : Discord.WebSocket.Error()
                if !self.Ptr := DllCall('Winhttp\WinHttpWebSocketCompleteUpgrade', 'ptr', hRequest, 'ptr', 0)
                    Throw Discord.Websocket.Error()
                DllCall('Winhttp\WinHttpCloseHandle', 'ptr', self.HINTERNETs.Pop())
                self.HINTERNETs.Push(self.Ptr), self.readyState := 1
                (Async && async_receive(self))
            }
    
            async_receive(self) {
                static on_read_complete := get_sync_callback(), hHeap := DllCall('GetProcessHeap', 'ptr')
                static msg_gui := Gui(), wm_ahkmsg := DllCall('RegisterWindowMessage', 'str', 'AHK_WEBSOCKET_STATUSCHANGE', 'uint')
                static pHeapReAlloc := DllCall('GetProcAddress', 'ptr', DllCall('GetModuleHandle', 'str', 'kernel32', 'ptr'), 'astr', 'HeapReAlloc', 'ptr')
                static pSendMessageW := DllCall('GetProcAddress', 'ptr', DllCall('GetModuleHandle', 'str', 'user32', 'ptr'), 'astr', 'SendMessageW', 'ptr')
                static pWinHttpWebSocketReceive := DllCall('GetProcAddress', 'ptr', DllCall('GetModuleHandle', 'str', 'winhttp', 'ptr'), 'astr', 'WinHttpWebSocketReceive', 'ptr')
                static _ := (OnMessage(wm_ahkmsg, WEBSOCKET_READ_WRITE_COMPLETE, 0xff), DllCall('SetParent', 'ptr', msg_gui.Hwnd, 'ptr', -3))
                ; #DllLoad E:\projects\test\test\x64\Debug\test.dll
                ; on_read_complete := DllCall('GetProcAddress', 'ptr', DllCall('GetModuleHandle', 'str', 'test', 'ptr'), 'astr', 'WINHTTP_STATUS_READ_COMPLETE', 'ptr')
                NumPut('ptr', pws := ObjPtr(self), 'ptr', msg_gui.Hwnd, 'uint', wm_ahkmsg, 'uint', InitialSize, 'ptr', hHeap,
                    'ptr', cache := DllCall('HeapAlloc', 'ptr', hHeap, 'uint', 0, 'uptr', InitialSize, 'ptr'), 'uptr', 0, 'uptr', InitialSize,
                    'ptr', pHeapReAlloc, 'ptr', pSendMessageW, 'ptr', pWinHttpWebSocketReceive,
                    contexts[pws] := context := Buffer(11 * A_PtrSize)), self.__send_queue := []
                context.DefineProp('__Delete', { call: self => DllCall('HeapFree', 'ptr', hHeap, 'uint', 0, 'ptr', NumGet(self, 3 * A_PtrSize + 8, 'ptr')) })
                DllCall('Winhttp\WinHttpSetOption', 'ptr', self, 'uint', 45, 'ptr*', context.Ptr, 'uint', A_PtrSize)
                DllCall('Winhttp\WinHttpSetStatusCallback', 'ptr', self, 'ptr', on_read_complete, 'uint', 0x80000, 'uptr', 0, 'ptr')
                if err := DllCall('Winhttp\WinHttpWebSocketReceive', 'ptr', self, 'ptr', cache, 'uint', InitialSize, 'uint*', 0, 'uint*', 0)
                    self.onError(err)
            }
    
            static WEBSOCKET_READ_WRITE_COMPLETE(wp, lp, msg, hwnd) {
                static map_has := Map.Prototype.Has
                if !map_has(contexts, ws := NumGet(wp, 'ptr')) || (ws := ObjFromPtrAddRef(ws)).readyState != 1
                    return
                switch lp {
                    case 5:		; WRITE_COMPLETE
                        try ws.__send_queue.Pop()
                    case 4:		; WINHTTP_WEB_SOCKET_CLOSE_BUFFER_TYPE
                        if err := NumGet(wp, A_PtrSize, 'uint')
                            return ws.onError(err)
                        rea := ws.QueryCloseStatus(), ws.shutdown()
                        return ws.onClose(rea.status, rea.reason)
                    default:	; WINHTTP_WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE, WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE
                        data := NumGet(wp, A_PtrSize, 'ptr')
                        size := NumGet(wp, 2 * A_PtrSize, 'uptr')
                        if lp == 2
                            return ws.onMessage(StrGet(data, size, 'utf-8'))
                        else return ws.onData(data, size)
                }
            }
    
            static async_send(self, type, buf, size) {
                if (self.readyState != 1)
                    Throw Discord.WebSocket.Error('websocket is disconnected')
                (q := self.__send_queue).InsertAt(1, buf)
                while (err := DllCall('Winhttp\WinHttpWebSocketSend', 'ptr', self, 'uint', type, 'ptr', buf, 'uint', size, 'uint')) = 4317 && A_Index < 60
                    Sleep(15)
                if err
                    q.RemoveAt(1), self.onError(err)
            }
    
            static async_shutdown(self) {
                if self.Ptr
                    DllCall('Winhttp\WinHttpSetOption', 'ptr', self, 'uint', 45, 'ptr*', 0, 'uint', A_PtrSize)
                (Discord.WebSocket.Prototype.shutdown)(self)
                try contexts.Delete(ObjPtr(self))
            }
    
            static get_sync_callback() {
                mcodes := ['g+wMVot0JBiF9g+E0QAAAItEJBw9AAAQAHUVi0YkagVW/3YI/3YE/9Beg8QMwhQAPQAACAAPhaYAAACLBolEJASLRCQgU1VXi1AEx0QkFAAAAADHRCQYAAAAAIP6BHRsi04Yi+qLAI0MAYlOGIPlAXV2i0YUiUQkFI1EJBBSUP92CItGJP92BIlMJCjHRhgAAAAA/9CNfhyFwHQHi14MOx91UYsHK0YYagBqAFCLRhQDRhhQ/3QkMItGKP/QhcB0HT3dEAAAdBaJRCQUagSNRCQUUP92CItGJP92BP/QX11bXoPEDMIUAIteHI1+HDvLcrED24tGIFP/dhRqAP92EP/QhcB0B4lGFIkf65aF7XSSx0QkFA4AB4DrsQ==',
                    'SIXSD4QvAQAASIlcJCBBVkiD7FBIi9pMi/FBgfgAABAAdR9Ii0sITIvCi1IQQbkFAAAA/1NASItcJHhIg8RQQV7DQYH4AAAIAA+F3gAAAEiLAkljUQRIiWwkYEiJRCQwM8BIiXQkaEiJfCRwSMdEJDgAAAAASIlEJECD+gQPhIYAAABFiwGL6kiLQyhNjQQATIlDKIPlAQ+FnAAAAEiLQyBMi8qLUxBIi0sITIlEJEBMjUQkMEiJRCQ4SMdDKAAAAAD/U0BIjXswSIXAdAiLcxRIOzd1c0SLB0UzyUiLUyBJi85EK0MoSANTKEjHRCQgAAAAAP9TSIXAdCM93RAAAHQci8BIiUQkOItTEEyNRCQwSItLCEG5BAAAAP9TQEiLdCRoSItsJGBIi3wkcEiLXCR4SIPEUEFew0iLczBIjXswTDvGcpBIA/ZMi0MgTIvOSItLGDPS/1M4SIXAdAxIiUMgSIk36Wz///+F7Q+EZP///0jHRCQ4DgAHgOuM']
                DllCall('crypt32\CryptStringToBinary', 'str', hex := mcodes[A_PtrSize >> 2], 'uint', 0, 'uint', 1, 'ptr', 0, 'uint*', &s := 0, 'ptr', 0, 'ptr', 0) &&
                    DllCall('crypt32\CryptStringToBinary', 'str', hex, 'uint', 0, 'uint', 1, 'ptr', code := Buffer(s), 'uint*', &s, 'ptr', 0, 'ptr', 0) &&
                    DllCall('VirtualProtect', 'ptr', code, 'uint', s, 'uint', 0x40, 'uint*', 0)
                return code
            }
    
            static receive(*) {
                Throw Discord.WebSocket.Error('Used only in synchronous mode')
            }
        }
    
        __Delete() {
            this.shutdown()
            while (this.HINTERNETs.Length)
                DllCall('Winhttp\WinHttpCloseHandle', 'ptr', this.HINTERNETs.Pop())
        }
    
        onError(err, what := 0) {
            if err != 12030
                Throw Discord.WebSocket.Error(err, what - 5)
            if this.readyState == 3
                return
            this.readyState := 3
            try this.onClose(1006, '')
        }
    
        class Error extends Error {
            __New(err := A_LastError, what := -4) {
                static module := DllCall('GetModuleHandle', 'str', 'winhttp', 'ptr')
                if err is Integer
                    if (DllCall("FormatMessage", "uint", 0x900, "ptr", module, "uint", err, "uint", 0, "ptr*", &pstr := 0, "uint", 0, "ptr", 0), pstr)
                        err := (msg := StrGet(pstr), DllCall('LocalFree', 'ptr', pstr), msg)
                    else err := OSError(err).Message
                super.__New(err, what)
            }
        }
    
        queryCloseStatus() {
            if (!DllCall('Winhttp\WinHttpWebSocketQueryCloseStatus', 'ptr', this, 'ushort*', &usStatus := 0, 'ptr', vReason := Buffer(123), 'uint', 123, 'uint*', &len := 0))
                return { status: usStatus, reason: StrGet(vReason, len, 'utf-8') }
            else if (this.readyState > 1)
                return { status: 1006, reason: '' }
        }
    
        /** @param type BINARY_MESSAGE = 0, BINARY_FRAGMENT = 1, UTF8_MESSAGE = 2, UTF8_FRAGMENT = 3 */
        _send(type, buf, size) {
            if (this.readyState != 1)
                Throw Discord.WebSocket.Error('websocket is disconnected')
            if err := DllCall('Winhttp\WinHttpWebSocketSend', 'ptr', this, 'uint', type, 'ptr', buf, 'uint', size, 'uint')
                return this.onError(err)
        }
    
        ; sends a utf-8 string to the server
        sendText(str) {
            if (size := StrPut(str, 'utf-8') - 1) {
                StrPut(str, buf := Buffer(size), 'utf-8')
                this._send(2, buf, size)
            } else
                this._send(2, 0, 0)
        }
    
        send(buf) => this._send(0, buf, buf.Size)
    
        receive() {
            if (this.readyState != 1)
                Throw Discord.WebSocket.Error('websocket is disconnected')
            ptr := (cache := Buffer(size := this.__cache_size)).Ptr, offset := 0
            while (!err := DllCall('Winhttp\WinHttpWebSocketReceive', 'ptr', this, 'ptr', ptr + offset, 'uint', size - offset, 'uint*', &dwBytesRead := 0, 'uint*', &eBufferType := 0)) {
                switch eBufferType {
                    case 1, 3:
                        offset += dwBytesRead
                        if offset == size
                            cache.Size := size *= 2, ptr := cache.Ptr
                    case 0, 2:
                        offset += dwBytesRead
                        if eBufferType == 2
                            return StrGet(ptr, offset, 'utf-8')
                        cache.Size := offset
                        return cache
                    case 4:
                        rea := this.QueryCloseStatus(), this.shutdown()
                        try this.onClose(rea.status, rea.reason)
                        return
                }
            }
            (err != 4317 && this.onError(err))
        }
    
        shutdown() {
            if (this.readyState = 1) {
                this.readyState := 2
                DllCall('Winhttp\WinHttpWebSocketClose', 'ptr', this, 'ushort', 1006, 'ptr', 0, 'uint', 0)
                this.readyState := 3
            }
            while (this.HINTERNETs.Length > 2)
                DllCall('Winhttp\WinHttpCloseHandle', 'ptr', this.HINTERNETs.Pop())
            this.Ptr := 0
        }
    }
    class FormData {
        __data := 0
        __New() {
            this.buf := Buffer(1), this.offset := 0
            this.boundary := '------------------------' A_Now A_TickCount
            this.contentType := 'multipart/form-data; boundary=' this.boundary
        }
        append(name, value, size, contentType, filename?) {
            if this.__data
                throw TypeError("Data has been created")
            if !name is String
                throw TypeError("Expected a string but received a " Type(name))
            if !contentType is String
                throw TypeError("Expected a string but received a " Type(contentType))
            if IsSet(filename) && !filename is String
                throw TypeError("Expected a string but received a " Type(filename))
            str := (this.offset ? '`n' : '') '--' this.boundary '`nContent-Disposition: form-data; name="' name '"' (IsSet(filename) ? '; filename="' filename '"' : '') '`nContent-Type: ' contentType '`n`n' (value is String ? value : '')
            this.buf.Size+=len:=StrLen(str), StrPut(str, this.buf.ptr+this.offset, 'utf-8'), this.offset += len
            if (not Value is String)
                this.buf.Size+=size, DllCall('RtlMoveMemory', 'ptr', this.buf.ptr+this.offset, 'ptr', value, 'uint', size), this.offset += size
            return this
        }
        data {
            get {
                if this.__data
                    return this.__data
                this.buf.Size+=StrLen(str := '`n--' this.boundary '--`n'), StrPut(str, this.buf.ptr+this.offset, 'utf-8')
                this.__data := ComObjArray(0x11, this.buf.Size)
                DllCall('oleaut32\SafeArrayAccessData', 'ptr', this.__data, 'ptr*', &p:=0)
                DllCall('RtlMoveMemory', 'ptr', p, 'ptr', this.buf.ptr, 'uint', this.buf.Size)
                DllCall('oleaut32\SafeArrayUnaccessData', 'ptr', this.__data)
                return this.__data
            }
        }
    }
}
