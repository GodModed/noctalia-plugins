import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Services.System

Item {
    id: root

    property var pluginApi: null

    Process {
        id: wallpaperProcess
    }

    Process {
        id: pauseProcess
    }

    function refresh() {

        wallpaperProcess.running = false
        
        if (pluginApi && pluginApi.pluginSettings.wallpaperPath) {

            let mpvOptions = "no-audio --loop-playlist shuffle input-ipc-server=/tmp/mpv-socket --panscan=1 --scale=nearest"
            if (pluginApi.pluginSettings.paused) {
                mpvOptions += " --pause"
            }

            const command = ["mpvpaper", "-o", mpvOptions, "ALL", pluginApi.pluginSettings.wallpaperPath]
            wallpaperProcess.exec(command)
            Logger.i("animated-wallpapers", "Starting wallpaper with command: " + command.join(" "))
        }

    }

    function pause() {
        if (wallpaperProcess.running) {

            const command = ['sh', '-c', "echo 'cycle pause' | socat - /tmp/mpv-socket"]
            pauseProcess.exec(command)
            Logger.i("animated-wallpapers", "Toggling pause with command: " + command.join(" "))

        }
    }

    Component.onCompleted: {
        ToastService.showNotice("Loaded wallpaper")
        refresh()
    }

}