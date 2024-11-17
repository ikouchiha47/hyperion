import QtQuick 
import QtWebEngine

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
            createWindow(defaultProfile)
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
        console.log("create window")
        var newWindow = browserWindowComponent.createObject(root);
        newWindow.currentWebView.profile = profile;
        profile.downloadRequested.connect(newWindow.onDownloadRequested);
        console.log("new", newWindow);
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
