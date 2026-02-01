import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

NScrollView {
    id: root

    property var pluginApi: null

    horizontalPolicy: ScrollBar.AlwaysOff
    verticalPolicy: ScrollBar.AsNeeded
    padding: Style.marginL

    property string valueUpsName: pluginApi?.pluginSettings?.upsName ||
                                  pluginApi?.manifest?.metadata?.defaultSettings?.upsName ||
                                  ""

    property var availableUpsNames: []

    Component.onCompleted: {
        upsListProcess.running = true;
    }

    ColumnLayout {
        width: parent.width
        spacing: Style.marginM

        NHeader {
            label: "UPS Configuration"
            description: "Select which UPS to monitor"
        }

        NComboBox {
            Layout.fillWidth: true
            label: "UPS Name"
            description: "Select the UPS to monitor from NUT"
            model: {
                var items = [];
                for (var i = 0; i < root.availableUpsNames.length; i++) {
                    items.push({name: root.availableUpsNames[i], key: root.availableUpsNames[i]});
                }
                if (items.length === 0) {
                    items.push({name: "(No UPS found)", key: ""});
                }
                return items;
            }
            currentKey: root.valueUpsName
            onSelected: function(key) {
                root.valueUpsName = key;
            }
        }

        NDivider {
            Layout.fillWidth: true
            Layout.topMargin: Style.marginS
            Layout.bottomMargin: Style.marginS
        }

        NButton {
            Layout.fillWidth: true
            Layout.topMargin: Style.marginM
            text: "Save Settings"
            onClicked: saveSettings()
        }
    }

    function saveSettings() {
        if (!pluginApi) {
            console.error("NUT Status: Cannot save settings - pluginApi is null");
            return;
        }

        pluginApi.pluginSettings.upsName = root.valueUpsName;
        pluginApi.saveSettings();
    }

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
                var names = [];
                var lines = collectedOutput.trim().split('\n');
                for (var i = 0; i < lines.length; i++) {
                    var name = lines[i].trim();
                    if (name) {
                        names.push(name);
                    }
                }
                root.availableUpsNames = names;
                // Auto-select first UPS if none configured
                if (!root.valueUpsName && names.length > 0) {
                    root.valueUpsName = names[0];
                }
            }
            collectedOutput = "";
        }
    }
}
