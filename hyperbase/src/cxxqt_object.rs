// https://cxx.rs/
// Example:
// https://github.com/dtolnay/cxx/blob/master/demo/src/main.rs
// https://kdab.github.io/cxx-qt/book/getting-started/2-our-first-cxx-qt-module.html
// // Shared structs with fields visible to both languages.
// // Rust types and signatures exposed to C++., using extern
// // C++ types and signatures exposed to Rust.
// // Rust implementation of shared struct definition in rust
// #[cxx_qt::bridge]
// pub mod qobject {
//
//     unsafe extern "C++" {
//         include!("cxx-qt-lib/qstring.h");
//         /// An alias to the QString type
//         type QString = cxx_qt_lib::QString;
//     }
//
//     unsafe extern "RustQt" {
//         // The QObject definition
//         // We tell CXX-Qt that we want a QObject class with the name MyObject
//         // based on the Rust struct MyObjectRust.
//         // qproperty: https://doc.qt.io/qt-6/properties.html
//         #[qobject]
//         #[qml_element]
//         #[qproperty(i32, number)]
//         #[qproperty(QString, string)]
//         #[namespace = "hyperobject"]
//         type HyperObject = super::HyperObjectRust;
//     }
//
//     unsafe extern "RustQt" {
//         // Declare the invokable methods we want to expose on the QObject
//         // qinvokable: https://doc.qt.io/qt-6/qtqml-cppintegration-exposecppattributes.html#exposing-methods-including-qt-slots
//         #[qinvokable]
//         #[cxx_name = "fromUserInput"]
//         fn from_user_input(self: Pin<&mut HyperObject>);
//
//         #[qinvokable]
//         #[cxx_name = "sayHi"]
//         fn say_hi(self: &HyperObject, string: &QString, number: i32);
//     }
// }
//
// // Implementation of HyperObject
// use core::pin::Pin;
// use cxx_qt_lib::QString;
//
// /// The Rust struct for the QObject
// #[derive(Default)]
// pub struct HyperObjectRust {
//     number: i32,
//     string: QString,
// }
//
// impl qobject::HyperObject {
//     /// Increment the number Q_PROPERTY
//     pub fn increment_number(self: Pin<&mut Self>) {
//         let previous = *self.number();
//         self.set_number(previous + 1);
//     }
//
//     /// Print a log message with the given string and number
//     pub fn say_hi(&self, string: &QString, number: i32) {
//         println!("Hi from Rust! String is '{string}' and number is {number}");
//     }
// }

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qurl.h");
        include!("cxx-qt-lib/qstring.h");

        type QString = cxx_qt_lib::QString;
        type QUrl = cxx_qt_lib::QUrl;
    }

    unsafe extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qml_singleton]
        #[qproperty(QString, user_input)]
        type Utils = super::BrowserUtilsRust;

        /// Increment the persistent value Q_PROPERTY of the QML_SINGLETON
        #[qinvokable]
        #[cxx_name = "fromUserInput"]
        fn from_user_input(self: &Utils, user_input: QString) -> QUrl;
    }
}

use cxx_qt_lib::QString;
use cxx_qt_lib::QUrl;
use std::env;
use std::path::Path;

#[derive(Default)]
pub struct BrowserUtilsRust {
    user_input: QString,
}

impl qobject::Utils {
    pub fn from_user_input(&self, user_input: QString) -> QUrl {
        let input = user_input.to_string();
        let file_info = Path::new(&input);

        if file_info.exists() {
            QUrl::from_local_file(&QString::from(file_info.to_string_lossy().to_string()))
        } else {
            let working_directory = env::current_dir()
                .map(|path| path.to_string_lossy().to_string())
                .unwrap_or_else(|_| String::new());

            let working_directory_qstr = QString::from(working_directory);
            QUrl::from_user_input(&QString::from(&input), &working_directory_qstr)
        }
    }
}
