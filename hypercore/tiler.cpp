#include "tiler.h"
#include <chrono>
#include <cstdint>
#include <stack>
#include <stdexcept>
#include <optional>
#include <unistd.h>

LayoutTree LayoutTree::New(std::shared_ptr<Metadata> attrs) {
    auto n_id = std::chrono::system_clock::now().time_since_epoch().count();
    return LayoutTree(ContainerNode::NewWindow(n_id, nullptr, attrs), n_id);
}

// Constructor
LayoutTree::LayoutTree(std::shared_ptr<ContainerNode> root, int64_t prev_id)
    : m_root(root), prev_id(prev_id) {}

// Add a new window to the tree
int64_t LayoutTree::AddWindow(int64_t parent_id, SplitDirection direction, std::shared_ptr<Metadata> attrs) {
    std::stack<std::shared_ptr<ContainerNode>> stack;
    stack.push(m_root);

    while (!stack.empty()) {
        auto current = stack.top();
        stack.pop();

        if (current->id == parent_id) {
            if (current->node_type == NodeType::Window) {
                this->prev_id = prev_id+1;
                auto new_window = ContainerNode::NewWindow(prev_id, std::make_shared<int64_t>(current->id), attrs);

                this->prev_id = prev_id+1;
                auto new_child = ContainerNode::NewWindow(prev_id, std::make_shared<int64_t>(current->id), current->attrs);

                auto split_node = ContainerNode::NewSplit(current->id, current->parent_id, direction);
                split_node->AddChild(new_child);
                split_node->AddChild(new_window);

                *current = *split_node;
                return new_window->id;
            } else if (current->node_type == NodeType::Split) {
                prev_id++;
                auto new_window = ContainerNode::NewWindow(prev_id, std::make_shared<int64_t>(current->id), attrs);
                current->AddChild(new_window);
                return new_window->id;
            }
        }

        for (auto& child : current->children) {
            stack.push(child);
        }
    }

    return -1;
}

// Update attributes of a node with the given window ID
void LayoutTree::UpdateAttrs(int64_t window_id, std::shared_ptr<Metadata> updated_attrs) {
    std::stack<std::shared_ptr<ContainerNode>> stack;
    stack.push(m_root);

    while (!stack.empty()) {
        auto current = stack.top();
        stack.pop();

        if (current->id == window_id) {
            current->attrs = updated_attrs;
            return;
        }

        for (auto& child : current->children) {
            stack.push(child);
        }
    }

    return;
}

// Traverse the tree and return all nodes
std::optional<std::vector<std::shared_ptr<ContainerNode>>> LayoutTree::Traverse() {
    if (!m_root) {
        return std::nullopt;
    }
    return m_root->Traverse();
}

std::optional<std::shared_ptr<ContainerNode>> LayoutTree::FindContainer(int64_t parentId) {
    if(m_root->id == parentId) {
        return m_root;
    }

    std::stack<std::shared_ptr<ContainerNode>> stack;
    stack.push(m_root);

    while (!stack.empty()) {
        auto current = stack.top();
        stack.pop();
    

        if (current->id == parentId) {
            return  current;
        }

        for(auto& child: current->children) {
            stack.push(child);
        }
    }

    return std::nullopt;
}

// Remove a window by ID
void LayoutTree::RemoveWindow(int64_t window_id) {
    if (m_root->id == window_id) {
       throw std::runtime_error("Cannot remove the root node");
    }

    std::stack<std::shared_ptr<ContainerNode>> stack;
    stack.push(m_root);

    while (!stack.empty()) {
        auto current = stack.top();
        stack.pop();

        try {
            auto removed = current->RemoveChild(window_id);
            if (current->node_type == NodeType::Split && current->children.size() == 1) {
                *current = *(current->children.front());
            }
            return;
        } catch (const std::runtime_error&) {
            // Continue searching
        }

        for (auto& child : current->children) {
            stack.push(child);
        }
    }

    // throw std::runtime_error("Window ID not found");
}

// Factory method to create a new window node
std::shared_ptr<ContainerNode> ContainerNode::NewWindow(int64_t id, std::shared_ptr<int64_t> parent_id, std::shared_ptr<Metadata> attrs) {
    return std::make_shared<ContainerNode>(ContainerNode{id, parent_id, NodeType::Window, SplitDirection::Horizontal, attrs, {}});
}

// Factory method to create a new split node
std::shared_ptr<ContainerNode> ContainerNode::NewSplit(int64_t id, std::shared_ptr<int64_t> parent_id, SplitDirection direction) {
    return std::make_shared<ContainerNode>(ContainerNode{id, parent_id, NodeType::Split, direction, nullptr, {}});
}

// Add a child node
void ContainerNode::AddChild(std::shared_ptr<ContainerNode> child) {
    children.push_back(child);
}

// Remove a child node by ID
std::optional<std::shared_ptr<ContainerNode>> ContainerNode::RemoveChild(int64_t window_id) {
    for (auto it = children.begin(); it != children.end(); ++it) {
        if ((*it)->id == window_id) {
            auto removed = *it;
            children.erase(it);
            return removed;
        }
    }
    
    return std::nullopt;
}

// Traverse the tree and return all nodes
std::vector<std::shared_ptr<ContainerNode>> ContainerNode::Traverse() {
    std::vector<std::shared_ptr<ContainerNode>> result;
    std::stack<std::shared_ptr<ContainerNode>> stack;

    stack.push(std::make_shared<ContainerNode>(*this));
    while (!stack.empty()) {
        auto current = stack.top();
        stack.pop();
        result.push_back(current);

        for (auto it = current->children.rbegin(); it != current->children.rend(); ++it) {
            stack.push(*it);
        }
    }

    return result;
}
