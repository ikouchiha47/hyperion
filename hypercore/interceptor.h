#include <QWebEngineUrlRequestInterceptor>
#include <QWebEngineUrlRequestInfo>

class CustomInterceptor : public QWebEngineUrlRequestInterceptor
{
    Q_OBJECT
    Q_PROPERTY(bool redirectToHttps READ redirectToHttps WRITE setRedirectToHttps NOTIFY redirectToHttpsChanged)
    
public:
    explicit CustomInterceptor(QObject *parent = nullptr, bool redirectToHttps = true);
    virtual void interceptRequest(QWebEngineUrlRequestInfo &info) override;

    bool redirectToHttps() const;
    void setRedirectToHttps(bool enable);

signals:
    void redirectToHttpsChanged();

private:
    bool m_redirectToHttps;
};

