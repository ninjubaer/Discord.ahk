QPC() {
    static _:=0, f := (DllCall("QueryPerformanceFrequency", "int64p", &_),_ /= 1000)
    return (DllCall("QueryPerformanceCounter", "int64p", &_), _ / f)
}