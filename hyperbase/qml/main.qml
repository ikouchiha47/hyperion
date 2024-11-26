import QtQuick 2.15
import QtWebEngine 1.15

// This must match the uri and version
// specified in the qml_module in the build.rs script.
import com.hyperion.cxx_qt.base 1.0

QtObject {
    id: root

    property QtObject defaultProfile: WebEngineProfile {
        offTheRecord: false
        storageName: "Profile"
        
        Component.onCompleted: {
            // let fullVersionList = defaultProfile.clientHints.fullVersionList;
            // fullVersionList["Hyperion"] = "1.0";
            // defaultProfile.clientHints.fullVersionList = fullVersionList;
            // console.log(defaultProfile.clientHints)
            // createWindow(defaultProfile)
            load("chrome://qt")
        }

    }

    property QtObject otrProfile: WebEngineProfile {
        offTheRecord: true
    }

    property Component browserWindowComponent: BrowserWindow {
        applicationRoot: root
    }
    property Component browserDialogComponent: BrowserDialog {
        onClosing: destroy()
    }
    function createWindow(profile) {
        var newWindow = browserWindowComponent.createObject(root);

        newWindow.currentWebView.profile = profile;
        profile.downloadRequested.connect(newWindow.onDownloadRequested);
        return newWindow;
    }
    function createDialog(profile) {
        var newDialog = browserDialogComponent.createObject(root);
        newDialog.currentWebView.profile = profile;
        return newDialog;
    }
    function load(url) {
        var browserWindow = createWindow(defaultProfile);
        browserWindow.currentWebView.url = url;
    }
}
