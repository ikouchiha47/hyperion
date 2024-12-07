
#include <QObject>
#include <QString>

class Metadata : public QObject {
    Q_OBJECT

    Q_PROPERTY(QString data READ data WRITE setData NOTIFY dataChanged)
    Q_PROPERTY(QString title READ title WRITE setTitle NOTIFY titleChanged)
    Q_PROPERTY(QString url READ url WRITE setUrl NOTIFY urlChanged)
    Q_PROPERTY(int width READ width WRITE setWidth NOTIFY widthChanged)
    Q_PROPERTY(int height READ height WRITE setHeight NOTIFY heightChanged)

public:
    explicit Metadata(QObject* parent = nullptr)
        : QObject(parent), m_width(0), m_height(0) {}

    Metadata(const QString& data, const QString& title, const QString& url, int width, int height, QObject* parent = nullptr)
        : QObject(parent), m_data(data), m_title(title), m_url(url), m_width(width), m_height(height) {}

    QString data() const { return m_data; }
    void setData(const QString& data) {
        if (m_data != data) {
            m_data = data;
            emit dataChanged();
        }
    }

    QString title() const { return m_title; }
    void setTitle(const QString& title) {
        if (m_title != title) {
            m_title = title;
            emit titleChanged();
        }
    }

    QString url() const { return m_url; }
    void setUrl(const QString& url) {
        if (m_url != url) {
            m_url = url;
            emit urlChanged();
        }
    }

    int width() const { return m_width; }
    void setWidth(int width) {
        if (m_width != width) {
            m_width = width;
            emit widthChanged();
        }
    }

    int height() const { return m_height; }
    void setHeight(int height) {
        if (m_height != height) {
            m_height = height;
            emit heightChanged();
        }
    }

    int parentID() const { return m_parentID; }
    void setParentID(int parentID) {
        if(parentID != m_parentID) {
            m_parentID = parentID;
        }
    }

    int windowID() const { return m_windowID; }
    void setWindowID(int windowID) {
        if(windowID != m_windowID) {
            m_windowID = windowID;
        }
    }

signals:
    void dataChanged();
    void titleChanged();
    void urlChanged();
    void widthChanged();
    void heightChanged();

private:
    QString m_data;
    QString m_title;
    QString m_url;
    int m_width;
    int m_height;
    int m_parentID;
    int m_windowID;
};
