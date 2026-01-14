import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property string wallpaperPath: pluginApi?.pluginSettings?.wallpaperPath || ""
  property bool paused: pluginApi?.pluginSettings?.paused || false

  spacing: Style.marginM

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NTextInput {
      Layout.fillWidth: true
      text: root.wallpaperPath
      onTextChanged: root.wallpaperPath = text
    }

    NButton {
      text: "Browse"
      onClicked: filePicker.openFilePicker()
    }
  }

  VideoFilePicker {
    id: filePicker
    initialPath: Quickshell.env("HOME") + "/Pictures/AnimatedWallpapers"
    nameFilters: ["*.mp4"]
    onAccepted: {
      if (paths.length > 0)
        root.wallpaperPath = paths[0]
    }
  }

  NToggle {
    label: "Pause Wallpaper"
    checked: root.paused
    onToggled: {
      root.paused = checked
    }
  }

  function saveSettings() {
    pluginApi.pluginSettings.wallpaperPath = root.wallpaperPath
    pluginApi.pluginSettings.paused = root.paused
    pluginApi.saveSettings()
    pluginApi.mainInstance.refresh()
  }
}