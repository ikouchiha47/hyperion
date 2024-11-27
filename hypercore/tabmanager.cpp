#include <QObject>
#include <QStringList>
#include <QDebug>

class TabStateManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QStringList activeTabs READ activeTabs NOTIFY activeTabsChanged)
    Q_PROPERTY(QStringList normalTabs READ normalTabs NOTIFY normalTabsChanged)

public:
    explicit TabStateManager(QObject *parent = nullptr) : QObject(parent) {}

    QStringList activeTabs() const { return m_activeTabs; }
    QStringList normalTabs() const { return m_normalTabs; }

    Q_INVOKABLE void addTab(const QString &tabTitle) {
        if (m_activeTabs.contains(tabTitle) || m_normalTabs.contains(tabTitle)) {
            return; // Ignore duplicate tabs
        }

        if (m_activeTabs.size() < 3) {
            m_activeTabs.append(tabTitle);
        } else {
            m_normalTabs.append(tabTitle);
        }
        emit activeTabsChanged();
        emit normalTabsChanged();
    }

    Q_INVOKABLE void removeTab(const QString &tabTitle) {
        if (m_activeTabs.removeOne(tabTitle)) {
            if (!m_normalTabs.isEmpty()) {
                m_activeTabs.append(m_normalTabs.takeFirst());
            }
        } else {
            m_normalTabs.removeOne(tabTitle);
        }
        emit activeTabsChanged();
        emit normalTabsChanged();
    }

signals:
    void activeTabsChanged();
    void normalTabsChanged();

private:
    QStringList m_activeTabs;
    QStringList m_normalTabs;
};
