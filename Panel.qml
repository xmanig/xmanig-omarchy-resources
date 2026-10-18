import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "xmanig.resources"
  ipcTarget: "xmanig.resources"

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  readonly property string scriptPath: Model.urlToPath(Qt.resolvedUrl("scripts/collect-metrics"))
  property var metrics: ({
    cpu: -1,
    cores: [],
    ram: -1,
    ramUsedKiB: 0,
    ramTotalKiB: 0,
    gpu: -1,
    vramUsed: 0,
    vramTotal: 0,
    gpuName: "Unavailable"
  })

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color accent: Color.accent
  readonly property color dim: Qt.darker(foreground, 1.4)
  readonly property color track: Qt.darker(foreground, 2.2)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string barLabel: "CPU " + Model.formatPercent(metrics.cpu)
    + "  RAM " + Model.formatPercent(metrics.ram)
    + "  GPU " + Model.formatPercent(metrics.gpu)
  readonly property string barTooltip: "CPU " + Model.formatPercent(metrics.cpu)
    + " · RAM " + Model.formatPercent(metrics.ram)
    + " · GPU " + Model.formatPercent(metrics.gpu)
    + " · VRAM " + vramSummary()
  readonly property string summary: "CPU " + Model.formatPercent(metrics.cpu)
    + " · RAM " + Model.formatPercent(metrics.ram)
    + " · GPU " + Model.formatPercent(metrics.gpu)
  readonly property real ramFraction: metrics.ramTotalKiB > 0
    ? Math.max(0, Math.min(1, metrics.ramUsedKiB / metrics.ramTotalKiB))
    : 0
  readonly property real vramFraction: metrics.vramTotal > 0
    ? Math.max(0, Math.min(1, metrics.vramUsed / metrics.vramTotal))
    : 0

  function vramSummary() {
    if (metrics.vramTotal <= 0) return "—"
    return Model.formatBytes(metrics.vramUsed) + " / " + Model.formatBytes(metrics.vramTotal)
  }

  function refresh() {
    if (!metricsProc.running) metricsProc.running = true
  }

  function openFromHotkey() {
    open()
    refresh()
  }

  onOpenedChanged: if (opened) refresh()

  Process {
    id: metricsProc
    command: [root.scriptPath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var next = Model.parseMetrics(text)
        if (next.cpu >= 0 || next.ram >= 0 || next.gpu >= 0) root.metrics = next
      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(430))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTextKey: function(t) {
        if (t === "r") root.refresh()
      }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(10)

        PanelHero {
          width: parent.width
          title: "Resources"
          meta: root.summary
          foreground: root.foreground
          fontFamily: root.fontFamily
          iconComponent: Component {
            Text {
              textFormat: Text.PlainText
              text: ""
              color: root.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.display
            }
          }
          trailingControl: refreshButton
        }

        PanelSectionHeader {
          width: parent.width
          text: "CPU / CORES"
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        RowLayout {
          width: parent.width
          spacing: Style.space(8)

          Text {
            textFormat: Text.PlainText
            text: "Total CPU"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            Layout.preferredWidth: Style.space(82)
          }

          Rectangle {
            Layout.fillWidth: true
            height: Style.space(7)
            radius: height / 2
            color: root.track

            Rectangle {
              width: parent.width * (root.metrics.cpu < 0 ? 0 : root.metrics.cpu / 100)
              height: parent.height
              radius: height / 2
              color: root.accent
            }
          }

          Text {
            textFormat: Text.PlainText
            text: Model.formatPercent(root.metrics.cpu)
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: Style.space(42)
          }
        }

        ListView {
          id: coreList
          width: parent.width
          height: Math.min(contentHeight, Style.space(240))
          visible: count > 0
          clip: true
          spacing: Style.space(4)
          interactive: contentHeight > height
          boundsBehavior: Flickable.StopAtBounds
          ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
          model: root.metrics.cores

          delegate: RowLayout {
            required property var modelData
            required property int index
            width: ListView.view.width
            spacing: Style.space(8)

            Text {
              textFormat: Text.PlainText
              text: "Core " + (index + 1)
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              Layout.preferredWidth: Style.space(82)
            }

            Rectangle {
              Layout.fillWidth: true
              height: Style.space(5)
              radius: height / 2
              color: root.track

              Rectangle {
                width: parent.width * Math.max(0, Math.min(1, Number(modelData) / 100))
                height: parent.height
                radius: height / 2
                color: root.foreground
                opacity: 0.75
              }
            }

            Text {
              textFormat: Text.PlainText
              text: Model.formatPercent(Number(modelData))
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              horizontalAlignment: Text.AlignRight
              Layout.preferredWidth: Style.space(42)
            }
          }
        }

        PanelSectionHeader {
          width: parent.width
          text: "MEMORY"
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        RowLayout {
          width: parent.width
          spacing: Style.space(8)

          Text {
            textFormat: Text.PlainText
            text: "RAM"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            Layout.preferredWidth: Style.space(82)
          }

          Rectangle {
            Layout.fillWidth: true
            height: Style.space(7)
            radius: height / 2
            color: root.track

            Rectangle {
              width: parent.width * root.ramFraction
              height: parent.height
              radius: height / 2
              color: root.accent
            }
          }

          Text {
            textFormat: Text.PlainText
            text: Model.formatPercent(root.metrics.ram)
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: Style.space(42)
          }
        }

        Text {
          textFormat: Text.PlainText
          width: parent.width
          text: Model.formatKiB(root.metrics.ramUsedKiB) + " / " + Model.formatKiB(root.metrics.ramTotalKiB)
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignRight
        }

        PanelSectionHeader {
          width: parent.width
          text: "GPU / VRAM"
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        RowLayout {
          width: parent.width
          spacing: Style.space(8)

          Text {
            textFormat: Text.PlainText
            text: "GPU load"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            Layout.preferredWidth: Style.space(82)
          }

          Rectangle {
            Layout.fillWidth: true
            height: Style.space(7)
            radius: height / 2
            color: root.track

            Rectangle {
              width: parent.width * (root.metrics.gpu < 0 ? 0 : root.metrics.gpu / 100)
              height: parent.height
              radius: height / 2
              color: root.accent
            }
          }

          Text {
            textFormat: Text.PlainText
            text: Model.formatPercent(root.metrics.gpu)
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: Style.space(42)
          }
        }

        RowLayout {
          width: parent.width
          spacing: Style.space(8)

          Text {
            textFormat: Text.PlainText
            text: "VRAM"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            Layout.preferredWidth: Style.space(82)
          }

          Rectangle {
            Layout.fillWidth: true
            height: Style.space(7)
            radius: height / 2
            color: root.track

            Rectangle {
              width: parent.width * root.vramFraction
              height: parent.height
              radius: height / 2
              color: root.accent
            }
          }

          Text {
            textFormat: Text.PlainText
            text: root.vramSummary()
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: Style.space(105)
          }
        }

        Text {
          textFormat: Text.PlainText
          width: parent.width
          text: root.metrics.gpuName
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
          horizontalAlignment: Text.AlignRight
        }
      }

      Component {
        id: refreshButton
        PanelActionButton {
          iconText: ""
          tooltipText: "Refresh resource metrics"
          foreground: root.foreground
          hoverColor: root.accent
          onClicked: root.refresh()
        }
      }
    }
  }

  IpcHandler {
    target: "xmanig.resources-refresh"
    function refresh(): string {
      root.refresh()
      return "ok"
    }
  }
}
