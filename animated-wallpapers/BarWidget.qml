// Credits: Based on the BarWidget.qml from the update-count plugin
// src: https://github.com/noctalia-dev/noctalia-plugins/blob/main/update-count/BarWidget.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Rectangle {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property bool hovered: false

  readonly property string barPosition: Settings.data.bar.position
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"

  implicitWidth: isVertical ? Style.capsuleHeight : layout.implicitWidth + Style.marginS * 2
  implicitHeight: isVertical ? layout.implicitHeight + Style.marginS * 2 : Style.capsuleHeight

  color: root.hovered ? Color.mHover : Style.capsuleColor
  radius: Style.radiusM
  border.color: Style.capsuleBorderColor
  border.width: Style.capsuleBorderWidth

  // property string currentIconName: pluginApi?.pluginSettings?.currentIconName || pluginApi?.manifest?.metadata?.defaultSettings?.currentIconName
  // property bool hideOnZero: pluginApi?.pluginSettings.hideOnZero || pluginApi?.manifest?.metadata.defaultSettings?.hideOnZero
  // readonly property bool isVisible: (root.pluginApi?.mainInstance?.updateCount > 0) || !root.hideOnZero
  // visible: root.isVisible
  // also set opacity to zero when invisible as we use opacity to hide the barWidgetLoader
  // opacity: root.isVisible ? 1.0 : 0.0


  //
  // ------ Widget ------
  //
  Item {
    id: layout
    anchors.centerIn: parent

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight

    GridLayout {
      id: grid
      columns: root.isVertical ? 1 : 2
      rowSpacing: Style.marginS
      columnSpacing: Style.marginS

      NIcon {
        id: playPauseIcon
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        icon: pluginApi.pluginSettings.paused ? "media-play" : "media-pause"
        color: root.hovered ? Color.mOnHover : Color.mOnSurface
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor

      onClicked: {
        pluginApi.pluginSettings.paused = !pluginApi.pluginSettings.paused;
        pluginApi.saveSettings();
        pluginApi.mainInstance.pause();
      }


      onEntered: {
        root.hovered = true;
      }

      onExited: {
        root.hovered = false;
      }
    }
  }
}