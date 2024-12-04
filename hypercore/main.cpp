// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include "utils.h"
#include "interceptor.h"

#include <QtWebEngineQuick/qtwebenginequickglobal.h>

#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlContext>

#include <QtGui/QGuiApplication>

#include <QtCore/QCommandLineParser>
#include <QtCore/QCommandLineOption>
#include <QtCore/QLoggingCategory>
#include <QQuickWebEngineProfile>

// #include "thieflite.h"


static QUrl startupUrl() {
    QUrl ret;
    QStringList args(qApp->arguments());
    args.takeFirst();

    for (const QString &arg : std::as_const(args)) {
        if (arg.startsWith(QLatin1Char('-')))
             continue;

        ret = Utils::fromUserInput(arg);
        if (ret.isValid())
            return ret;
    }
    return QUrl(QStringLiteral("chrome://qt"));
}

int main(int argc, char **argv) {
    QCoreApplication::setApplicationName("Hyperion");
    QCoreApplication::setOrganizationName("Hyperion");

    QtWebEngineQuick::initialize();

    QGuiApplication app(argc, argv);

    QLoggingCategory::setFilterRules(
        "qt.webenginecontext.debug=true\n"
        "qt.webenginepage.debug=true\n"
        "qt.webengine.debug=true"
    );

    QQmlApplicationEngine appEngine;
    CustomInterceptor *interceptor = new CustomInterceptor(&app);

    QQuickWebEngineProfile *defaultProfile = QQuickWebEngineProfile::defaultProfile();
    defaultProfile->setUrlRequestInterceptor(interceptor);

    // TFLiteModel::instance();
    // TFLiteModel::instance()->loadModel("../thparty/include/mlmodels/phishing_detection.tflite");

    // qDebug() << "model loaded" << TFLiteModel::instance()->isModelLoaded();

    // static auto instance = TFLiteModel::instance();

    appEngine.rootContext()->setContextProperty("customInterceptor", interceptor);
    // appEngine.rootContext()->setContextProperty("fishDetector", instance);

    appEngine.load(QUrl("qrc:/qml/ApplicationRoot.qml"));

    if (appEngine.rootObjects().isEmpty())
        qFatal("Failed to load sources");


    QMetaObject::invokeMethod(appEngine.rootObjects().constFirst(),
                              "load", 
                              Q_ARG(QVariant, startupUrl()));


    return app.exec();
}
