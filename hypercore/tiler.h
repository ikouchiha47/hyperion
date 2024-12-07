// Converted from the rust
#ifndef TILER_H
#define TILER_H

#include <cstdint>
#include <vector>
#include <memory>
#include <string>
#include <optional>

// Enum for split direction
enum class SplitDirection {
    Horizontal = 1,
    Vertical = 2
};

// Enum for node type
enum class NodeType {
    Window = 4,
    Split = 5
};

// Metadata structure
struct Metadata {
    std::string name;
    std::string url;
    int id;
    int width;
    int height;
    bool halted;
};

// Forward declaration of ContainerNode
struct ContainerNode;

// LayoutTree class definition
class LayoutTree {
public:
    // Constructor to create a new layout tree
    static LayoutTree New(std::shared_ptr<Metadata> attrs);

    // Add a new window to the tree
    int64_t AddWindow(int64_t parentId, SplitDirection direction, std::shared_ptr<Metadata> attrs);

    // Update attributes of a node by window ID
    void UpdateAttrs(int64_t windowId, std::shared_ptr<Metadata> updated_attrs);

    // Traverse the tree and return all nodes
    std::optional<std::vector<std::shared_ptr<ContainerNode>>> Traverse();

    // Remove a window by ID
    void RemoveWindow(int64_t window_id);

    // Find a window or split by id
    std::optional<std::shared_ptr<ContainerNode>> FindContainer(int64_t parentId);

    std::shared_ptr<ContainerNode> root() const { return m_root;}

private:
    std::shared_ptr<ContainerNode> m_root;
    int64_t prev_id;

    LayoutTree(std::shared_ptr<ContainerNode> root, int64_t prev_id);
};

// ContainerNode class definition
struct ContainerNode {
    int64_t id;
    std::shared_ptr<int64_t> parent_id;
    NodeType node_type;
    SplitDirection orientation;
    std::shared_ptr<Metadata> attrs;
    std::vector<std::shared_ptr<ContainerNode>> children;

    // Static methods for creating new nodes
    static std::shared_ptr<ContainerNode> NewWindow(int64_t id, std::shared_ptr<int64_t> parent_id, std::shared_ptr<Metadata> attrs);
    static std::shared_ptr<ContainerNode> NewSplit(int64_t id, std::shared_ptr<int64_t> parent_id, SplitDirection direction);

    // Add a child node
    void AddChild(std::shared_ptr<ContainerNode> child);

    // Remove a child node by ID
    std::optional<std::shared_ptr<ContainerNode>> RemoveChild(int64_t window_id);

    // Traverse the tree and return all nodes
    std::vector<std::shared_ptr<ContainerNode>> Traverse();
};

#endif // TILER_H
