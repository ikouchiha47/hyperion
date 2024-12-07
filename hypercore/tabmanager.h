#ifndef TABMANAGER_H
#define TABMANAGER_H

#include <QObject>
#include <QList>
#include <QVector>
#include <QVariantMap>
#include <QVariantList>
#include <QDateTime>
#include <QHash>
#include <QString>
#include <QHash>
#include <QCache>
#include <QVariant>
#include <QDateTime>
#include <memory>
#include <qcontainerfwd.h>
#include <qobject.h>

#include "tiler.h" 

struct TabInfo {
    QString name;                      
    QDateTime timestamp;               
    LayoutTree layoutTree;    
    int activeWindowID;

    QString getUniqueId() const {
        return QString("%1_%2").arg(name, timestamp.toString("yyyyMMddHHmmsszzz"));
    }

    QVariantList traverseList(const std::shared_ptr<ContainerNode> root) const {
        QVariantList result;
        auto nodes = root->Traverse();

        for(const auto& node: nodes) {
            QVariantMap nodeData;

            nodeData["id"] = static_cast<qint64>(node->id);
            nodeData["type"] = (node->node_type == NodeType::Window) ? "window": "split";
            nodeData["direction"] = (node->orientation == SplitDirection::Horizontal) ? "horizontal" : "vertical";

            if(node->attrs) {
                nodeData["title"] = QString::fromStdString(node->attrs->name); 
                nodeData["url"] = QString::fromStdString(node->attrs->url);
            }

            QVariantList childList;
            for(const auto& child: node->children) {
                childList.append(TabInfo::traverseList(child));
            }

            nodeData["children"] = childList;
        
            result.append(nodeData);
        }

        return result;
    }
};

class TabManager: public QObject {
    Q_OBJECT

public:
    explicit TabManager(QObject* parent = nullptr); 

    Q_INVOKABLE void addTab(const QString& tabName, const QString& url);
    Q_INVOKABLE void removeTab(const QString& uniqueId);
    Q_INVOKABLE void addSplit(const QString& uniqueId, int parentId, int direction, const QString &title, const QString& url, int width, int height);
    Q_INVOKABLE void removeSplit(const QString& uniqueId, int windowId);

    Q_INVOKABLE void setActiveTab(const QString& uniqueId);
    Q_INVOKABLE void setActiveWindow(const QString& uniqueId, int windowId);

    Q_INVOKABLE QVariantList getLayoutTree(const QString& uniqueId, int nodeId) const;

signals:
    void layoutUpdated(const QString& uniqueId, QVariantList layout);

private:
    QList<TabInfo> tabStore;
    QString activeTabID;
    int activeWindowId;
    std::shared_ptr<ContainerNode> activeWindow;
};

#endif // TABMANAGER_H
