pub mod cxxqt_object;
pub mod qtwebengine;

use cxx_qt_lib::{QGuiApplication, QQmlApplicationEngine, QUrl};
use qtwebengine::QWebEngine;

pub fn startup_url() -> QUrl {
    QUrl::from("chrome://qt")
}

fn main() {
    // Create the application and engine
    QWebEngine::initialize();

    let mut app = QGuiApplication::new();
    let mut engine = QQmlApplicationEngine::new();

    // Load the QML path into the engine
    if let Some(engine) = engine.as_mut() {
        engine.load(&QUrl::from(
            "qrc:/qt/qml/com/hyperion/cxx_qt/base/qml/main.qml",
        ));
    }

    if let Some(engine) = engine.as_mut() {
        // Listen to a signal from the QML Engine
        engine
            .as_qqmlengine()
            .on_quit(|_| {
                println!("QML Quit!");
            })
            .release();
    }

    // Start the app
    if let Some(app) = app.as_mut() {
        app.exec();
    }
}
