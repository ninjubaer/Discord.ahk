Class FormData {
    __New() {
        this.boundary := '---------------------------' A_TickCount . A_TickCount
        this.hGlobal := DllCall("GlobalAlloc", "UInt", 2, "Ptr", 0, "ptr")
        this.pStream := (DllCall("ole32\CreateStreamOnHGlobal", "ptr", this.hGlobal, "int", false, "ptrp", &_:=0, "uint"), _)
        this.fileCount:=0
        this.contentType := "multipart/form-data; boundary=" SubStr(this.boundary, 2)
    }
    Call(data) {
        str :=
        (
        '
        ' . this.boundary . '
        Content-Disposition: form-data; name="' . data.name . '"' . (data.hasProp("filename") ? '; filename="' . data.filename . '"' : "") . '
        Content-Type: ' . data.type . '

        ' . (data.hasProp("string") ? data.string . "`r`n": "")
        )
        this.utf8(str)
        if (data.hasProp("pBitmap")) {
            try {
					pFileStream := Gdip_SaveBitmapToStream(data.pBitmap)
					DllCall("shlwapi\IStream_Size", "Ptr", pFileStream, "UInt64P", &size:=0, "UInt")
					DllCall("shlwapi\IStream_Reset", "Ptr", pFileStream, "UInt")
					DllCall("shlwapi\IStream_Copy", "Ptr", pFileStream, "Ptr", this.pStream, "UInt", size, "UInt")
					ObjRelease(pFileStream)
			}
        }
        if (data.hasProp("file")) {
            DllCall("shlwapi\SHCreateStreamOnFileEx", "WStr", data.file, "Int", 0, "UInt", 0x80, "Int", 0, "Ptr", 0, "PtrP", &pFileStream:=0)
			DllCall("shlwapi\IStream_Size", "Ptr", pFileStream, "UInt64P", &size:=0, "UInt")
			DllCall("shlwapi\IStream_Copy", "Ptr", pFileStream, "Ptr", this.pStream, "UInt", size, "UInt")
			ObjRelease(pFileStream)
        }
        return this
    }
    AppendJSON(name, value) => this({name: name, string: JSON.stringify(value, false, ""), type: "application/json"})
    AppendBitmap(pBitmap, filename?) => this({name: 'files[' this.fileCount++ ']',pBitmap: pBitmap, filename: filename ?? 'image.png', type: "image/png"})
    AppendFile(file, contentType := 'application/octet-stream') => this({name: 'files[' this.fileCount++ ']', file: file, type: contentType})
    AppendString(name, value) => this({name: name, string: value, type: "text/plain"})
    utf8(str) {
        StrPut(str, buf:=Buffer(size:=StrPut(str, "UTF-8") - 1), "UTF-8")
        DllCall("shlwapi\IStream_Write", "ptr", this.pStream, "ptr", buf, "uint", size, "uintp", &written:=0)
    }
    data(&data) {
        this.utf8('`r`n`r`n' this.boundary '--`r`n')
        ObjRelease(this.pStream)
        pGlobal := DllCall("GlobalLock", "Ptr", this.hGlobal, "ptr")
        size := DllCall("GlobalSize", "ptr", pGlobal, "uint")
        data := ComObjArray(0x11, size)
        pvData := NumGet(ComObjValue(data), 8 + A_PtrSize, "ptr")
        DllCall("RtlMoveMemory", "ptr", pvData, "ptr", pGlobal, "uint", size)

        DllCall("GlobalUnlock", "Ptr", this.hGlobal)
        DllCall("GlobalFree", "Ptr", this.hGlobal)
        return data
    }
}