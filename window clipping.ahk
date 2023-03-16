/*
trying this
this is way better
improve this code 15march 20:49



*/


/************************************************************************
 * @description  no depencies
 *  
 * @file v5.ahk
 * @author 
 * @date 2023/03/07
 * @version 0.0.0
 ***********************************************************************/
DetectHiddenWindows true
selectregion() {
    ; returns area cordinates and windowid
    CoordMode "Mouse", "Screen"
    MouseGetPos &begin_x, &begin_y, &wintitle_under_cursor_id
    WinGetPos(&win_x, &win_y, &win_width, &win_height, wintitle_under_cursor_id)
    AreaGui := Gui("+Resize -caption AlwaysOnTop")
    AreaGui.BackColor := "EFFDE1"
    WinSetTransparent(100, AreaGui)

    loop {
        MouseGetPos &x, &y
        width := Abs(begin_x - x)
        height := Abs(begin_y - y)

        gui_size := "x" begin_x "y" begin_y "w" width "h" height
        AreaGui.Show(gui_size)
        Sleep 20

        if !GetKeyState("LButton", "P") {
            AreaGui.Destroy()
            break
        }

    }
    /*
    begin_x,begin_y, hegith, width : selected area dimensions
    cropstart_x : crop is relative to the window to match it with the screen we have to offset it
    Id : selected window id
    */

    return { x: begin_x,
        y: begin_y,
        h: height,
        w: width,
        cropstart_x: Abs(win_x - begin_x),
        cropstart_y: Abs(win_y - begin_y),
        Id: wintitle_under_cursor_id,
        win_x: win_x,
        win_y: win_y,
        win_width: win_width,
        win_height: win_height,
    }
}

class WinClip {
    __New(info, gui_color) {
        this.x := info.x
        this.y := info.y
        this.cropstart_x := info.cropstart_x
        this.cropstart_y := info.cropstart_y
        this.w := info.w
        this.h := info.h
        this.Window_Id := info.Id
        this.win_x := info.win_x
        this.win_y := info.win_y
        this.win_width := info.win_width
        this.win_height := info.win_height
        this.gui_color := gui_color
    }

    cropandGui() {
        this.croparea := this.cropstart_x "-" this.cropstart_y " W" this.w " H" this.h
        WinSetStyle "-0xC00000", this.Window_Id
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", this.Window_Id, "uint", WMWA_NCRENDERING_POLICY := 2, "int*", DWMNCRP_DISABLED := 1, "uint", 4)
        Sleep 200    ; if sleep removed it not working
        if !WinActive("ahk_class Shell_TrayWnd")    ; sometimes tasgkbar getting hidden to prevent it
            WinSetRegion(this.croparea " R20-20", this.Window_Id)
        WinSetAlwaysOnTop(1, this.Window_Id)

        this.actionGui := Gui("AlwaysOnTop +ToolWindow -Border", this.Window_Id)
        this.actionGui.BackColor := this.gui_color
        this.actionGui_show := "x" this.x " y" this.y + this.h " w" this.w " h16"
        this.actionGui.Show(this.actionGui_show)

        OnMessage 0x0201, WM_LBUTTONDOWN
        WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {

            ; if WinGetMinMax(this.window_id) = 1 and hwnd = this.actionGui.Hwnd {
            ;     MsgBox("Cannot move window `n" WinGetTitle(this.Window_Id), , "4096 ")
            ; }
            if hwnd = this.actionGui.Hwnd {

                WinGetPos(&gui_x, &gui_y, , , hwnd)
                WinGetPos(&win_x, &win_y, , , this.window_id) ;cropped window
                PostMessage 0XA1, 2, , hwnd
                KeyWait("Lbutton", "p")

                WinGetPos(&x, &y, , , hwnd) ; after moving action gui
                x_rel := gui_x - x
                y_rel := gui_y - y

                if ((gui_x != x) or (gui_y != y)) and WinGetMinMax(this.window_id) = 1 {
                    MsgBox("Cannot move window `n" WinGetTitle(this.Window_Id), , "4096 ")
                    WinMove(gui_x, gui_y, , , hwnd)
                }

                ; new Window position

                win_x_new := win_x - x_rel
                win_y_new := win_y - y_rel
                WinMove(win_x_new, win_y_new, , , this.window_id)

            }
        }
        OnMessage 0x0203, WM_LBUTTONDBLCLK
        WM_LBUTTONDBLCLK(wParam, lParam, msg, hwnd) {
            if this.actionGui.Hwnd == hwnd {
                static hide := true
                hide ? WinHide(this.Window_Id) : WinShow(this.Window_Id)
                hide ? GuiFromHwnd(hwnd).Show("w50") : GuiFromHwnd(hwnd).Show("W" this.w)
                hide := !hide
            }
        }

        onMessage 0x0204, WM_RBUTTONDOWN
        WM_RBUTTONDOWN(wParam, lParam, msg, hwnd) {
            if this.actionGui.Hwnd == hwnd {

                rightclick := Menu()
                rightclick.Add("Close", close)
                rightclick.show()
            }

           
            close(*) {

                this.uncrop(this.window_id)
                WinClose(hwnd)
            }
        }
    }
    uncrop(window_id) {
        WinMove(this.win_x, this.win_y, this.win_width, this.win_height, window_id)

        WinSetStyle "+0xC00000", window_id
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", window_id, "uint", DWMWA_NCRENDERING_POLICY := 2, "int*", DWMNCRP_ENABLED := 2, "uint", 4)
        WinSetRegion(, window_id)
        WinSetAlwaysOnTop(0, window_id)
        WinShow(this.Window_Id)

    }
}
info := []
^#Lbutton:: {
    static i := 1
    global info
    colors := ["7642ee", "e27157", "b14358", "ecaba7b", "6d5679"]
    info.Push(selectregion())
    lool := WinClip(info[i], colors[i])
    lool.cropandGui()
    i++
    if i == 5
        i := 1


}

exiting(*) {
    global info
    try {


        loop info.Length {
            WinShow(info[A_Index].Id)
            WinSetRegion(, info[A_Index].Id)
            WinMove(info[A_Index].win_x, info[A_Index].win_y, info[A_Index].win_width, info[A_Index].win_height, info[A_Index].Id)
            WinSetAlwaysOnTop(0, info[A_Index].Id)
            WinSetStyle "+0xC00000", info[A_Index].Id
            DllCall("dwmapi\DwmSetWindowAttribute", "ptr", info[A_Index].Id, "uint", DWMWA_NCRENDERING_POLICY := 2, "int*", DWMNCRP_ENABLED := 2, "uint", 4)
        }
    }
}
OnExit exiting