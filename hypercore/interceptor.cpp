#include "interceptor.h"

#include <QWebEngineUrlRequestInfo>
#include <QUrl>
#include <QDebug>

CustomInterceptor::CustomInterceptor(QObject *parent, bool redirectToHttps): 
    QWebEngineUrlRequestInterceptor(parent), m_redirectToHttps(redirectToHttps) {}

// CustomInterceptor::CustomInterceptor(QObject *parent): QWebEngineUrlRequestInterceptor(parent) {}

void CustomInterceptor::interceptRequest(QWebEngineUrlRequestInfo &info) {
    QUrl url = info.requestUrl();

    QString host = url.host();

    if (host == "localhost") {
        return;
    }

    if (m_redirectToHttps && url.scheme() == "http") {
        QUrl secureUrl = info.requestUrl();
        secureUrl.setScheme("https");
        info.redirect(secureUrl);
    }
}

bool CustomInterceptor::redirectToHttps() const {
    return m_redirectToHttps;
}

void CustomInterceptor::setRedirectToHttps(bool enable) {
    if (m_redirectToHttps != enable) {
        m_redirectToHttps = enable;
        emit redirectToHttpsChanged();
    }
};

