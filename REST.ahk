Class REST {
    __New(token, version?) {
        this.token := token, this.version := version ?? 10, this.baseAPI := 'https://discord.com/api/v' this.version '/'
        this.defaultHeaders := {
            Authorization: "Bot " this.token,
            %"User-Agent"%: "DiscordBot (by Ninju)"
        }
    }
    Call(method, endpoint, options) {
        (whr := ComObject("WinHttp.WinHttpRequest.5.1")).Open(method, this.baseAPI . endpoint, false)
        for i, j in this.defaultHeaders.OwnProps()
            whr.SetRequestHeader(i, j)
        for i, j in (options.headers ?? {}).OwnProps()
            whr.SetRequestHeader(i, j)
        whr.Send((IsObject(options.body ?? "") && !(options.body is ComObjArray)) ? JSON.stringify(options.body ?? "") : options.body ?? "")
        return {status: whr.Status, text: whr.ResponseText, json: JSON.parse(whr.ResponseText)}
    }
    Get(endpoint, options) {
        return this.Call("GET", endpoint, options)
    }
    Post(endpoint, options) {
        return this.Call("POST", endpoint, options)
    }
    Patch(endpoint, options) {
        return this.Call("PATCH", endpoint, options)
    }
    Put(endpoint, options) {
        return this.Call("PUT", endpoint, options)
    }
    Delete(endpoint, options) {
        return this.Call("DELETE", endpoint, options)
    }
    SendMessage(channelId, content) {
        return this("POST", "channels/" channelId "/messages", {
            body: content,
            headers: {%"Content-Type"%: "application/json"}
        })
    }
    __Call(method, endpoint, options) {
        return this.Call(method, endpoint, options)
    }
}