import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: root
    focus: true

    Caching { id: paths }

    MatugenColors { id: mocha }

    readonly property real bgAlpha: Config.blurEnabled ? 0.35 : 0.85

    // --- Responsive Scaling Logic ---
    Scaler {
        id: scaler
        currentWidth: Screen.width
    }
    function s(val) { return scaler.s(val); }

    // --- Currently active override (read once + on write) ---
    property string activeHex: ""
    property string activeScheme: ""

    Process {
        id: overrideReader
        command: ["bash", "-c", "cat ~/.config/hypr/color_override.json 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let o = JSON.parse(this.text.trim());
                    root.activeHex = o.active ? (o.hex || "") : "";
                    root.activeScheme = o.scheme || "";
                } catch (e) {
                    root.activeHex = "";
                }
            }
        }
    }
    Component.onCompleted: overrideReader.running = true

    // --- Run a shell command fire-and-forget ---
    function execCmd(cmdStr) {
        var safeCmd = cmdStr.replace(/`/g, "\\`");
        var p = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["bash", "-c", \`${safeCmd}\`]
                running: true
                onExited: (exitCode) => destroy()
            }
        `, root);
    }

    function applyColor(hex, scheme) {
        root.activeHex = hex;
        root.activeScheme = scheme || "";
        let schemeArg = scheme ? ` "${scheme}"` : "";
        execCmd(`bash $HOME/.config/hypr/scripts/quickshell/color/apply_color.sh "${hex}"${schemeArg}`);
    }

    // --- Preset palettes ---
    readonly property var materialColors: [
        { name: "Red",         hex: "#F44336" },
        { name: "Pink",        hex: "#E91E63" },
        { name: "Purple",      hex: "#9C27B0" },
        { name: "Deep Purple", hex: "#673AB7" },
        { name: "Indigo",      hex: "#3F51B5" },
        { name: "Blue",        hex: "#2196F3" },
        { name: "Light Blue",  hex: "#03A9F4" },
        { name: "Cyan",        hex: "#00BCD4" },
        { name: "Teal",        hex: "#009688" },
        { name: "Green",       hex: "#4CAF50" },
        { name: "Light Green", hex: "#8BC34A" },
        { name: "Lime",        hex: "#CDDC39" },
        { name: "Yellow",      hex: "#FFEB3B" },
        { name: "Amber",       hex: "#FFC107" },
        { name: "Orange",      hex: "#FF9800" },
        { name: "Deep Orange", hex: "#FF5722" },
        { name: "Brown",       hex: "#795548" },
        { name: "Grey",        hex: "#9E9E9E" },
        { name: "Blue Grey",   hex: "#607D8B" },
        { name: "Black",       hex: "#212121" }
    ]

    readonly property var catppuccinColors: [
        { name: "Latte (Mauve)",     hex: "#8839EF" },
        { name: "Frappé (Mauve)",    hex: "#CA9EE6" },
        { name: "Macchiato (Mauve)", hex: "#C6A0F6" },
        { name: "Mocha (Mauve)",     hex: "#CBA6F7" },
        { name: "Mocha (Blue)",      hex: "#89B4FA" },
        { name: "Mocha (Green)",     hex: "#A6E3A1" },
        { name: "Mocha (Peach)",     hex: "#FAB387" },
        { name: "Mocha (Red)",       hex: "#F38BA8" }
    ]

    readonly property var famousColors: [
        { name: "Nord",       hex: "#5E81AC" },
        { name: "Dracula",    hex: "#BD93F9" },
        { name: "Gruvbox",    hex: "#D79921" },
        { name: "Tokyo Night",hex: "#7AA2F7" },
        { name: "Rosé Pine",  hex: "#C4A7E7" },
        { name: "Solarized",  hex: "#268BD2" },
        { name: "Everforest", hex: "#A7C080" },
        { name: "One Dark",   hex: "#61AFEF" }
    ]

    property int currentTab: 0 // 0 Material, 1 Catppuccin, 2 Famous, 3 Custom

    // --- Custom color state (HSL sliders) ---
    property real customHue: 260
    property real customSat: 70
    property real customLight: 60
    property string customHex: "#8839EF"

    function hslToHex(h, sPct, lPct) {
        let c = Qt.hsla(h / 360, sPct / 100, lPct / 100, 1.0);
        let toHex2 = (v) => Math.round(v * 255).toString(16).padStart(2, "0");
        return ("#" + toHex2(c.r) + toHex2(c.g) + toHex2(c.b)).toUpperCase();
    }

    function updateFromHsl() {
        root.customHex = hslToHex(root.customHue, root.customSat, root.customLight);
        if (typeof hexField !== "undefined" && hexField) hexField.text = root.customHex;
    }

    // ============================================================
    // WINDOW BACKGROUND
    // ============================================================
    Rectangle {
        anchors.fill: parent
        radius: root.s(20)
        color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, root.bgAlpha)
        border.color: mocha.surface1
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.s(24)
            spacing: root.s(16)

            // --- Header ---
            RowLayout {
                Layout.fillWidth: true
                spacing: root.s(10)
                Text {
                    text: "Color"
                    color: mocha.text
                    font.family: "Liberation Sans"
                    font.pixelSize: root.s(22)
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.activeHex ? ("Active: " + root.activeHex) : "Following wallpaper"
                    color: mocha.subtext0
                    font.family: "Liberation Sans"
                    font.pixelSize: root.s(13)
                }
                Rectangle {
                    Layout.preferredWidth: root.s(22)
                    Layout.preferredHeight: root.s(22)
                    radius: root.s(6)
                    color: root.activeHex || mocha.overlay0
                    border.color: mocha.surface1
                    border.width: 1
                }
            }

            // --- Tab bar ---
            RowLayout {
                Layout.fillWidth: true
                spacing: root.s(8)

                Repeater {
                    model: ["Material", "Catppuccin", "Famous", "Custom"]
                    delegate: Rectangle {
                        Layout.preferredHeight: root.s(34)
                        Layout.preferredWidth: tabText.implicitWidth + root.s(28)
                        radius: root.s(10)
                        color: root.currentTab === index ? mocha.mauve : (tabMa.containsMouse ? mocha.surface1 : "transparent")
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Text {
                            id: tabText
                            anchors.centerIn: parent
                            text: modelData
                            font.family: "Liberation Sans"
                            font.pixelSize: root.s(13)
                            font.weight: Font.Medium
                            color: root.currentTab === index ? mocha.base : mocha.subtext0
                        }
                        MouseArea {
                            id: tabMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentTab = index
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: mocha.surface1 }

            // --- Content area ---
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Preset grid (Material / Catppuccin / Famous)
                GridView {
                    id: presetGrid
                    anchors.fill: parent
                    visible: root.currentTab < 3
                    cellWidth: width / 4
                    cellHeight: root.s(96)
                    model: root.currentTab === 0 ? root.materialColors : (root.currentTab === 1 ? root.catppuccinColors : root.famousColors)
                    clip: true

                    delegate: Item {
                        width: presetGrid.cellWidth
                        height: presetGrid.cellHeight

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: root.s(6)

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: root.s(56); height: root.s(56)
                                radius: root.s(18)
                                color: modelData.hex
                                border.width: root.activeHex.toUpperCase() === modelData.hex.toUpperCase() ? root.s(3) : 1
                                border.color: root.activeHex.toUpperCase() === modelData.hex.toUpperCase() ? mocha.text : mocha.surface1
                                scale: swatchMa.containsMouse ? 1.08 : 1.0
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                MouseArea {
                                    id: swatchMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.applyColor(modelData.hex)
                                }
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.name
                                color: mocha.subtext0
                                font.family: "Liberation Sans"
                                font.pixelSize: root.s(11)
                            }
                        }
                    }
                }

                // Custom color builder
                ColumnLayout {
                    anchors.fill: parent
                    visible: root.currentTab === 3
                    spacing: root.s(20)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: root.s(20)

                        Rectangle {
                            Layout.preferredWidth: root.s(140)
                            Layout.preferredHeight: root.s(140)
                            radius: root.s(28)
                            color: root.customHex
                            border.color: mocha.surface1
                            border.width: 2
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: root.s(14)

                            // Hue slider
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: root.s(4)
                                Text { text: "Hue"; color: mocha.subtext0; font.pixelSize: root.s(12); font.family: "Liberation Sans" }
                                Slider {
                                    Layout.fillWidth: true
                                    from: 0; to: 359; value: root.customHue
                                    onMoved: { root.customHue = value; root.updateFromHsl(); }
                                }
                            }
                            // Saturation slider
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: root.s(4)
                                Text { text: "Saturation"; color: mocha.subtext0; font.pixelSize: root.s(12); font.family: "Liberation Sans" }
                                Slider {
                                    Layout.fillWidth: true
                                    from: 0; to: 100; value: root.customSat
                                    onMoved: { root.customSat = value; root.updateFromHsl(); }
                                }
                            }
                            // Lightness slider
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: root.s(4)
                                Text { text: "Lightness"; color: mocha.subtext0; font.pixelSize: root.s(12); font.family: "Liberation Sans" }
                                Slider {
                                    Layout.fillWidth: true
                                    from: 10; to: 90; value: root.customLight
                                    onMoved: { root.customLight = value; root.updateFromHsl(); }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: root.s(12)

                        Text { text: "Hex"; color: mocha.subtext0; font.family: "Liberation Sans"; font.pixelSize: root.s(13) }

                        TextField {
                            id: hexField
                            Layout.preferredWidth: root.s(140)
                            text: root.customHex
                            font.family: "Liberation Mono"
                            color: mocha.text
                            background: Rectangle {
                                radius: root.s(8)
                                color: mocha.surface0
                                border.color: mocha.surface1
                            }
                            onEditingFinished: {
                                if (/^#[0-9A-Fa-f]{6}$/.test(text)) {
                                    root.customHex = text.toUpperCase();
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            Layout.preferredWidth: root.s(120)
                            Layout.preferredHeight: root.s(38)
                            radius: root.s(10)
                            color: applyMa.containsMouse ? Qt.lighter(mocha.mauve, 1.1) : mocha.mauve
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Apply"
                                color: mocha.base
                                font.family: "Liberation Sans"
                                font.weight: Font.Bold
                                font.pixelSize: root.s(13)
                            }
                            MouseArea {
                                id: applyMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.applyColor(root.customHex)
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
