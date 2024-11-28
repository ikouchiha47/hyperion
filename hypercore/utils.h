// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#ifndef UTILS_H
#define UTILS_H

#include <QtQml/qqml.h>

#include <QtCore/QFileInfo>
#include <QtCore/QUrl>

class Utils : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
public:
    Q_INVOKABLE static QUrl fromUserInput(const QString &userInput, bool toSSL);
};

inline QUrl Utils::fromUserInput(const QString &userInput, bool toSSL = true)
{
    const QStringList sslAbleProtocols = {
        "http:", "ws:", "ftp:", "smtp:", "pop3:", "imap:", "ldap:", "irc:", "nntp:", "xmpp:"
    };

    // QString cleanedInput = userInput.trimmed().replace(QRegExp("\\s+"), "");
    if (toSSL && sslAbleProtocols.contains(userInput.section(':', 0, 0) + ":")) {
        QUrl url(userInput);

        QString protocol = url.scheme();

        if (protocol == "xmpp") {
            url.setScheme("xmpp+tls");
        } else if (sslAbleProtocols.contains(protocol + ":")) {
            url.setScheme(protocol + "s");
        }

        return url;
    }

    QFileInfo fileInfo(userInput);
    if (fileInfo.exists())
        return QUrl::fromLocalFile(fileInfo.absoluteFilePath());
    return QUrl::fromUserInput(userInput);
}

#endif // UTILS_H
