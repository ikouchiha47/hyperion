#[cxx_qt::bridge]
pub mod QWebEngine {
    unsafe extern "C++" {
        include!("QtWebEngineQuick/qtwebenginequickglobal.h");

        #[namespace = "QtWebEngineQuick"]
        #[rust_name = "initialize"]
        fn initialize();
    }
}
