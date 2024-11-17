import QtQuick
import QtQuick.Window
import QtWebEngine

import com.hyperion.cxx_qt.base 1.0

Window {
    id: window
    property alias currentWebView: webView
    flags: Qt.Dialog
    width: 800
    height: 600
    visible: true
    onClosing: destroy()
    WebEngineView {
        id: webView
        anchors.fill: parent

        onGeometryChangeRequested: function(geometry) {
            window.x = geometry.x
            window.y = geometry.y
            window.width = geometry.width
            window.height = geometry.height
        }
    }
}
