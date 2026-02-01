import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Item {
    id: root
    property var pluginApi: null
    property var screen: null

    // SmartPanel properties
    readonly property bool allowAttach: true
    property real contentPreferredWidth: 300 * Style.uiScaleRatio
    property real contentPreferredHeight: content.implicitHeight + (Style.marginL * 2)

    // Settings - configured UPS name
    readonly property string configuredUpsName: pluginApi?.pluginSettings?.upsName || ""

    // Auto-detected or configured UPS name
    property string detectedUpsName: ""
    readonly property string activeUpsName: configuredUpsName || detectedUpsName

    // UPS data
    property int batteryCharge: -1
    property string upsStatus: ""
    property string upsModel: ""
    property string upsMfr: ""
    property real inputVoltage: -1
    property real outputVoltage: -1
    property real batteryVoltage: -1
    property real upsLoad: -1
    property real upsTemp: -1
    property bool upsAvailable: false

    // Status parsing
    readonly property bool isOnline: upsStatus.indexOf("OL") >= 0
    readonly property bool isOnBattery: upsStatus.indexOf("OB") >= 0
    readonly property bool isLowBattery: upsStatus.indexOf("LB") >= 0
    readonly property bool isCharging: upsStatus.indexOf("CHRG") >= 0

    anchors.fill: parent

    Component.onCompleted: {
        startQuery();
    }

    // Re-query when activeUpsName becomes available (handles late pluginApi injection)
    onActiveUpsNameChanged: {
        if (activeUpsName && !upsAvailable) {
            upsProcess.running = true;
        }
    }

    function startQuery() {
        // Auto-detect UPS if not configured
        if (!configuredUpsName) {
            upsListProcess.running = true;
        } else if (activeUpsName) {
            upsProcess.running = true;
        }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Style.marginL
        spacing: Style.marginM

        // Header
        NText {
            Layout.fillWidth: true
            font.weight: Style.fontWeightBold
            pointSize: Style.fontSizeL
            text: "UPS Status"
        }

        // UPS name subheader
        NText {
            Layout.fillWidth: true
            visible: root.activeUpsName
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeS
            text: root.activeUpsName
        }

        // No UPS found
        NText {
            Layout.fillWidth: true
            visible: !root.activeUpsName
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeM
            text: "No UPS found. Is NUT running?"
        }

        // UPS info
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginS
            visible: root.activeUpsName && root.upsAvailable

            // Model info
            NText {
                Layout.fillWidth: true
                visible: root.upsMfr || root.upsModel
                color: Color.mOnSurfaceVariant
                pointSize: Style.fontSizeS
                text: (root.upsMfr ? root.upsMfr + " " : "") + (root.upsModel || "")
            }

            NDivider {
                Layout.fillWidth: true
            }

            // Status row
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                NText {
                    pointSize: Style.fontSizeM
                    text: "Status"
                }
                Item { Layout.fillWidth: true }
                NText {
                    pointSize: Style.fontSizeM
                    color: root.isOnBattery ? Color.mTertiary : Color.mPrimary
                    text: {
                        var status = root.isOnline ? "Online" : (root.isOnBattery ? "On Battery" : "Unknown");
                        if (root.isCharging) status += " (Charging)";
                        if (root.isLowBattery) status += " - LOW";
                        return status;
                    }
                }
            }

            // Battery charge
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM
                visible: root.batteryCharge >= 0

                NText {
                    pointSize: Style.fontSizeM
                    text: "Battery"
                }
                Item { Layout.fillWidth: true }
                NText {
                    pointSize: Style.fontSizeM
                    color: root.batteryCharge <= 20 ? Color.mError :
                           (root.batteryCharge <= 40 ? Color.mTertiary : Color.mOnSurface)
                    text: root.batteryCharge + "%"
                }
            }

            // Load
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM
                visible: root.upsLoad >= 0

                NText {
                    pointSize: Style.fontSizeM
                    text: "Load"
                }
                Item { Layout.fillWidth: true }
                NText {
                    pointSize: Style.fontSizeM
                    text: root.upsLoad.toFixed(0) + "%"
                }
            }

            // Input voltage
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM
                visible: root.inputVoltage >= 0

                NText {
                    pointSize: Style.fontSizeM
                    text: "Input Voltage"
                }
                Item { Layout.fillWidth: true }
                NText {
                    pointSize: Style.fontSizeM
                    text: root.inputVoltage.toFixed(1) + " V"
                }
            }

            // Output voltage
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM
                visible: root.outputVoltage >= 0

                NText {
                    pointSize: Style.fontSizeM
                    text: "Output Voltage"
                }
                Item { Layout.fillWidth: true }
                NText {
                    pointSize: Style.fontSizeM
                    text: root.outputVoltage.toFixed(1) + " V"
                }
            }

            // Battery voltage
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM
                visible: root.batteryVoltage >= 0

                NText {
                    pointSize: Style.fontSizeM
                    text: "Battery Voltage"
                }
                Item { Layout.fillWidth: true }
                NText {
                    pointSize: Style.fontSizeM
                    text: root.batteryVoltage.toFixed(1) + " V"
                }
            }

            // Temperature
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM
                visible: root.upsTemp >= 0

                NText {
                    pointSize: Style.fontSizeM
                    text: "Temperature"
                }
                Item { Layout.fillWidth: true }
                NText {
                    pointSize: Style.fontSizeM
                    text: root.upsTemp.toFixed(1) + " C"
                }
            }
        }

        // UPS unavailable
        NText {
            Layout.fillWidth: true
            visible: root.activeUpsName && !root.upsAvailable
            color: Color.mError
            pointSize: Style.fontSizeM
            text: "Cannot connect to UPS: " + root.activeUpsName
        }
    }

    // UPS list process for auto-detection
    Process {
        id: upsListProcess

        property string collectedOutput: ""

        command: ["upsc", "-l"]

        stdout: SplitParser {
            onRead: function(data) {
                upsListProcess.collectedOutput += data + "\n";
            }
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0 && collectedOutput) {
                var lines = collectedOutput.trim().split('\n');
                if (lines.length > 0 && lines[0].trim()) {
                    root.detectedUpsName = lines[0].trim();
                    upsProcess.running = true;
                }
            }
            collectedOutput = "";
        }
    }

    Process {
        id: upsProcess

        property string collectedOutput: ""

        command: ["upsc", root.activeUpsName]

        stdout: SplitParser {
            onRead: function(data) {
                upsProcess.collectedOutput += data + "\n";
            }
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0 && collectedOutput) {
                root.upsAvailable = true;
                root.parseUpsOutput(collectedOutput);
            } else {
                root.upsAvailable = false;
            }
            collectedOutput = "";
        }
    }

    function parseUpsOutput(output) {
        var lines = output.split('\n');
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            var colonIdx = line.indexOf(":");
            if (colonIdx < 0) continue;

            var key = line.substring(0, colonIdx).trim();
            var value = line.substring(colonIdx + 1).trim();

            switch (key) {
                case "battery.charge":
                    var charge = parseInt(value, 10);
                    if (!isNaN(charge)) batteryCharge = charge;
                    break;
                case "ups.status":
                    upsStatus = value;
                    break;
                case "ups.model":
                    upsModel = value;
                    break;
                case "ups.mfr":
                    upsMfr = value;
                    break;
                case "input.voltage":
                    var iv = parseFloat(value);
                    if (!isNaN(iv)) inputVoltage = iv;
                    break;
                case "output.voltage":
                    var ov = parseFloat(value);
                    if (!isNaN(ov)) outputVoltage = ov;
                    break;
                case "battery.voltage":
                    var bv = parseFloat(value);
                    if (!isNaN(bv)) batteryVoltage = bv;
                    break;
                case "ups.load":
                    var load = parseFloat(value);
                    if (!isNaN(load)) upsLoad = load;
                    break;
                case "ups.temperature":
                    var temp = parseFloat(value);
                    if (!isNaN(temp)) upsTemp = temp;
                    break;
            }
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.activeUpsName !== ""

        onTriggered: {
            upsProcess.running = true;
        }
    }
}
