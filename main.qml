import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import org.qfield
import Theme

/**
 * QField Traccar Client Plugin
 * Sends GPS position to a Traccar server using the OsmAnd HTTP protocol.
 * Protocol: GET /?id=<id>&timestamp=<unix>&lat=<lat>&lon=<lon>&speed=<speed>&bearing=<bearing>&altitude=<alt>&accuracy=<acc>
 *
 * Log feature mirrors traccar-client-android StatusActivity:
 *   - circular buffer of up to LOG_LIMIT timestamped entries
 *   - colour-coded (green / orange / red)
 *   - "Clear" button to clear
 *
 * All UI strings are wrapped in qsTr() for i18n.
 * Translation files live in i18n/<locale>.ts  (compiled to .qm at deploy time).
 */
Item {
    id: root

    // --- Persistent settings -------------------------------------------------
    Settings {
        id: cfg
        property string serverUrl: "http://traccar.intelligeo.net:5055"
        property string deviceId:  "qfield-device-1"
        property int    interval:  10
        property bool   tracking:  false
    }

    // --- Status banner -------------------------------------------------------
    property string statusText:  qsTr("Idle")
    property color  statusColor: "#888888"

    // --- Log model (max LOG_LIMIT entries, like StatusActivity) --------------
    readonly property int LOG_LIMIT: 20

    ListModel { id: logModel }

    function addLog(message, level) {
        var color = "#4CAF50"
        if      (level === "warn")  color = "#FF9800"
        else if (level === "error") color = "#F44336"

        var d   = new Date()
        var hh  = ("0" + d.getHours()).slice(-2)
        var mm  = ("0" + d.getMinutes()).slice(-2)
        var ss  = ("0" + d.getSeconds()).slice(-2)
        var entry = hh + ":" + mm + ":" + ss + " - " + message

        logModel.insert(0, { "msg": entry, "col": color })
        while (logModel.count > LOG_LIMIT)
            logModel.remove(logModel.count - 1)

        root.statusText  = message
        root.statusColor = color
    }

    // --- Toolbar button ------------------------------------------------------
    QfToolButton {
        id: traccarButton
        iconSource: Theme.getThemeVectorIcon("ic_cloud_upload_white_24dp")
        iconColor:  cfg.tracking ? "#4CAF50" : "#FFFFFF"
        bgcolor:    Theme.toolButtonBackgroundColor
        round:      true
        ToolTip.text: cfg.tracking ? qsTr("Traccar: active") : qsTr("Traccar: idle")
        onClicked:  settingsPopup.open()
    }

    // --- Main popup ----------------------------------------------------------
    // parent set in Component.onCompleted (Overlay.overlay is null in plugins)
    Popup {
        id: settingsPopup
        width:       Math.min(420, parent && parent.width > 0 ? parent.width - 32 : 380)
        height:      Math.min(parent && parent.height > 0 ? parent.height - 48 : 680,
                              contentCol.implicitHeight + 32)
        x:           parent ? (parent.width  - width)  / 2 : 0
        y:           parent ? (parent.height - height) / 2 : 0
        modal:       true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding:     16

        background: Rectangle {
            color:        "#1E1E1E"
            radius:       10
            border.color: "#444444"
            border.width: 1
        }

        ScrollView {
            anchors.fill: parent
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                id: contentCol
                width:   parent.width
                spacing: 12

                // Title
                Label {
                    text: qsTr("Traccar Client")
                    font.bold:       true
                    font.pixelSize:  16
                    color:           "#FFFFFF"
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

                // Status banner
                Rectangle {
                    Layout.fillWidth: true
                    height:       34
                    radius:       6
                    color:        Qt.alpha(root.statusColor, 0.20)
                    border.color: root.statusColor
                    border.width: 1
                    Label {
                        anchors.centerIn: parent
                        text:  root.statusText
                        color: root.statusColor
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        width: parent.width - 16
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Server URL
                Label { text: qsTr("Server URL"); color: "#AAAAAA"; font.pixelSize: 12 }
                TextField {
                    id: urlField
                    Layout.fillWidth: true
                    text:            cfg.serverUrl
                    placeholderText: "http://host:5055"
                    color:           "#FFFFFF"
                    background: Rectangle { color: "#2D2D2D"; radius: 4; border.color: "#555"; border.width: 1 }
                    onEditingFinished: cfg.serverUrl = text.trim()
                }

                // Device ID
                Label { text: qsTr("Device ID"); color: "#AAAAAA"; font.pixelSize: 12 }
                TextField {
                    id: deviceField
                    Layout.fillWidth: true
                    text:            cfg.deviceId
                    placeholderText: "my-device-id"
                    color:           "#FFFFFF"
                    background: Rectangle { color: "#2D2D2D"; radius: 4; border.color: "#555"; border.width: 1 }
                    onEditingFinished: cfg.deviceId = text.trim()
                }

                // Interval
                Label { text: qsTr("Interval (seconds)"); color: "#AAAAAA"; font.pixelSize: 12 }
                TextField {
                    id: intervalField
                    Layout.fillWidth: true
                    text:            cfg.interval.toString()
                    placeholderText: "30"
                    inputMethodHints: Qt.ImhDigitsOnly
                    color:           "#FFFFFF"
                    background: Rectangle { color: "#2D2D2D"; radius: 4; border.color: "#555"; border.width: 1 }
                    onEditingFinished: {
                        var v = parseInt(text)
                        if (v > 0) {
                            cfg.interval = v
                            sendTimer.interval = v * 1000
                        }
                    }
                }

                // Start / Stop
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Button {
                        text: qsTr("Start tracking")
                        Layout.fillWidth: true
                        enabled: !cfg.tracking
                        background: Rectangle { color: parent.enabled ? "#4CAF50" : "#333"; radius: 6 }
                        contentItem: Label {
                            text: parent.text; color: "#FFFFFF"
                            horizontalAlignment: Text.AlignHCenter
                        }
                        onClicked: {
                            cfg.serverUrl = urlField.text.trim()
                            cfg.deviceId  = deviceField.text.trim()
                            var v = parseInt(intervalField.text)
                            if (v > 0) cfg.interval = v
                            cfg.tracking = true
                            sendTimer.interval = cfg.interval * 1000
                            sendTimer.start()
                            traccarButton.iconColor = "#4CAF50"
                            root.addLog(qsTr("Tracking started (every %1 s)").arg(cfg.interval), "warn")
                        }
                    }

                    Button {
                        text: qsTr("Stop")
                        Layout.fillWidth: true
                        enabled: cfg.tracking
                        background: Rectangle { color: parent.enabled ? "#F44336" : "#333"; radius: 6 }
                        contentItem: Label {
                            text: parent.text; color: "#FFFFFF"
                            horizontalAlignment: Text.AlignHCenter
                        }
                        onClicked: {
                            cfg.tracking = false
                            sendTimer.stop()
                            traccarButton.iconColor = Theme.toolButtonColor
                            root.addLog(qsTr("Tracking stopped"), "warn")
                            root.statusText  = qsTr("Idle")
                            root.statusColor = "#888888"
                        }
                    }
                }

                // Separator
                Rectangle { Layout.fillWidth: true; height: 1; color: "#444444" }

                // Log header
                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: qsTr("Event log (last %1)").arg(root.LOG_LIMIT)
                        color: "#AAAAAA"; font.pixelSize: 12
                        Layout.fillWidth: true
                    }

                    Button {
                        text: qsTr("Clear")
                        padding: 6; leftPadding: 10; rightPadding: 10
                        background: Rectangle { color: "#333333"; radius: 4 }
                        contentItem: Label {
                            text: parent.text; color: "#CCCCCC"; font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                        }
                        onClicked: {
                            logModel.clear()
                            root.statusText  = qsTr("Log cleared")
                            root.statusColor = "#888888"
                        }
                    }
                }

                // Log list
                Rectangle {
                    Layout.fillWidth: true
                    height: Math.max(3, Math.min(8, logModel.count)) * 22 + 8
                    color:  "#141414"
                    radius: 6
                    border.color: "#333333"
                    border.width: 1
                    clip: true

                    ListView {
                        id: logView
                        anchors { fill: parent; margins: 4 }
                        model:          logModel
                        spacing:        2
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: Text {
                            width:          logView.width - 8
                            text:           model.msg
                            color:          model.col
                            font.pixelSize: 11
                            font.family:    "monospace"
                            elide:          Text.ElideRight
                            wrapMode:       Text.NoWrap
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        visible:         logModel.count === 0
                        text:            qsTr("No events recorded")
                        color:           "#555555"
                        font.pixelSize:  11
                        font.italic:     true
                    }
                }

                // Close
                Button {
                    Layout.fillWidth: true
                    text: qsTr("Close")
                    background: Rectangle { color: "#333333"; radius: 6 }
                    contentItem: Label {
                        text: parent.text; color: "#CCCCCC"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    onClicked: settingsPopup.close()
                }

            } // ColumnLayout
        } // ScrollView
    } // Popup

    // --- Periodic send timer -------------------------------------------------
    Timer {
        id: sendTimer
        interval: cfg.interval * 1000
        repeat:   true
        running:  false
        onTriggered: root.sendPosition()
    }

    // --- Core: read GPS and send ---------------------------------------------
    function sendPosition() {
        if (!cfg.tracking) return

        var posSource = iface.findItemByObjectName("positionSource")
        if (!posSource || !posSource.active) {
            root.addLog(qsTr("Positioning not active"), "error")
            return
        }

        var info = posSource.positionInformation
        if (!info || !info.latitudeValid || !info.longitudeValid) {
            root.addLog(qsTr("Waiting for GPS signal…"), "warn")
            return
        }

        var ts      = Math.floor(Date.now() / 1000)
        var lat     = info.latitude
        var lon     = info.longitude
        var alt     = info.elevationValid ? info.elevation : 0
        var speed   = info.speedValid     ? info.speed     : 0
        var bearing = info.directionValid ? info.direction : 0
        var hacc    = info.haccValid      ? info.hacc      : 0

        var base = cfg.serverUrl.replace(/\/+$/, "")
        var url  = base
                 + "?id="        + encodeURIComponent(cfg.deviceId)
                 + "&timestamp=" + ts
                 + "&lat="       + lat.toFixed(6)
                 + "&lon="       + lon.toFixed(6)
                 + "&speed="     + speed.toFixed(2)
                 + "&bearing="   + bearing.toFixed(1)
                 + "&altitude="  + alt.toFixed(1)
                 + "&accuracy="  + hacc.toFixed(1)

        root.addLog(qsTr("Sending → %1, %2").arg(lat.toFixed(5)).arg(lon.toFixed(5)), "warn")

        var xhr = new XMLHttpRequest()
        xhr.open("GET", url, true)
        xhr.timeout = 10000

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status >= 200 && xhr.status < 400) {
                root.addLog(qsTr("OK  lat=%1 lon=%2 acc=%3m")
                            .arg(lat.toFixed(5)).arg(lon.toFixed(5)).arg(hacc.toFixed(0)), "ok")
            } else {
                root.addLog(qsTr("HTTP error %1 – %2").arg(xhr.status).arg(xhr.statusText), "error")
            }
        }

        xhr.ontimeout = function() {
            root.addLog(qsTr("Timeout (%1)").arg(cfg.serverUrl), "error")
        }

        xhr.send()
    }

    // --- Init ----------------------------------------------------------------
    Component.onCompleted: {
        // Set popup parent after iface is ready (Overlay.overlay is null in plugins)
        settingsPopup.parent = iface.mainWindow().contentItem

        iface.addItemToPluginsToolbar(traccarButton)

        root.addLog(qsTr("Plugin loaded"), "ok")

        if (cfg.tracking) {
            sendTimer.interval = cfg.interval * 1000
            sendTimer.start()
            root.addLog(qsTr("Tracking resumed (every %1 s)").arg(cfg.interval), "warn")
        }
    }
}
