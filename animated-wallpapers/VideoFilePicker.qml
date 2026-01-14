// Based on the FilePicker.qml from the Noctalia filepicker widget
// src: https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NFilePicker.qml

import Qt.labs.folderlistmodel
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Popup {
  id: root

  // Properties
  property string title: "Video Picker"
  property string initialPath: Quickshell.env("HOME") || "/home"
  property string selectionMode: "files" // "files" or "folders"
  property var nameFilters: ["*.mp4"]
  property bool showDirs: true
  property bool showHiddenFiles: false

  property var selectedPaths: []
  property string currentPath: initialPath
  property bool shouldResetSelection: false

  // Signals
  signal accepted(var paths)
  signal cancelled

  function openFilePicker() {
    if (!root.currentPath)
      root.currentPath = root.initialPath;
    shouldResetSelection = true;
    open();
  }

  function getFileIcon(fileName) {
    const ext = fileName.split('.').pop().toLowerCase();
    const iconMap = {
      "mp4": 'filepicker-video'
    };
    return iconMap[ext] || 'filepicker-file';
  }

  function formatFileSize(bytes) {
    if (bytes === 0)
      return "0 B";
    const k = 1024, sizes = ["B", "KB", "MB", "GB", "TB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i];
  }

  function confirmSelection() {
    if (filePickerPanel.currentSelection.length === 0)
      return;
    root.selectedPaths = filePickerPanel.currentSelection;
    root.accepted(filePickerPanel.currentSelection);
    root.close();
  }

  function updateFilteredModel() {
    filteredModel.clear();
    const searchText = filePickerPanel.filterText.toLowerCase();

    for (var i = 0; i < folderModel.count; i++) {
      const fileName = folderModel.get(i, "fileName");
      const filePath = folderModel.get(i, "filePath");
      const fileIsDir = folderModel.get(i, "fileIsDir");
      const fileSize = folderModel.get(i, "fileSize");

      // Skip hidden items if showHiddenFiles is false
      // This additional check ensures hidden files are properly filtered
      if (!root.showHiddenFiles && fileName.startsWith(".")) {
        continue;
      }

      // In folder mode, hide files
      if (root.selectionMode === "folders" && !fileIsDir)
        continue;
      if (searchText === "" || fileName.toLowerCase().includes(searchText)) {
        filteredModel.append({
                               "fileName": fileName,
                               "filePath": filePath,
                               "fileIsDir": fileIsDir,
                               "fileSize": fileSize
                             });
      }
    }
  }

  width: 900
  height: 700
  modal: true
  closePolicy: Popup.CloseOnEscape
  anchors.centerIn: Overlay.overlay

  background: Rectangle {
    color: Color.mSurfaceVariant
    radius: Style.iRadiusL
    border.color: Color.mOutline
    border.width: Style.borderS
  }

  Rectangle {
    id: filePickerPanel
    anchors.fill: parent
    anchors.margins: Style.marginL
    color: "transparent"

    property string filterText: ""
    property var currentSelection: []
    property bool viewMode: true // true = grid, false = list
    property string searchText: ""
    property bool showSearchBar: false

    focus: true

    Keys.onPressed: event => {
                      if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_F) {
                        filePickerPanel.showSearchBar = !filePickerPanel.showSearchBar;
                        if (filePickerPanel.showSearchBar)
                        Qt.callLater(() => searchInput.forceActiveFocus());
                        event.accepted = true;
                      } else if (event.key === Qt.Key_Escape && filePickerPanel.showSearchBar) {
                        filePickerPanel.showSearchBar = false;
                        filePickerPanel.searchText = "";
                        filePickerPanel.filterText = "";
                        root.updateFilteredModel();
                        event.accepted = true;
                      }
                    }

    ColumnLayout {
      anchors.fill: parent
      spacing: Style.marginM

      // Header
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NIcon {
          icon: "filepicker-folder"
          color: Color.mPrimary
          pointSize: Style.fontSizeXXL
        }
        NText {
          text: root.title
          pointSize: Style.fontSizeXL
          font.weight: Style.fontWeightBold
          color: Color.mPrimary
          Layout.fillWidth: true
        }

        // "Select Current" button only visible in folder selection mode
        NButton {
          text: "Select Current"
          icon: "filepicker-folder-current"
          visible: root.selectionMode === "folders"
          onClicked: {
            filePickerPanel.currentSelection = [root.currentPath];
            root.confirmSelection();
          }
        }

        NIconButton {
          icon: "filepicker-refresh"
          tooltipText: "Refresh"
          onClicked: {
            // Force a proper refresh by resetting the folder
            const currentFolder = folderModel.folder;
            folderModel.folder = "";
            folderModel.folder = currentFolder;
            Qt.callLater(root.updateFilteredModel);
          }
        }
        NIconButton {
          icon: "filepicker-close"
          tooltipText: "Close"
          onClicked: {
            root.cancelled();
            root.close();
          }
        }
      }

      NDivider {
        Layout.fillWidth: true
      }

      // Navigation toolbar
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 45
        color: Color.mSurfaceVariant
        radius: Style.iRadiusS
        border.color: Color.mOutline
        border.width: Style.borderS

        RowLayout {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          anchors.leftMargin: Style.marginS
          anchors.rightMargin: Style.marginS
          spacing: Style.marginS

          NIconButton {
            icon: "filepicker-arrow-up"
            tooltipText: "Go Up"
            baseSize: Style.baseWidgetSize * 0.8
            enabled: folderModel.folder.toString() !== "file:///"
            onClicked: {
              const parentPath = folderModel.parentFolder.toString().replace("file://", "");
              folderModel.folder = "file://" + parentPath;
              root.currentPath = parentPath;
            }
          }

          NIconButton {
            icon: "filepicker-home"
            tooltipText: "Home"
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: {
              const homePath = Quickshell.env("HOME") || "/home";
              folderModel.folder = "file://" + homePath;
              root.currentPath = homePath;
            }
          }

          NIconButton {
            icon: filePickerPanel.showSearchBar ? "filepicker-x" : "filepicker-search"
            tooltipText: filePickerPanel.showSearchBar ? "Close Search" : "Search"
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: {
              filePickerPanel.showSearchBar = !filePickerPanel.showSearchBar;
              if (!filePickerPanel.showSearchBar) {
                filePickerPanel.searchText = "";
                filePickerPanel.filterText = "";
                root.updateFilteredModel();
              }
            }
          }

          NTextInput {
            id: locationInput
            text: root.currentPath
            placeholderText: "Enter path..."
            Layout.fillWidth: true

            visible: !filePickerPanel.showSearchBar
            enabled: !filePickerPanel.showSearchBar

            onEditingFinished: {
              const newPath = text.trim();
              if (newPath !== "" && newPath !== root.currentPath) {
                folderModel.folder = "file://" + newPath;
                root.currentPath = newPath;
              } else {
                text = root.currentPath;
              }
            }
            Connections {
              target: root
              function onCurrentPathChanged() {
                if (!locationInput.activeFocus)
                  locationInput.text = root.currentPath;
              }
            }
          }

          // Search bar
          NTextInput {
            id: searchInput
            inputIconName: "search"
            placeholderText: "Search"
            Layout.fillWidth: true

            visible: filePickerPanel.showSearchBar
            enabled: filePickerPanel.showSearchBar

            text: filePickerPanel.searchText
            onTextChanged: {
              filePickerPanel.searchText = text;
              filePickerPanel.filterText = text;
              root.updateFilteredModel();
            }
            Keys.onEscapePressed: {
              filePickerPanel.showSearchBar = false;
              filePickerPanel.searchText = "";
              filePickerPanel.filterText = "";
              root.updateFilteredModel();
            }
          }

          NIconButton {
            icon: filePickerPanel.viewMode ? "filepicker-list" : "filepicker-layout-grid"
            tooltipText: filePickerPanel.viewMode ? "List View" : "Grid View"
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: filePickerPanel.viewMode = !filePickerPanel.viewMode
          }
          NIconButton {
            icon: root.showHiddenFiles ? "filepicker-eye-off" : "filepicker-eye"
            tooltipText: root.showHiddenFiles ? "Hide Hidden Files" : "Show Hidden Files"
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: {
              root.showHiddenFiles = !root.showHiddenFiles;
              // Force model refresh by resetting the folder
              const currentFolder = folderModel.folder;
              folderModel.folder = "";
              folderModel.folder = currentFolder;
              Qt.callLater(root.updateFilteredModel);
            }
          }
        }
      }

      // File list area
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Color.mSurface
        radius: Style.iRadiusM
        border.color: Color.mOutline
        border.width: Style.borderS

        FolderListModel {
          id: folderModel
          folder: "file://" + root.currentPath
          // Use wildcard filters including hidden files when showHiddenFiles is true
          nameFilters: root.showHiddenFiles ? ["*.mp4", ".*.mp4"] : root.nameFilters
          showDirs: root.showDirs
          showHidden: true // Always true, we'll filter in updateFilteredModel
          showDotAndDotDot: false
          sortField: FolderListModel.Name
          sortReversed: false

          onFolderChanged: {
            root.currentPath = folder.toString().replace("file://", "");
            filePickerPanel.currentSelection = [];
            Qt.callLater(root.updateFilteredModel);
          }

          onStatusChanged: {
            if (status === FolderListModel.Error) {
              if (root.currentPath !== Quickshell.env("HOME")) {
                folder = "file://" + Quickshell.env("HOME");
                root.currentPath = Quickshell.env("HOME");
              }
            } else if (status === FolderListModel.Ready) {
              root.updateFilteredModel();
            }
          }
        }

        // Update nameFilters when showHiddenFiles changes
        Connections {
          target: root
          function onShowHiddenFilesChanged() {
            folderModel.nameFilters = root.showHiddenFiles ? ["*.mp4", ".*.mp4"] : root.nameFilters;
          }
        }

        ListModel {
          id: filteredModel
        }

        // Common scroll bar component
        Component {
          id: scrollBarComponent
          ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
              implicitWidth: 6
              implicitHeight: 100
              radius: Style.iRadiusM
              color: Qt.alpha(Color.mHover, 0.8)
              opacity: parent.policy === ScrollBar.AlwaysOn || parent.active ? 1.0 : 0.0
              Behavior on opacity {
                NumberAnimation {
                  duration: Style.animationFast
                }
              }
              Behavior on color {
                ColorAnimation {
                  duration: Style.animationFast
                }
              }
            }
            background: Rectangle {
              implicitWidth: 6
              implicitHeight: 100
              color: "transparent"
              opacity: parent.policy === ScrollBar.AlwaysOn || parent.active ? 0.3 : 0.0
              radius: (Style.iRadiusM) / 2
              Behavior on opacity {
                NumberAnimation {
                  duration: Style.animationFast
                }
              }
            }
          }
        }

        // Grid view
        GridView {
          id: gridView
          anchors.fill: parent
          anchors.margins: Style.marginM
          model: filteredModel
          visible: filePickerPanel.viewMode
          clip: true
          reuseItems: true

          property int columns: Math.max(1, Math.floor(width / (120)))
          property int itemSize: Math.floor((width - leftMargin - rightMargin - (columns * Style.marginS)) / columns)

          cellWidth: Math.floor((width - leftMargin - rightMargin) / columns)
          cellHeight: Math.floor(itemSize * 0.8) + Style.marginXS + Style.fontSizeS + Style.marginM

          leftMargin: Style.marginS
          rightMargin: Style.marginS
          topMargin: Style.marginS
          bottomMargin: Style.marginS

          ScrollBar.vertical: scrollBarComponent.createObject(gridView, {
                                                                "parent": gridView,
                                                                "x": gridView.mirrored ? 0 : gridView.width - width,
                                                                "y": 0,
                                                                "height": gridView.height
                                                              })

          delegate: Rectangle {
            id: gridItem
            width: gridView.itemSize
            height: gridView.cellHeight
            color: "transparent"
            radius: Style.iRadiusM

            property bool isSelected: filePickerPanel.currentSelection.includes(model.filePath)

            Rectangle {
              anchors.fill: parent
              color: "transparent"
              radius: parent.radius
              border.color: isSelected ? Color.mSecondary : Color.mSurface
              border.width: Style.borderL
              Behavior on color {
                ColorAnimation {
                  duration: Style.animationFast
                }
              }
            }

            Rectangle {
              anchors.fill: parent
              color: (mouseArea.containsMouse && !isSelected) ? Color.mHover : "transparent"
              radius: parent.radius
              border.color: (mouseArea.containsMouse && !isSelected) ? Color.mHover : "transparent"
              border.width: Style.borderS
              Behavior on color {
                ColorAnimation {
                  duration: Style.animationFast
                }
              }
              Behavior on border.color {
                ColorAnimation {
                  duration: Style.animationFast
                }
              }
            }

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: Style.marginS
              spacing: Style.marginXS

              Rectangle {
                id: iconContainer
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(gridView.itemSize * 0.67)
                color: "transparent"

                property bool isImage: false

                property bool generationAttempted: false
                property string currentPath: model.filePath
                onCurrentPathChanged: generationAttempted = false

                Process {
                  id: thumbGen
                  onRunningChanged: {
                    if (!running) {
                       const src = thumbnail.source;
                       thumbnail.source = "";
                       thumbnail.source = src;
                    }
                  }
                }

                property bool isVideo: {
                  if (model.fileIsDir)
                    return false;
                  const ext = model.fileName.split('.').pop().toLowerCase();
                  return ['mp4'].includes(ext);
                }

                property bool supportsThumbnail: isVideo

                Image {
                  id: thumbnail
                  anchors.fill: parent
                  anchors.margins: Style.marginXS
                  source: {
                    if (iconContainer.isImage) return "file://" + model.filePath;
                    if (iconContainer.isVideo) {
                      const path = model.filePath.toString();
                      const dot = path.lastIndexOf('.');
                      return "file://" + path.substring(0, dot) + ".jpg";
                    }
                    return "";
                  }
                  fillMode: Image.PreserveAspectFit
                  visible: iconContainer.supportsThumbnail && status === Image.Ready
                  smooth: false
                  cache: true
                  asynchronous: true
                  sourceSize.width: 120
                  sourceSize.height: 120
                  onStatusChanged: {
                     if (status === Image.Error && iconContainer.isVideo && !iconContainer.generationAttempted) {
                        iconContainer.generationAttempted = true;
                        const path = model.filePath.toString();
                        const dot = path.lastIndexOf('.');
                        const thumbPath = path.substring(0, dot) + ".jpg";
                        const command = ["ffmpeg", "-y", "-i", path, "-ss", "00:00:01", "-vframes", "1", thumbPath];
                        thumbGen.exec(command);
                        Logger.i("animated-wallpapers", "Generating thumbnail with command: " + command.join(" "));
                     }
                  }

                  Rectangle {
                    anchors.fill: parent
                    color: Color.mSurfaceVariant
                    radius: Style.iRadiusS
                    visible: thumbnail.status === Image.Loading
                    NIcon {
                      icon: "filepicker-photo"
                      pointSize: Style.fontSizeL
                      color: Color.mOnSurfaceVariant
                      anchors.centerIn: parent
                    }
                  }
                }

                NIcon {
                  icon: model.fileIsDir ? "filepicker-folder" : root.getFileIcon(model.fileName)
                  pointSize: Style.fontSizeXXL * 2
                  color: {
                    if (isSelected)
                      return Color.mSecondary;
                    else if (mouseArea.containsMouse)
                      return Color.mOnHover;
                    else
                      return model.fileIsDir ? Color.mPrimary : Color.mOnSurfaceVariant;
                  }
                  anchors.centerIn: parent
                  visible: !iconContainer.supportsThumbnail || thumbnail.status !== Image.Ready
                }

                Rectangle {
                  anchors.top: parent.top
                  anchors.right: parent.right
                  anchors.margins: Style.marginS
                  width: 24
                  height: 24
                  radius: Math.min(Style.iRadiusL, width / 2)
                  color: Color.mSecondary
                  border.color: Color.mOutline
                  border.width: Style.borderS
                  visible: isSelected
                  NIcon {
                    icon: "filepicker-check"
                    pointSize: Style.fontSizeS
                    color: Color.mOnSecondary
                    anchors.centerIn: parent
                  }
                }
              }

              NText {
                text: model.fileName
                color: {
                  if (isSelected)
                    return Color.mSecondary;
                  else if (mouseArea.containsMouse)
                    return Color.mOnHover;
                  else
                    return Color.mOnSurfaceVariant;
                }
                pointSize: Style.fontSizeS
                font.weight: isSelected ? Style.fontWeightBold : Style.fontWeightRegular
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAnywhere
                elide: Text.ElideRight
                maximumLineCount: 2
              }
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.RightButton

              onClicked: mouse => {
                           if (mouse.button === Qt.LeftButton) {
                             if (model.fileIsDir) {
                               // In folder mode, single click selects the folder
                               if (root.selectionMode === "folders") {
                                 filePickerPanel.currentSelection = [model.filePath];
                               }
                               // In file mode, single click on folder does nothing (must double-click to enter)
                             } else {
                               // Single click on file selects it (only in file mode)
                               if (root.selectionMode === "files") {
                                 filePickerPanel.currentSelection = [model.filePath];
                               }
                             }
                           }
                         }

              onDoubleClicked: mouse => {
                                 if (mouse.button === Qt.LeftButton) {
                                   if (model.fileIsDir) {
                                     // Double-click on folder always navigates into it
                                     folderModel.folder = "file://" + model.filePath;
                                     root.currentPath = model.filePath;
                                   } else {
                                     // Double-click on file selects and confirms (only in file mode)
                                     if (root.selectionMode === "files") {
                                       filePickerPanel.currentSelection = [model.filePath];
                                       root.confirmSelection();
                                     }
                                   }
                                 }
                               }
            }
          }
        }

        // List view
        NListView {
          id: listView
          anchors.fill: parent
          anchors.margins: Style.marginS
          model: filteredModel
          visible: !filePickerPanel.viewMode

          delegate: Rectangle {
            id: listItem
            width: listView.width
            height: 40
            color: {
              if (filePickerPanel.currentSelection.includes(model.filePath))
                return Color.mSecondary;
              if (mouseArea.containsMouse)
                return Color.mHover;
              return "transparent";
            }
            radius: Style.iRadiusS
            Behavior on color {
              ColorAnimation {
                duration: Style.animationFast
              }
            }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: Style.marginM
              anchors.rightMargin: Style.marginM
              spacing: Style.marginM

              NIcon {
                icon: model.fileIsDir ? "filepicker-folder" : root.getFileIcon(model.fileName)
                pointSize: Style.fontSizeL
                color: model.fileIsDir ? (filePickerPanel.currentSelection.includes(model.filePath) ? Color.mOnSecondary : Color.mPrimary) : Color.mOnSurfaceVariant
              }

              NText {
                text: model.fileName
                color: filePickerPanel.currentSelection.includes(model.filePath) ? Color.mOnSecondary : Color.mOnSurface
                pointSize: Style.fontSizeM
                font.weight: filePickerPanel.currentSelection.includes(model.filePath) ? Style.fontWeightBold : Style.fontWeightRegular
                Layout.fillWidth: true
                elide: Text.ElideRight
              }

              NText {
                text: model.fileIsDir ? "" : root.formatFileSize(model.fileSize)
                color: filePickerPanel.currentSelection.includes(model.filePath) ? Color.mOnSecondary : Color.mOnSurfaceVariant
                pointSize: Style.fontSizeS
                visible: !model.fileIsDir
                Layout.preferredWidth: implicitWidth
              }
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.RightButton

              onClicked: mouse => {
                           if (mouse.button === Qt.LeftButton) {
                             if (model.fileIsDir) {
                               // In folder mode, single click selects the folder
                               if (root.selectionMode === "folders") {
                                 filePickerPanel.currentSelection = [model.filePath];
                               }
                               // In file mode, single click on folder does nothing (must double-click to enter)
                             } else {
                               // Single click on file selects it (only in file mode)
                               if (root.selectionMode === "files") {
                                 filePickerPanel.currentSelection = [model.filePath];
                               }
                             }
                           }
                         }

              onDoubleClicked: mouse => {
                                 if (mouse.button === Qt.LeftButton) {
                                   if (model.fileIsDir) {
                                     // Double-click on folder always navigates into it
                                     folderModel.folder = "file://" + model.filePath;
                                     root.currentPath = model.filePath;
                                   } else {
                                     // Double-click on file selects and confirms (only in file mode)
                                     if (root.selectionMode === "files") {
                                       filePickerPanel.currentSelection = [model.filePath];
                                       root.confirmSelection();
                                     }
                                   }
                                 }
                               }
            }
          }
        }
      }

      // Footer
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NText {
          text: {
            if (filePickerPanel.searchText.length > 0) {
              return "Searching for: \"" + filePickerPanel.searchText + "\" (" + filteredModel.count + " matches)";
            } else if (filePickerPanel.currentSelection.length > 0) {
              const selectedName = filePickerPanel.currentSelection[0].split('/').pop();
              return "Selected: " + selectedName;
            } else {
              return filteredModel.count + " items";
            }
          }
          color: filePickerPanel.searchText.length > 0 ? Color.mPrimary : Color.mOnSurfaceVariant
          pointSize: Style.fontSizeS
          Layout.fillWidth: true
        }

        NButton {
          text: "Cancel"
          outlined: true
          onClicked: {
            root.cancelled();
            root.close();
          }
        }

        NButton {
          text: root.selectionMode === "folders" ? "Select Folder" : "Select File"
          icon: "filepicker-check"
          enabled: filePickerPanel.currentSelection.length > 0
          onClicked: root.confirmSelection()
        }
      }
    }

    Connections {
      target: root
      function onShouldResetSelectionChanged() {
        if (root.shouldResetSelection) {
          filePickerPanel.currentSelection = [];
          root.shouldResetSelection = false;
        }
      }
    }

    Component.onCompleted: {
      if (!root.currentPath)
        root.currentPath = root.initialPath;
      folderModel.folder = "file://" + root.currentPath;
    }
  }
}