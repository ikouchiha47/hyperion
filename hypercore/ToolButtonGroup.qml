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

    Row { 
        anchors.fill: parent
        spacing: 10

        width: parent.width
        height: parent.height

        anchors.centerIn: parent
        anchors.verticalCenter: parent.verticalCenter

        ToolButton {
            enabled: currentWebView && (currentWebView.canGoBack || currentWebView.canGoForward)
            onClicked: historyMenu.open()
            text: qsTr("▼")

            height: parent.height

            Menu {
                id: historyMenu
                Instantiator {
                    model: currentWebView && currentWebView.history.items
                    MenuItem {
                        text: model.title
                        onTriggered: currentWebView.goBackOrForward(model.offset)
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
            icon.source: "qrc:/icons/go-previous.png"
            onClicked: currentWebView.goBack()
            enabled: currentWebView && currentWebView.canGoBack
            activeFocusOnTab: !browserWindow.platformIsMac

            height: parent.height

        }
        ToolButton {
            id: forwardButton
            icon.source: "qrc:/icons/go-next.png"
            onClicked: currentWebView.goForward()
            enabled: currentWebView && currentWebView.canGoForward
            activeFocusOnTab: !browserWindow.platformIsMac

            height: parent.height

        }
        ToolButton {
            id: reloadButton
            icon.source: currentWebView && currentWebView.loading ? "qrc:/icons/process-stop.png" : "qrc:/icons/view-refresh.png"
            onClicked: currentWebView && currentWebView.loading ? currentWebView.stop() : currentWebView.reload()
            activeFocusOnTab: !browserWindow.platformIsMac

            height: parent.height
        }
    }
}
