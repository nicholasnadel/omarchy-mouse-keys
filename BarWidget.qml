import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.nicholasnadel.mouse-keys"

  readonly property bool opened: panelController.open
  property bool popoutSwitchClosing: false
  property bool serviceLoaded: false
  property bool serviceActive: false
  property bool actionBusy: false
  property string actionError: ""
  readonly property color foreground: bar ? bar.barForeground : Color.foreground

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function open() { panelController.show() }
  function close() { panelController.hide() }
  function toggle() { opened ? close() : open() }
  function closeForPopoutSwitch() {
    popoutSwitchClosing = true
    close()
    Qt.callLater(function() { popoutSwitchClosing = false })
  }
  function switchPanel(direction) {
    if (bar && typeof bar.switchPanelFrom === "function")
      return bar.switchPanelFrom(root, direction)
    return false
  }

  function refreshStatus() {
    if (statusProcess.running || actionProcess.running) return
    statusProcess.running = true
  }

  function toggleService() {
    if (!serviceLoaded || actionBusy) return
    actionError = ""
    actionBusy = true
    actionProcess.command = ["/usr/bin/systemctl", "--user",
                             serviceActive ? "stop" : "start",
                             "kanata-mouse-keys.service"]
    actionProcess.running = true
  }

  onOpenedChanged: if (opened) refreshStatus()
  Component.onCompleted: refreshStatus()

  PanelController { id: panelController }

  Timer {
    interval: root.opened ? 500 : 5000
    running: true
    repeat: true
    onTriggered: root.refreshStatus()
  }

  Process {
    id: statusProcess
    command: ["/usr/bin/systemctl", "--user", "show", "--no-pager",
              "--property=LoadState,ActiveState", "kanata-mouse-keys.service"]
    stdout: StdioCollector { id: statusOutput; waitForEnd: true }
    onExited: function(exitCode) {
      var value = exitCode === 0 ? statusOutput.text : ""
      root.serviceLoaded = /(^|\n)LoadState=loaded(\n|$)/.test(value)
      root.serviceActive = root.serviceLoaded && /(^|\n)ActiveState=active(\n|$)/.test(value)
    }
  }

  Process {
    id: actionProcess
    onExited: function(exitCode) {
      root.actionBusy = false
      root.actionError = exitCode === 0 ? "" : "Could not change the mouse-key service."
      root.refreshStatus()
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "MK"
    foreground: root.serviceActive ? Color.accent : root.foreground
    tooltipText: root.serviceLoaded
      ? (root.serviceActive ? "Mouse keys enabled" : "Mouse keys disabled")
      : "Mouse keys setup needed"
    onPressed: root.toggle()
  }

  component KeyTile: Rectangle {
    id: tile
    property string keyLabel: ""
    property string actionLabel: ""
    property bool highlighted: false

    height: Style.space(44)
    radius: Style.space(5)
    color: highlighted ? Qt.alpha(Color.accent, 0.12)
                       : Qt.alpha(root.foreground, 0.04)
    border.width: 1
    border.color: highlighted ? Color.accent
                              : Qt.alpha(root.foreground, 0.22)

    Column {
      anchors.centerIn: parent
      spacing: 0

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: tile.keyLabel
        textFormat: Text.PlainText
        color: tile.highlighted ? Color.accent : root.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: tile.actionLabel
        textFormat: Text.PlainText
        color: Color.muted
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(10)

        Text {
          width: parent.width
          text: "Mouse Keys"
          textFormat: Text.PlainText
          color: root.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.subtitle
          font.bold: true
        }

        Text {
          width: parent.width
          text: root.serviceLoaded
            ? (root.serviceActive ? "Enabled" : "Disabled")
            : "Setup needed"
          textFormat: Text.PlainText
          color: root.serviceActive ? Color.accent : Color.muted
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
        }

        Row {
          width: parent.width
          spacing: Style.space(8)

          KeyTile {
            width: Style.space(52)
            keyLabel: "d"
            actionLabel: "hold"
            highlighted: true
          }

          Text {
            width: parent.width - Style.space(60)
            anchors.verticalCenter: parent.verticalCenter
            text: "Hold briefly for mouse keys. Release to type."
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            color: root.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.bodySmall
          }
        }

        Rectangle {
          width: parent.width
          implicitHeight: keyMap.implicitHeight + Style.space(16)
          radius: Style.space(5)
          color: Qt.alpha(root.foreground, 0.03)
          border.width: 1
          border.color: Qt.alpha(root.foreground, 0.17)

          Column {
            id: keyMap
            width: parent.width - Style.space(16)
            anchors.centerIn: parent
            spacing: Style.space(6)

            Text {
              text: "MOVE"
              textFormat: Text.PlainText
              color: Color.muted
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Row {
              width: parent.width
              spacing: Style.space(6)
              KeyTile { width: (parent.width - 3 * parent.spacing) / 4; keyLabel: "h"; actionLabel: "←" }
              KeyTile { width: (parent.width - 3 * parent.spacing) / 4; keyLabel: "j"; actionLabel: "↓" }
              KeyTile { width: (parent.width - 3 * parent.spacing) / 4; keyLabel: "k"; actionLabel: "↑" }
              KeyTile { width: (parent.width - 3 * parent.spacing) / 4; keyLabel: "l"; actionLabel: "→" }
            }

            Text {
              text: "CLICK"
              textFormat: Text.PlainText
              color: Color.muted
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Row {
              width: parent.width
              spacing: Style.space(6)
              KeyTile { width: (parent.width - 2 * parent.spacing) / 3; keyLabel: "v"; actionLabel: "left" }
              KeyTile { width: (parent.width - 2 * parent.spacing) / 3; keyLabel: "b"; actionLabel: "right" }
              KeyTile { width: (parent.width - 2 * parent.spacing) / 3; keyLabel: "n"; actionLabel: "middle" }
            }

            Text {
              text: "ADJUST"
              textFormat: Text.PlainText
              color: Color.muted
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Row {
              width: parent.width
              spacing: Style.space(6)
              KeyTile { width: (parent.width - 2 * parent.spacing) / 3; keyLabel: "s"; actionLabel: "scroll" }
              KeyTile { width: (parent.width - 2 * parent.spacing) / 3; keyLabel: "f"; actionLabel: "faster" }
              KeyTile { width: (parent.width - 2 * parent.spacing) / 3; keyLabel: "g"; actionLabel: "slower" }
            }

            Text {
              text: "hold s with h/j/k/l to scroll"
              textFormat: Text.PlainText
              color: Color.muted
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
        }

        Button {
          text: root.serviceLoaded
            ? (root.serviceActive ? "Disable mouse keys" : "Enable mouse keys")
            : "Open setup guide"
          foreground: root.foreground
          bordered: true
          enabled: !root.actionBusy
          onClicked: {
            if (root.serviceLoaded) root.toggleService()
            else Qt.openUrlExternally("https://github.com/nicholasnadel/omarchy-mouse-keys#install")
          }
        }

        Text {
          visible: root.actionError !== ""
          width: parent.width
          text: root.actionError
          textFormat: Text.PlainText
          wrapMode: Text.WordWrap
          color: Color.muted
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.bodySmall
        }
      }
    }
  }
}
