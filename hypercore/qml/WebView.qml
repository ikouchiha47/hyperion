import QtCore
import QtQml
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtWebEngine

import QtQuick.Controls.Fusion


Item {
    id: customWebView

    property alias profile: leftWebView.profile
    property alias url: leftWebView.url
    property alias title: leftWebView.title
    property alias rightUrl: rightWebView.url
    property bool splitEnabled: browserWindow.splitEnabled

    property bool localContentCanAccessRemoteUrls: false
    property bool localContentCanAccessFileUrls: false
    property bool autoLoadImages: true
    property bool javascriptEnabled: true
    property bool errorPageEnabled: true
    property bool pluginsEnabled: true
    property bool fullScreenSupportEnabled: true
    property bool autoLoadIconsForPage: true
    property bool touchIconsEnabled: true
    property bool webRTCPublicInterfacesOnly: true
    property bool pdfViewerEnabled: true
    property int imageAnimationPolicy: WebEngineSettings.ImageAnimationPolicy.Allow
    property bool screenCaptureEnabled: true

    property alias engine: leftWebView

    signal certificateError
    signal newWindowRequested
    signal fullScreenRequested
    signal renderProcessTerminated
    signal linkHovered
    signal permissionRequested
    signal registerProtocolHandlerRequested
    signal desktopMediaRequested
    signal selectClientCertificate
    signal findTextFinished
    signal loadingChanged
    signal webAuthUxRequested
    

    SplitView {
        id: splitView
        anchors.fill: parent
        orientation: Qt.Horizontal

        // Behavior on SplitView.preferredWidth {
        //     NumberAnimation {
        //         duration: 300
        //         easing.type: Easing.InOutQuad
        //     }
        // }

        WebEngineView {
            id: leftWebView
            focus: true
            url: "chrome://qt"


            SplitView.preferredWidth: splitEnabled ? (parent.width / 2 - 80) : parent.width
            SplitView.preferredHeight: parent.height

            onCertificateError: customWebView.certificateErrorOccurred
            onNewWindowRequested: customWebView.newWindowRequested
            onFullScreenRequested: customWebView.fullScreenRequested
            onRenderProcessTerminated: customWebView.renderProcessTerminated
            onLinkHovered: customWebView.linkHovered
            onPermissionRequested: customWebView.permissionRequested
            onRegisterProtocolHandlerRequested: customWebView.registerProtocolHandlerRequested
            onDesktopMediaRequested: customWebView.desktopMediaRequested
            onSelectClientCertificate: customWebView.selectClientCertificate
            onFindTextFinished: customWebView.findTextFinished
            onLoadingChanged: customWebView.loadingChanged
            onWebAuthUxRequested: customWebView.webAuthUxRequested

            states: [
                State {
                    name: "FullScreen"
                    PropertyChanges {
                        target: tabBar
                        visible: false
                        height: 0
                    }
                    PropertyChanges {
                        target: navigationBar
                        visible: false
                    }
                }
            ]

            // Settings
            Component.onCompleted: {
                settings.localContentCanAccessRemoteUrls = customWebView.localContentCanAccessRemoteUrls;
                settings.localContentCanAccessFileUrls = customWebView.localContentCanAccessFileUrls;
                settings.autoLoadImages = customWebView.autoLoadImages;
                settings.javascriptEnabled = customWebView.javascriptEnabled;
                settings.errorPageEnabled = customWebView.errorPageEnabled;
                settings.pluginsEnabled = customWebView.pluginsEnabled;
                settings.fullScreenSupportEnabled = customWebView.fullScreenSupportEnabled;
                settings.autoLoadIconsForPage = customWebView.autoLoadIconsForPage;
                settings.touchIconsEnabled = customWebView.touchIconsEnabled;
                settings.webRTCPublicInterfacesOnly = customWebView.webRTCPublicInterfacesOnly;
                settings.pdfViewerEnabled = customWebView.pdfViewerEnabled;
                settings.imageAnimationPolicy = customWebView.imageAnimationPolicy;
                settings.screenCaptureEnabled = customWebView.screenCaptureEnabled;
            }
        }

        WebEngineView {
            id: rightWebView
            visible: splitEnabled
            url: leftWebView.url

            // Layout.preferredWidth: splitEnabled ? (parent.width / 2 - 100) : 0
            // Layout.preferredHeight: parent.height

            onCertificateError: customWebView.certificateError
            onNewWindowRequested: customWebView.newWindowRequested
            onFullScreenRequested: customWebView.fullScreenRequested
            onRenderProcessTerminated: customWebView.renderProcessTerminated
            onLinkHovered: customWebView.linkHovered
            onPermissionRequested: customWebView.permissionRequested
            onRegisterProtocolHandlerRequested: customWebView.registerProtocolHandlerRequested
            onDesktopMediaRequested: customWebView.desktopMediaRequested
            onSelectClientCertificate: customWebView.clientCertificateSelected
            onFindTextFinished: customWebView.findTextFinished
            onLoadingChanged: customWebView.loadingChanged
            onWebAuthUxRequested: customWebView.webAuthUxRequested

            // settings: leftWebView.settings
            Component.onCompleted: {
                settings.localContentCanAccessRemoteUrls = customWebView.localContentCanAccessRemoteUrls;
                settings.localContentCanAccessFileUrls = customWebView.localContentCanAccessFileUrls;
                settings.autoLoadImages = customWebView.autoLoadImages;
                settings.javascriptEnabled = customWebView.javascriptEnabled;
                settings.errorPageEnabled = customWebView.errorPageEnabled;
                settings.pluginsEnabled = customWebView.pluginsEnabled;
                settings.fullScreenSupportEnabled = customWebView.fullScreenSupportEnabled;
                settings.autoLoadIconsForPage = customWebView.autoLoadIconsForPage;
                settings.touchIconsEnabled = customWebView.touchIconsEnabled;
                settings.webRTCPublicInterfacesOnly = customWebView.webRTCPublicInterfacesOnly;
                settings.pdfViewerEnabled = customWebView.pdfViewerEnabled;
                settings.imageAnimationPolicy = customWebView.imageAnimationPolicy;
                settings.screenCaptureEnabled = customWebView.screenCaptureEnabled;
            }
        }
    }

    // Timer {
    //     id: reloadTimer
    //     interval: 0
    //     running: false
    //     repeat: false
    //     onTriggered: leftWebView.reload()
    // }
}
