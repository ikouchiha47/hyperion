// https://cxx.rs/
// Example: 
// https://github.com/dtolnay/cxx/blob/master/demo/src/main.rs
// https://kdab.github.io/cxx-qt/book/getting-started/2-our-first-cxx-qt-module.html
// // Shared structs with fields visible to both languages.
// // Rust types and signatures exposed to C++., using extern
// // C++ types and signatures exposed to Rust.
// // Rust implementation of shared struct definition in rust
#[cxx_qt::bridge]
pub mod qobject {

    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        /// An alias to the QString type
        type QString = cxx_qt_lib::QString;
    }    

    
    unsafe extern "RustQt" {
        // The QObject definition
        // We tell CXX-Qt that we want a QObject class with the name MyObject
        // based on the Rust struct MyObjectRust.
        // qproperty: https://doc.qt.io/qt-6/properties.html 
        #[qobject]
        #[qml_element]
        #[qproperty(i32, number)]
        #[qproperty(QString, string)]
        #[namespace = "hyperobject"]
        type HyperObject = super::HyperObjectRust;
    }

    unsafe extern "RustQt" {
        // Declare the invokable methods we want to expose on the QObject
        // qinvokable: https://doc.qt.io/qt-6/qtqml-cppintegration-exposecppattributes.html#exposing-methods-including-qt-slots
        #[qinvokable]
        #[cxx_name = "incrementNumber"]
        fn increment_number(self: Pin<&mut HyperObject>);

        #[qinvokable]
        #[cxx_name = "sayHi"]
        fn say_hi(self: &HyperObject, string: &QString, number: i32);
    }
}

// Implementation of HyperObject
use core::pin::Pin;
use cxx_qt_lib::QString;

/// The Rust struct for the QObject
#[derive(Default)]
pub struct HyperObjectRust {
    number: i32,
    string: QString,
}

impl qobject::HyperObject {
    /// Increment the number Q_PROPERTY
    pub fn increment_number(self: Pin<&mut Self>) {
        let previous = *self.number();
        self.set_number(previous + 1);
    }

    /// Print a log message with the given string and number
    pub fn say_hi(&self, string: &QString, number: i32) {
        println!("Hi from Rust! String is '{string}' and number is {number}");
    }
}
