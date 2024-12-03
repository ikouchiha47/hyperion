import QtCore
import QtQml
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtWebEngine

import QtQuick.Controls.Fusion


Item {
    id: customWebView

    property SplitView splitView: splitView

    property alias profile: leftWebView.profile
    property alias url: leftWebView.url
    property alias title: leftWebView.title
    property alias rightUrl: rightWebView.url

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


    property Item activeWebView: leftWebView

    property bool canGoBack: activeWebView ? activeWebView.canGoBack : false
    property bool canGoForward: activeWebView ? activeWebView.canGoForward: false
    property var history: activeWebView ? activeWebView.history : null

    function goBack() {
        if (activeWebView && activeWebView.canGoBack) {
            activeWebView.goBack();
        }
    }

    function goBackOrForward(steps) {
        if (activeWebView && (activeWebView.canGoBack || activeWebView.canGoForward)) {
            activeWebView.goBackOrForward(steps);
        }
    }

    function stop() {
        if(activeWebView) {
            activeWebView.stop()
        }
    }

    function reload() {
        if(activeWebView) {
            activeWebView.reload()
        }
    }

    // property Item leftWebView: leftWebView
    // property Item rightWebView: rightWebView

    signal certificateError(string error)
    signal newWindowRequested(var request)
    signal fullScreenRequested(var request)
    signal renderProcessTerminated(int terminationStatus, int exitCode)
    signal linkHovered(string url)
    signal permissionRequested(var permission)
    signal registerProtocolHandlerRequested(var request)
    signal desktopMediaRequested(var request)
    signal selectClientCertificate(var selection)
    signal findTextFinished(var result)
    signal loadingChanged(var loadingInfo)
    signal webAuthUxRequested(var request)
    signal activeFocusOnPressChanged(bool focus)

    property bool splitEnabled: false
    onSplitEnabledChanged: function() {
        // console.log("split enable changed", splitEnabled)
        // activeWebView.visible = splitEnabled
    }

    function handleCertificateError(error) {
        customWebView.certificateError(error)
    }

    function handleNewWindowRequested(request) {
        customWebView.newWindowRequested(request)
    }

    function handleFullScreenRequested(request) {
        customWebView.fullScreenRequested(request)
    }

    function handleRenderProcessTerminated(terminationStatus, exitCode) {
        customWebView.renderProcessTerminated(terminationStatus, exitCode)
    }

    function handleLinkHovered(url) {
        customWebView.linkHovered(url)
    }

    function handlePermissionRequested(permission) {
        customWebView.permissionRequested(permission)
    }

    function handleRegisterProtocolHandlerRequested(request) {
        customWebView.registerProtocolHandlerRequested(request)
    }

    function handleDesktopMediaRequested(request) {
        customWebView.desktopMediaRequested(request)
    }

    function handleSelectClientCertificate(selection) {
        customWebView.selectClientCertificate(selection)
    }

    function handleFindTextFinished(result) {
        customWebView.findTextFinished(result)
    }

    function handleLoadingChanged(loadingInfo) {
        customWebView.loadingChanged(loadingInfo)
    }

    function handleWebAuthUxRequested(request) {
        customWebView.webAuthUxRequested(request)
    }

    function handleActiveFocusOnPressChanged(focus) {
        customWebView.activeFocusOnPressChanged(focus)
    }


    function closeView(view) {
        if (view === "left") {
            console.log("Closing left WebView");
            leftWebViewLoader.sourceComponent = null;
        } else if (view === "right") {
            console.log("Closing right WebView");
            rightWebViewLoader.sourceComponent = null;
        }
    }

    SplitView {
        id: splitView
        anchors.fill: parent
        orientation: Qt.Horizontal

        Behavior on SplitView.preferredWidth {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuad
            }
        } 

        Rectangle { 
            id: leftWebViewWrapper
            border.color: splitEnabled && customWebView.activeWebView == leftWebView ? "#fe00f0" : "transparent"
            border.width: splitEnabled ? 2 : 0

            SplitView.preferredWidth: splitEnabled ? (parent.width / 2 - 80) : parent.width
            SplitView.preferredHeight: parent.height

            anchors.margins: 1

            MouseArea {
                anchors.fill: parent
                z: 1
                onClicked: {
                    customWebView.activeWebView = leftWebView
                    customWebView.handleActiveFocusOnPressChanged(true)
                }
            }

            WebEngineView {
                id: leftWebView
                focus: true
                url: "chrome://qt"
                anchors.fill: parent
                anchors.margins: 2

                onCertificateError: customWebView.handleCertificateError
                onNewWindowRequested: customWebView.handleNewWindowRequested
                onFullScreenRequested: customWebView.handleFullScreenRequested
                onRenderProcessTerminated: customWebView.handleRenderProcessTerminated
                onLinkHovered: customWebView.handleLinkHovered
                onPermissionRequested: customWebView.handlePermissionRequested
                onRegisterProtocolHandlerRequested: customWebView.handleRegisterProtocolHandlerRequested
                onDesktopMediaRequested: customWebView.handleDesktopMediaRequested
                onSelectClientCertificate: customWebView.handleSelectClientCertificate
                onFindTextFinished: customWebView.handleFindTextFinished
                onLoadingChanged: customWebView.handleLoadingChanged
                onWebAuthUxRequested: customWebView.handleWebAuthUxRequested
                onActiveFocusOnPressChanged: customWebView.handleActiveFocusOnPressChanged 
                onUrlChanged: {
                    if (browserWindow.currentWebView === leftWebView) {
                        addressBar.text = url.toString();
                    }
                }

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
                    // customWebView.activeWebView = leftWebView
                    // customWebView.handleActiveFocusOnPressChanged(true)
                }
            }
        }

        Rectangle { 
            id: rightWebViewWrapper
            border.color: splitEnabled && customWebView.activeWebView == rightWebView ? "#fe00f0" : "transparent"
            border.width: splitEnabled ? 2 : 0

            SplitView.preferredWidth: splitEnabled ? (parent.width / 2 - 100) : parent.width
            SplitView.preferredHeight: parent.height

            anchors.margins: 1

            visible: splitEnabled

            MouseArea {
                    anchors.fill: parent
                    z: 1
                    onClicked: {
                        customWebView.activeWebView = rightWebView
                        customWebView.handleActiveFocusOnPressChanged(true)
                    }
                }

            WebEngineView {
                id: rightWebView
                url: "chrome://qt"

                visible: splitEnabled

                anchors.fill: parent
                anchors.margins: 2

                onCertificateError: customWebView.handleCertificateErrorOccurred
                onNewWindowRequested: customWebView.handleNewWindowRequested
                onFullScreenRequested: customWebView.handleFullScreenRequested
                onRenderProcessTerminated: customWebView.handleRenderProcessTerminated
                onLinkHovered: customWebView.handleLinkHovered
                onPermissionRequested: customWebView.handlePermissionRequested
                onRegisterProtocolHandlerRequested: customWebView.handleRegisterProtocolHandlerRequested
                onDesktopMediaRequested: customWebView.handleDesktopMediaRequested
                onSelectClientCertificate: customWebView.handleSelectClientCertificate
                onFindTextFinished: customWebView.handleFindTextFinished
                onLoadingChanged: customWebView.handleLoadingChanged
                onWebAuthUxRequested: customWebView.handleWebAuthUxRequested
                onActiveFocusOnPressChanged: customWebView.handleActiveFocusOnPressChanged

                onUrlChanged: {
                    if (browserWindow.currentWebView === rightWebView) {
                        addressBar.text = url.toString();
                    }
                }

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
    }
}
