// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtCore
import QtQml
import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import QtQuick.Window
import QtWebEngine
import Qt5Compat.GraphicalEffects
import BrowserUtils

ApplicationWindow {
    id: browserWindow
    property QtObject applicationRoot
    // property Item currentWebView: tabBar.currentIndex < tabBar.count ? tabLayout.children[tabBar.currentIndex] : null

    property int previousVisibility: Window.Windowed
    property int createdTabs: 0
    property int sideBarWidth: 180

    property var tabsModel: []

    property Item currentWebView: tabBar.currentIndex < tabBar.count ? tabLayout.children[tabBar.currentIndex] : null

    // property Item activeWebView: currentWebView && splitEnabled ? currentWebView.activeWebView : currentWebView
    property Item activeWebView: currentWebView && tabsModel[tabBar.currentIndex]?.webview.splitEnabled 
                                 ? tabsModel[tabBar.currentIndex]?.webview.activeWebView
                                 : currentWebView.activeWebView

    width: 1300
    height: 900
    visible: true
    color: "black"
    title: currentWebView && currentWebView.title

    // Make sure the Qt.WindowFullscreenButtonHint is set on OS X.
    Component.onCompleted: flags = flags | Qt.WindowFullscreenButtonHint

    onCurrentWebViewChanged: {
        findBar.reset();
    }

    function addTab() {
        tabsModel.push({ splitEnabled: false });
        // console.log("Tab added. Total tabs:", tabsModel.length);
    }

    function toggleSplitForActiveTab() {
        if (tabsModel[activeTabIndex]) {
            tabsModel[activeTabIndex].splitEnabled = !tabsModel[activeTabIndex].splitEnabled;
            console.log("Split toggled for tab:", activeTabIndex, "State:", tabsModel[activeTabIndex].splitEnabled);
        }
    }

    // When using style "mac", ToolButtons are not supposed to accept focus.
    property bool platformIsMac: Qt.platform.os == "osx"

    Settings {
        id : appSettings
        property alias autoLoadImages: loadImages.checked
        property alias javaScriptEnabled: javaScriptEnabled.checked
        property alias errorPageEnabled: errorPageEnabled.checked
        property alias pluginsEnabled: pluginsEnabled.checked
        property alias fullScreenSupportEnabled: fullScreenSupportEnabled.checked
        property alias autoLoadIconsForPage: autoLoadIconsForPage.checked
        property alias touchIconsEnabled: touchIconsEnabled.checked
        property alias webRTCPublicInterfacesOnly : webRTCPublicInterfacesOnly.checked
        property alias devToolsEnabled: devToolsEnabled.checked
        property alias pdfViewerEnabled: pdfViewerEnabled.checked
        property int imageAnimationPolicy: WebEngineSettings.ImageAnimationPolicy.Allow
    }

    Action {
        shortcut: "Ctrl+D"
        onTriggered: {
            downloadView.visible = !downloadView.visible;
        }
    }
    Action {
        id: focus
        shortcut: "Ctrl+L"
        onTriggered: {
            addressBar.forceActiveFocus();
            addressBar.selectAll();
        }
    }
    Action {
        shortcut: StandardKey.Refresh
        onTriggered: {
            if (currentWebView)
                currentWebView.reload();
        }
    }
    Action {
        shortcut: "Ctrl+T"
        onTriggered: {
            tabBar.createTab(tabBar.count != 0 ? currentWebView.profile : defaultProfile);
            addressBar.forceActiveFocus();
            addressBar.selectAll();
        }
    }
    Action {
        shortcut: "Ctrl+W"
        onTriggered: {
            if (currentWebView) {
                tabBar.removeView(tabBar.currentIndex);
            }
        }
    }
    Action {
        shortcut: StandardKey.Quit
        onTriggered: browserWindow.close()
    }
    Action {
        shortcut: "Escape"
        onTriggered: {
            if (currentWebView.state == "FullScreen") {
                browserWindow.visibility = browserWindow.previousVisibility;
                fullScreenNotification.hide();
                currentWebView.triggerWebAction(WebEngineView.ExitFullScreen);
            }

            if (findBar.visible)
                findBar.visible = false;
        }
    }
    Action {
        shortcut: "Ctrl+0"
        onTriggered: currentWebView.zoomFactor = 1.0
    }
    Action {
        shortcut: StandardKey.ZoomOut
        onTriggered: currentWebView.zoomFactor -= 0.1
    }
    Action {
        shortcut: StandardKey.ZoomIn
        onTriggered: currentWebView.zoomFactor += 0.1
    }

    Action {
        shortcut: StandardKey.Copy
        onTriggered: currentWebView.triggerWebAction(WebEngineView.Copy)
    }
    Action {
        shortcut: StandardKey.Cut
        onTriggered: currentWebView.triggerWebAction(WebEngineView.Cut)
    }
    Action {
        shortcut: StandardKey.Paste
        onTriggered: currentWebView.triggerWebAction(WebEngineView.Paste)
    }
    Action {
        shortcut: "Shift+"+StandardKey.Paste
        onTriggered: currentWebView.triggerWebAction(WebEngineView.PasteAndMatchStyle)
    }
    Action {
        shortcut: StandardKey.SelectAll
        onTriggered: currentWebView.triggerWebAction(WebEngineView.SelectAll)
    }
    Action {
        shortcut: StandardKey.Undo
        onTriggered: currentWebView.triggerWebAction(WebEngineView.Undo)
    }
    Action {
        shortcut: StandardKey.Redo
        onTriggered: currentWebView.triggerWebAction(WebEngineView.Redo)
    }
    Action {
        shortcut: StandardKey.Back
        onTriggered: currentWebView.triggerWebAction(WebEngineView.Back)
    }
    Action {
        shortcut: StandardKey.Forward
        onTriggered: currentWebView.triggerWebAction(WebEngineView.Forward)
    }
    Action {
        shortcut: StandardKey.Find
        onTriggered: {
            if (!findBar.visible)
                findBar.visible = true;
        }
    }
    Action {
        shortcut: StandardKey.FindNext
        onTriggered: findBar.findNext()
    }
    Action {
        shortcut: StandardKey.FindPrevious
        onTriggered: findBar.findPrevious()
    } 

    menuBar: ToolBar {
        id: navigationBar
        height: 48

        background: Rectangle {
            anchors.fill: parent
            color: "#111"
        }

        RowLayout {
            anchors.fill: parent

            ToolButtonGroup {
                width: 168
                height: navigationBar.height
            }

            TextField {
                id: addressBar
                implicitHeight: parent.height - 10
                text: browserWindow.activeWebView ? browserWindow.activeWebView.url : "chrome://qt"

                clip: true
                leftPadding: faviconImage.source == '' ? 16 : 36
                focus: true

                Layout.fillWidth: true
                verticalAlignment: TextInput.AlignVCenter
                z: 2

                background: Rectangle {
                    anchors.fill: parent
                    radius: 8
                    border.width: 1
                    border.color: "#eee"
                    color: "transparent"
                    z: 1
                }

                Image {
                    anchors.verticalCenter: addressBar.verticalCenter;
                    x: 12
                    z: 2
                    id: faviconImage
                    width: 16; height: 16
                    sourceSize: Qt.size(width, height)
                    source: currentWebView && currentWebView.icon ? currentWebView.icon : ''
                }
                MouseArea {
                    id: textFieldMouseArea
                    acceptedButtons: Qt.RightButton
                    anchors.fill: parent
                    onClicked: {
                        var textSelectionStartPos = addressBar.selectionStart;
                        var textSelectionEndPos = addressBar.selectionEnd;

                        textFieldContextMenu.open();
                        addressBar.select(textSelectionStartPos, textSelectionEndPos);
                    }
                    Menu {
                        id: textFieldContextMenu
                        x: textFieldMouseArea.mouseX
                        y: textFieldMouseArea.mouseY
                        MenuItem {
                            text: qsTr("Cut")
                            onTriggered: addressBar.cut()
                            enabled: addressBar.selectedText.length > 0
                        }
                        MenuItem {
                            text: qsTr("Copy")
                            onTriggered: addressBar.copy()
                            enabled: addressBar.selectedText.length > 0
                        }
                        MenuItem {
                            text: qsTr("Paste")
                            onTriggered: addressBar.paste()
                            enabled: addressBar.canPaste
                        }
                        MenuItem {
                            text: qsTr("Delete")
                            onTriggered: addressBar.text = qsTr("")
                            enabled: addressBar.selectedText.length > 0
                        }
                        MenuSeparator {}
                        MenuItem {
                            text: qsTr("Select All")
                            onTriggered: addressBar.selectAll()
                            enabled: addressBar.text.length > 0
                        }
                    }
                }
 
                Binding on text {
                    when: activeWebView
                    value: activeWebView.url
                }
                onAccepted: {
                    const sanitizedUrl = text.trim().replace(/\s+/g, '');

                    // if (sanitizedUrl.startsWith("http")) {
                    //     fishDetector.isMalicious(sanitizedUrl)
                    // }

                    activeWebView.url = Utils.fromUserInput(sanitizedUrl, customInterceptor.redirectToHttps)
                }
                selectByMouse: true
            }

            ToolButton {
                id: settingsMenuButton
                text: qsTr("⋮")
                onClicked: settingsMenu.open()
                Menu {
                    id: settingsMenu
                    y: settingsMenuButton.height
                    MenuItem {
                        id: loadImages
                        text: "Autoload images"
                        checkable: true
                        checked: WebEngine.settings.autoLoadImages
                    }
                    MenuItem {
                        id: javaScriptEnabled
                        text: "JavaScript On"
                        checkable: true
                        checked: WebEngine.settings.javascriptEnabled
                    }
                    MenuItem {
                        id: errorPageEnabled
                        text: "ErrorPage On"
                        checkable: true
                        checked: WebEngine.settings.errorPageEnabled
                    }
                    MenuItem {
                        id: pluginsEnabled
                        text: "Plugins On"
                        checkable: true
                        checked: true
                    }
                    MenuItem {
                        id: fullScreenSupportEnabled
                        text: "FullScreen On"
                        checkable: true
                        checked: WebEngine.settings.fullScreenSupportEnabled
                    }
                    MenuItem {
                        id: offTheRecordEnabled
                        text: "Off The Record"
                        checkable: true
                        checked: currentWebView && currentWebView.profile === otrProfile
                        onToggled: function(checked) {
                            if (currentWebView) {
                                currentWebView.profile = checked ? otrProfile : defaultProfile;
                            }
                        }
                    }
                    MenuItem {
                        id: httpDiskCacheEnabled
                        text: "HTTP Disk Cache"
                        checkable: currentWebView && !currentWebView.profile.offTheRecord
                        checked: currentWebView && (currentWebView.profile.httpCacheType === WebEngineProfile.DiskHttpCache)
                        onToggled: function(checked) {
                            if (currentWebView) {
                                currentWebView.profile.httpCacheType = checked ? WebEngineProfile.DiskHttpCache : WebEngineProfile.MemoryHttpCache;
                            }
                        }
                    }
                    MenuItem {
                        id: autoLoadIconsForPage
                        text: "Icons On"
                        checkable: true
                        checked: WebEngine.settings.autoLoadIconsForPage
                    }
                    MenuItem {
                        id: touchIconsEnabled
                        text: "Touch Icons On"
                        checkable: true
                        checked: WebEngine.settings.touchIconsEnabled
                        enabled: autoLoadIconsForPage.checked
                    }
                    MenuItem {
                        id: webRTCPublicInterfacesOnly
                        text: "WebRTC Public Interfaces Only"
                        checkable: true
                        checked: WebEngine.settings.webRTCPublicInterfacesOnly
                    }
                    MenuItem {
                        id: devToolsEnabled
                        text: "Open DevTools"
                        checkable: true
                        checked: false
                    }
                    MenuItem {
                        id: redirectToHttpsToggle
                        text: "Redirect to HTTPS"
                        checkable: true
                        checked: customInterceptor.redirectToHttps
                        onToggled: customInterceptor.redirectToHttps = checked
                    }
                    MenuItem {
                        id: pdfViewerEnabled
                        text: "PDF Viewer Enabled"
                        checkable: true
                        checked: WebEngine.settings.pdfViewerEnabled
                    }

                    Menu {
                        id: imageAnimationPolicy
                        title: "Image Animation Policy"

                        MenuItem {
                            id: disableImageAnimation
                            text: "Disable All Image Animation"
                            checkable: true
                            autoExclusive: true
                            checked: WebEngine.settings.imageAnimationPolicy === WebEngineSettings.ImageAnimationPolicy.Disallow
                            onTriggered: {
                                appSettings.imageAnimationPolicy = WebEngineSettings.ImageAnimationPolicy.Disallow
                            }
                        }

                        MenuItem {
                            id: allowImageAnimation
                            text: "Allow All Animated Images"
                            checkable: true
                            autoExclusive: true
                            checked: WebEngine.settings.imageAnimationPolicy === WebEngineSettings.ImageAnimationPolicy.Allow
                            onTriggered : {
                                appSettings.imageAnimationPolicy = WebEngineSettings.ImageAnimationPolicy.Allow
                            }
                        }

                        MenuItem {
                            id: animateImageOnce
                            text: "Animate Image Once"
                            checkable: true
                            autoExclusive: true
                            checked: WebEngine.settings.imageAnimationPolicy === WebEngineSettings.ImageAnimationPolicy.AnimateOnce
                            onTriggered : {
                                appSettings.imageAnimationPolicy = WebEngineSettings.ImageAnimationPolicy.AnimateOnce
                            }
                        }
                    }

                }
            }
        }
        ProgressBar {
            id: progressBar
            height: 3
            anchors {
                left: parent.left
                top: parent.bottom
                right: parent.right
                leftMargin: parent.leftMargin
                rightMargin: parent.rightMargin
            }
            background: Item {}
            z: -2
            from: 0
            to: 100
            value: (currentWebView && currentWebView.loadProgress < 100) ? currentWebView.loadProgress : 0
        }
    }

    StackLayout {
        id: tabLayout
        currentIndex: tabBar.currentIndex

        // anchor top bottom left right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: tabBar.right
        anchors.right: parent.right
    }

    Component {
        id: tabButtonComponent

        TabButton {
            property string tabTitle: "New Tab"
            property int tabIndex: -1

            width: sideBarWidth

            implicitWidth: Math.max(text.width + 10, 60)
            implicitHeight: 40

            id: tabButton

            background: Rectangle {
                anchors.fill: parent
                color: "black"
            }

            contentItem: Rectangle {
                id: tabRectangle
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: tabBar.currentIndex === tabIndex ? "#2e3846" : "transparent" 
                    clip: true

                    Text {
                        id: tabText
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.centerIn: parent 
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 8
                        text: tabButton.tabTitle
                        color: tabBar.currentIndex === tabIndex ? "#fff" : "#eee"
                        font.weight: tabBar.currentIndex === tabIndex ? Font.Bold : Font.Normal
                        font.pointSize: 8
                        elide: Text.ElideRight
                        width: 120
                    }

                    Button {
                        id: button
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 4
                        height: 24
                        width: 24

                        background: Rectangle {
                            radius: 8
                            implicitWidth: 16
                            implicitHeight: 16
                            clip: true
                            color: button.hovered ? "#ccc" : tabRectangle.color
                            Text {text: "x"; anchors.centerIn: parent; color: "gray"}
                        }
                        onClicked: tabButton.closeTab()
                    }
                }
            }

            onClicked: addressBar.text = tabLayout.itemAt(TabBar.index).url;
            function closeTab() {
                tabBar.removeView(TabBar.index);
            }
        }
    }

    TabBar {
        id: tabBar

        // anchor left right top bottom
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        anchors.topMargin: 8

        width: sideBarWidth

        //TODO: make tabBar resizable

        contentItem: ListView {
            model: tabBar.contentModel
            currentIndex: tabBar.currentIndex

            spacing: tabBar.spacing
            orientation: ListView.Vertical
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.AutoFlickIfNeeded
            snapMode: ListView.SnapToItem

            clip: true
            ScrollBar.vertical: ScrollBar {}

            highlightMoveDuration: 0
            highlightRangeMode: ListView.ApplyRange
            preferredHighlightBegin: 40
            preferredHighlightEnd: height - 40
        }

        Component.onCompleted: createTab(defaultProfile)

        function createTab(profile, focusOnNewTab = true, url = undefined) {
            var webview = tabComponent.createObject(tabLayout, {profile: profile, splitEnabled: false, url: "chrome://qt"});

            var newTabButton = tabButtonComponent.createObject(tabBar, {
                tabTitle: Qt.binding(function () { return webview.title; }),
                tabIndex: tabBar.count
            });

            tabBar.addItem(newTabButton);

            browserWindow.tabsModel.push({
                webview: webview,
            });

            if (focusOnNewTab) {
                tabBar.setCurrentIndex(tabBar.count - 1);
            }

            browserWindow.currentWebView = tabsModel[tabBar.currentIndex].webview
            browserWindow.activeWebView = currentWebView.activeWebView
            // console.log(browserWindow.currentWebView.activeWebView, webview.activeWebView, "after create")

            return webview;
        }

        function removeView(index) {
            if (tabBar.count > 1) {
                tabBar.removeItem(tabBar.itemAt(index));

                browserWindow.tabsModel.splice(index, 1);
                tabLayout.children[index].destroy();
            } else {
                browserWindow.close();
            }
        }

        Component {
            id: tabComponent

            WebView {
                id: webEngineView
                splitEnabled: tabsModel[tabBar.currentIndex].splitEnabled;

                Action {
                    shortcut: "Ctrl+/"
                    onTriggered: function() {
                        if (tabsModel[tabBar.currentIndex]) {
                            var activeTab = tabsModel[tabBar.currentIndex];

                            activeTab.webview.splitEnabled = !activeTab.webview.splitEnabled;
                        }
                    }
                }

                onLinkHovered: function(hoveredUrl) {
                    if (hoveredUrl == "")
                        hideStatusText.start();
                    else {
                        statusText.text = hoveredUrl;
                        statusBubble.visible = true;
                        hideStatusText.stop();
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

                localContentCanAccessRemoteUrls: true
                localContentCanAccessFileUrls: false
                autoLoadImages: appSettings.autoLoadImages
                javascriptEnabled: appSettings.javaScriptEnabled
                errorPageEnabled: appSettings.errorPageEnabled
                pluginsEnabled: appSettings.pluginsEnabled
                fullScreenSupportEnabled: appSettings.fullScreenSupportEnabled
                autoLoadIconsForPage: appSettings.autoLoadIconsForPage
                touchIconsEnabled: appSettings.touchIconsEnabled
                webRTCPublicInterfacesOnly: appSettings.webRTCPublicInterfacesOnly
                pdfViewerEnabled: appSettings.pdfViewerEnabled
                imageAnimationPolicy: appSettings.imageAnimationPolicy
                screenCaptureEnabled: true

                onCertificateError: function(error) {
                    if (!error.isMainFrame) {
                        error.rejectCertificate();
                        return;
                    }

                    error.defer();
                    sslDialog.enqueue(error);
                }

                onNewWindowRequested: function(request) {
                    if (!request.userInitiated)
                        console.warn("Blocked a popup window.");
                    else if (request.destination === WebEngineNewWindowRequest.InNewTab) {
                        var tab = tabBar.createTab(currentWebView.profile, true, request.requestedUrl);
                        tab.acceptAsNewWindow(request);
                    } else if (request.destination === WebEngineNewWindowRequest.InNewBackgroundTab) {
                        var backgroundTab = tabBar.createTab(currentWebView.profile, false);
                        backgroundTab.acceptAsNewWindow(request);
                    } else if (request.destination === WebEngineNewWindowRequest.InNewDialog) {
                        var dialog = applicationRoot.createDialog(currentWebView.profile);
                        dialog.currentWebView.acceptAsNewWindow(request);
                    } else {
                        var window = applicationRoot.createWindow(currentWebView.profile);
                        window.currentWebView.acceptAsNewWindow(request);
                    }
                }

                onFullScreenRequested: function(request) {
                    if (request.toggleOn) {
                        webEngineView.state = "FullScreen";
                        browserWindow.previousVisibility = browserWindow.visibility;
                        browserWindow.showFullScreen();
                        fullScreenNotification.show();
                    } else {
                        webEngineView.state = "";
                        browserWindow.visibility = browserWindow.previousVisibility;
                        fullScreenNotification.hide();
                    }
                    request.accept();
                }

                onRegisterProtocolHandlerRequested: function(request) {
                    console.log("accepting registerProtocolHandler request for "
                                + request.scheme + " from " + request.origin);
                    request.accept();
                }

                onDesktopMediaRequested: function(request) {
                    // select the primary screen
                    request.selectScreen(request.screensModel.index(0, 0));
                }

                onRenderProcessTerminated: function(terminationStatus, exitCode) {
                    var status = "";
                    switch (terminationStatus) {
                    case WebEngineView.NormalTerminationStatus:
                        status = "(normal exit)";
                        break;
                    case WebEngineView.AbnormalTerminationStatus:
                        status = "(abnormal exit)";
                        break;
                    case WebEngineView.CrashedTerminationStatus:
                        status = "(crashed)";
                        break;
                    case WebEngineView.KilledTerminationStatus:
                        status = "(killed)";
                        break;
                    }

                    print("Render process exited with code " + exitCode + " " + status);
                    reloadTimer.running = true;
                }

                onSelectClientCertificate: function(selection) {
                    selection.certificates[0].select();
                }

                onFindTextFinished: function(result) {
                    if (!findBar.visible)
                        findBar.visible = true;

                    findBar.numberOfMatches = result.numberOfMatches;
                    findBar.activeMatch = result.activeMatch;
                }

                onLoadingChanged: function(loadRequest) {
                    if (loadRequest.status == WebEngineView.LoadStartedStatus)
                        findBar.reset();
                }

                onPermissionRequested: function(permission) {
                    permissionDialog.permission = permission;
                    permissionDialog.visible = true;
                }
                onWebAuthUxRequested: function(request) {
                    webAuthDialog.init(request);
                }

                onActiveFocusOnPressChanged: function(focus) {
                    // console.log("active focus", focus, activeWebView, this, currentWebView, this.activeWebView, currentWebView.activeWebView, browserWindow.activeWebView)
                    if (focus) {
                        browserWindow.activeWebView = activeWebView
                    }
                }

                Timer {
                    id: reloadTimer
                    interval: 0
                    running: false
                    repeat: false
                    onTriggered: currentWebView.reload()
                }
            }
        }
    }
    WebEngineView {
        id: devToolsView
        visible: devToolsEnabled.checked
        height: visible ? 400 : 0
        inspectedView: visible && tabBar.currentIndex < tabBar.count ? tabLayout.children[tabBar.currentIndex] : null
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        onNewWindowRequested: function(request) {
            var tab = tabBar.createTab(currentWebView.profile);
            request.openIn(tab);
        }

        Timer {
            id: hideTimer
            interval: 0
            running: false
            repeat: false
            onTriggered: devToolsEnabled.checked = false
        }
        onWindowCloseRequested: function(request) {
            // Delay hiding for keep the inspectedView set to receive the ACK message of close.
            hideTimer.running = true;
        }
    }
    Dialog {
        id: sslDialog
        anchors.centerIn: parent
        contentWidth: Math.max(mainTextForSSLDialog.width, detailedTextForSSLDialog.width)
        contentHeight: mainTextForSSLDialog.height + detailedTextForSSLDialog.height
        property var certErrors: []
        // fixme: icon!
        // icon: StandardIcon.Warning
        standardButtons: Dialog.No | Dialog.Yes
        title: "Server's certificate not trusted"
        contentItem: Item {
            Label {
                id: mainTextForSSLDialog
                text: "Do you wish to continue?"
            }
            Text {
                id: detailedTextForSSLDialog
                anchors.top: mainTextForSSLDialog.bottom
                text: "If you wish so, you may continue with an unverified certificate.\n" +
                      "Accepting an unverified certificate means\n" +
                      "you may not be connected with the host you tried to connect to.\n" +
                      "Do you wish to override the security check and continue?"
            }
        }

        onAccepted: {
            certErrors.shift().acceptCertificate();
            presentError();
        }
        onRejected: reject()

        function reject(){
            certErrors.shift().rejectCertificate();
            presentError();
        }
        function enqueue(error){
            certErrors.push(error);
            presentError();
        }
        function presentError(){
            visible = certErrors.length > 0
        }
    }
    Dialog {
        id: permissionDialog
        anchors.centerIn: parent
        width: Math.min(browserWindow.width, browserWindow.height) / 3 * 2
        contentWidth: mainTextForPermissionDialog.width
        contentHeight: mainTextForPermissionDialog.height
        standardButtons: Dialog.No | Dialog.Yes
        title: "Permission Request"

        property var permission;

        contentItem: Item {
            Label {
                id: mainTextForPermissionDialog
            }
        }

        onAccepted: permission.grant()
        onRejected: permission.deny()
        onVisibleChanged: {
            if (visible) {
                mainTextForPermissionDialog.text = questionForPermissionType();
                width = contentWidth + 20;
            }
        }

        function questionForPermissionType() {
            var question = "Allow " + permission.origin + " to "

            switch (permission.permissionType) {
            case WebEnginePermission.PermissionType.Geolocation:
                question += "access your location information?";
                break;
            case WebEnginePermission.PermissionType.MediaAudioCapture:
                question += "access your microphone?";
                break;
            case WebEnginePermission.PermissionType.MediaVideoCapture:
                question += "access your webcam?";
                break;
            case WebEnginePermission.PermissionType.MediaAudioVideoCapture:
                question += "access your microphone and webcam?";
                break;
            case WebEnginePermission.PermissionType.MouseLock:
                question += "lock your mouse cursor?";
                break;
            case WebEnginePermission.PermissionType.DesktopVideoCapture:
                question += "capture video of your desktop?";
                break;
            case WebEnginePermission.PermissionType.DesktopAudioVideoCapture:
                question += "capture audio and video of your desktop?";
                break;
            case WebEnginePermission.PermissionType.Notifications:
                question += "show notification on your desktop?";
                break;
            case WebEnginePermission.PermissionType.ClipboardReadWrite:
                question += "read from and write to your clipboard?";
                break;
            case WebEnginePermission.PermissionType.LocalFontsAccess:
                question += "access the fonts stored on your machine?";
                break;
            default:
                question += "access unknown or unsupported permission type [" + permission.permissionType + "] ?";
                break;
            }

            return question;
        }
    }

    FullScreenNotification {
        id: fullScreenNotification
    }

    DownloadView {
        id: downloadView
        visible: false
        anchors.fill: parent
    }

    WebAuthDialog {
        id: webAuthDialog
        visible: false
    }

    function onDownloadRequested(download) {
        downloadView.visible = true;
        downloadView.append(download);
        download.accept();
    }

    FindBar {
        id: findBar
        visible: false
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.top: parent.top

        onFindNext: {
            if (text)
                currentWebView && currentWebView.findText(text);
            else if (!visible)
                visible = true;
        }
        onFindPrevious: {
            if (text)
                currentWebView && currentWebView.findText(text, WebEngineView.FindBackward);
            else if (!visible)
                visible = true;
        }
    }


    Rectangle {
        id: statusBubble
        color: "oldlace"
        property int padding: 8
        visible: false

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: statusText.paintedWidth + padding
        height: statusText.paintedHeight + padding

        Text {
            id: statusText
            anchors.centerIn: statusBubble
            elide: Qt.ElideMiddle

            Timer {
                id: hideStatusText
                interval: 750
                onTriggered: {
                    statusText.text = "";
                    statusBubble.visible = false;
                }
            }
        }
    }
}
