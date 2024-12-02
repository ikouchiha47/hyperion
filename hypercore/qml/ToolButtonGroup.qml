import QtCore
import QtQml
import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import QtQuick.Window
import QtWebEngine

Item {
    id: toolButtonGroup

    width: parent.width
    height: parent.height

    FontLoader {
        id: fontAwesome
        source: "qrc:/fonts/FontAwesome.ttf"
    }

    Row { 
        anchors.fill: parent
        spacing: 10

        width: parent.width
        height: parent.height

        anchors.centerIn: parent
        anchors.verticalCenter: parent.verticalCenter

        ToolButton {
            enabled: currentWebView && (currentWebView.engine.canGoBack || currentWebView.engine.canGoForward)
            onClicked: historyMenu.open()
            text: qsTr("▼")

            height: parent.height

            Menu {
                id: historyMenu
                Instantiator {
                    model: currentWebView && currentWebView.engine.history.items
                    MenuItem {
                        text: model.title
                        onTriggered: currentWebView.engine.goBackOrForward(model.offset)
                        checkable: !enabled
                        checked: !enabled
                        enabled: model.offset
                    }

                    onObjectAdded: function(index, object) {
                        historyMenu.insertItem(index, object)
                    }
                    onObjectRemoved: function(index, object) {
                        historyMenu.removeItem(object)
                    }
                }
            }
        }

        ToolButton {
            id: backButton

            onClicked: currentWebView.engine.goBack()
            enabled: currentWebView && currentWebView.engine.canGoBack
            activeFocusOnTab: !browserWindow.platformIsMac

            height: parent.height
            hoverEnabled: false

            Text {
                anchors.centerIn: parent
                font.family: fontAwesome.name
                font.pointSize: 16
                text: "\uf060"
                color: backButton.enabled ? "#fff" : "#999"
            }
        }
        ToolButton {
            id: forwardButton

            onClicked: currentWebView.engine.goForward()
            enabled: currentWebView && currentWebView.engine.canGoForward
            activeFocusOnTab: !browserWindow.platformIsMac
            hoverEnabled: false

            height: parent.height
            Text {
                anchors.centerIn: parent
                font.family: fontAwesome.name
                font.pointSize: 16
                text: "\uf061"
                color: forwardButton.enabled ? "#fff" : "#999"
            }
        }
        ToolButton {
            id: reloadButton
            onClicked: currentWebView && currentWebView.engine.loading ? currentWebView.engine.stop() : currentWebView.engine.reload()
            activeFocusOnTab: !browserWindow.platformIsMac

            height: parent.height
            hoverEnabled: false
            enabled: currentWebView && currentWebView.engine.loading

            contentItem: Text {
                text: currentWebView && currentWebView.engine.loading ? "\uf00d" : "\uf021"
                font.family: fontAwesome.name
                font.pointSize: 16
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                anchors.centerIn: parent
                color: reloadButton.enabled ? "#fff" : "#999"
            }
        }
    }
}
