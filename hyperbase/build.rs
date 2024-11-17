// https://github.com/KDAB/cxx-qt/blob/main/examples/cargo_without_cmake/build.rs

use cxx_qt_build::{CxxQtBuilder, QmlModule};

fn main() {
    CxxQtBuilder::new()
        // Link Qt's Network library
        // - Qt Core is always linked
        // - Qt Gui is linked by enabling the qt_gui Cargo feature of cxx-qt-lib.
        // - Qt Qml is linked by enabling the qt_qml Cargo feature of cxx-qt-lib.
        // - Qt Qml requires linking Qt Network on macOS
        .qt_module("Network")
        .qml_module(QmlModule {
            uri: "com.hyperion.cxx_qt.base",
            rust_files: &["src/cxxqt_object.rs"],
            qml_files: &[
                "qml/main.qml",
                "qml/BrowserWindow.qml",
                "qml/BrowserDialog.qml",
                "qml/DownloadView.qml",
                "qml/FindBar.qml",
                "qml/WebAuthDialog.qml",
                "qml/FullScreenNotification.qml",
            ],
            ..Default::default()
        })
        .qt_module("Quick")
        .qrc("qml/icons/qml.qrc")
        .build();
}
