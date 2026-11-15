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
    interval: 5000
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
      ? (root.serviceActive ? "Mouse keys active" : "Mouse keys stopped")
      : "Mouse keys setup needed"
    onPressed: root.toggle()
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
            ? (root.serviceActive ? "Active" : "Stopped")
            : "Setup needed"
          textFormat: Text.PlainText
          color: root.serviceActive ? Color.accent : Color.muted
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
        }

        Text {
          width: parent.width
          text: "Hold Right Command/Super, tap M; or hold D and press a mouse key. "
              + "H/J/K/L move · V/B/N click · hold S to scroll."
          textFormat: Text.PlainText
          wrapMode: Text.WordWrap
          color: root.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
        }

        Button {
          text: root.serviceLoaded
            ? (root.serviceActive ? "Stop mouse keys" : "Start mouse keys")
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
