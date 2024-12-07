#include "tabmanager.h"
#include <memory>
#include <qcontainerfwd.h>
#include <qobject.h>

TabManager::TabManager(QObject *parent): QObject(parent) {}

void TabManager::addTab(const QString& tabName, const QString& url) {
    auto metadata = std::make_shared<Metadata>();
    metadata->name = tabName.toStdString();
    metadata->url = url.toStdString();

    QDateTime timestamp = QDateTime::currentDateTime();
    LayoutTree tree = LayoutTree::New(metadata);

    TabInfo tabInfo = {tabName, timestamp, std::move(tree)};
    tabStore.append(tabInfo);

    if (tabStore.size() == 1) {
        auto uniqueId = tabInfo.getUniqueId();
        setActiveTab(uniqueId); 
        setActiveWindow(uniqueId, tabInfo.layoutTree.root()->id);
    }

    return;
}

void TabManager::removeTab(const QString& uniqueId) {
    for (int i = 0; i < tabStore.size(); ++i) {
        if (tabStore[i].getUniqueId() == uniqueId) {
            tabStore.removeAt(i);

            if (activeTabID == uniqueId) {
                activeTabID = tabStore.isEmpty() ? "" : tabStore.first().getUniqueId();
                activeWindow = nullptr;
            }

            emit layoutUpdated(uniqueId, {});
            return;
        }
    }
}

SplitDirection toDirection(int direction) {
    if (direction == 1) {
        return SplitDirection::Horizontal;
    }

    return SplitDirection::Vertical;
}

void TabManager::addSplit(const QString& uniqueId, int parentId, int direction, const QString &title, const QString& url, int width, int height) {
    auto attrs = std::make_shared<Metadata>();

    attrs->name = title.toStdString();
    attrs->url = url.toStdString();
    attrs->width = width;
    attrs->height = height;
    
   for(auto& tab: tabStore) {
        if (tab.getUniqueId() == uniqueId) {
            int newWindowID = tab.layoutTree.AddWindow(parentId,toDirection(direction), attrs);

            // assert(newWindowId != -1)
            tab.activeWindowID = newWindowID;
            setActiveWindow(uniqueId, newWindowID);

            emit layoutUpdated(uniqueId, getLayoutTree(uniqueId, newWindowID));
            return;
        }
    }
}

void TabManager::removeSplit(const QString& uniqueId, int windowId) {
    for(auto& tab: tabStore) {
    if (tab.getUniqueId() == uniqueId) {
            tab.layoutTree.RemoveWindow(windowId);
            return;
        }
    }
}

QVariantList TabManager::getLayoutTree(const QString& uniqueId, int nodeId) const {
    for(auto& tab: tabStore) {
        if (tab.getUniqueId() == uniqueId) {
            return tab.traverseList(tab.layoutTree.root());
        }
    }

    QVariantList result;
    return result;
}

void TabManager::setActiveTab(const QString& uniqueId) {
    activeTabID = uniqueId;
}

void TabManager::setActiveWindow(const QString& uniqueId, int windowId) {
    activeWindowId = windowId;

    for(auto& tab: tabStore) {
        if (tab.getUniqueId() == uniqueId) {
            auto node = tab.layoutTree.FindContainer(windowId);

            if(node.has_value()) {
                activeWindow = node.value();
            }
        }
    }
}
