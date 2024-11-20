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

        Class REST {
            token := ""
            __New(token) {
                this.token := token
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
            msgbox JSON.stringify(obj)
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
    Class Channel {

    }
    Class Message {

    }
    Class Embed {

    }
    Class Reaction {

    }
    Class Role {

    }
    Class Guild {

    }
    Class Command {

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
            APPLICATION_COMMAND_DELETE: 0
        }
        name := "", callback := 0
        __New(name, callback, intents) {
            if !callback is Func
                throw TypeError("Expected a function but received a " Type(callback))
            if !name is String or !Discord.Event.EventEnum.HasProp(name)
                throw TypeError("Invalid event name")
            if callback.MaxParams() < 3 || callback.MinParams() > 3
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

    }
    Class Component {

    }
    Class Interaction {

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
}
