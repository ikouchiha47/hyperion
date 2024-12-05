use std::usize;

#[derive(Debug, Clone)]
pub enum SplitDirection {
    Horizontal,
    Vertical,
}

// Container is equivalent of
// a Tab in browser

#[derive(Debug, Clone)]
enum NodeType {
    Split(SplitDirection),
    Window,
}

#[derive(Debug, Clone)]
struct ContainerNode {
    id: usize,
    node_type: NodeType,
    children: Vec<Box<ContainerNode>>,
}

impl ContainerNode {
    fn new_split(id: usize, direction: SplitDirection) -> Self {
        Self {
            id,
            node_type: NodeType::Split(direction),
            children: Vec::new(),
        }
    }

    fn new_window(id: usize) -> Self {
        Self {
            id,
            node_type: NodeType::Window,
            children: Vec::new(),
        }
    }

    fn add_child(&mut self, child: ContainerNode) {
        self.children.push(Box::new(child));
    }
}

// initial node: LayoutNode {id: 0, type: Window, parent: 0, nodes: None}
// split into two
//
// LayoutNode{
// id: 1,
// type: SplitH,
// parent: 0,
// nodes: [
//  LayoutNode{id: 1, type: Window, parent: 0,nodes: None},
//  LayoutNode{id: 2, type: Window, parent: 0,nodes: None}]
// }
//
// split right side into 2
//
// LayoutNode{
// type: SpitH,
// parent: 0,
// nodes: [
//  LayoutNode{ type: Window, parent: 0,nodes: None},
//  LayoutNode{type: SplitV, parent: 0,nodes: [
//      LayoutNode{type: Window, ...},
//      ...
//  ]}]
// }
//

#[derive(Debug)]
pub struct LayoutTree {
    root: ContainerNode,
    next_id: usize,
}

impl LayoutTree {
    pub fn new() -> Self {
        Self {
            root: ContainerNode::new_window(1),
            next_id: 1,
        }
    }

    pub fn add_window(
        &mut self,
        parent_id: usize,
        direction: SplitDirection,
    ) -> Result<usize, &'static str> {
        return self.add_window_internal(parent_id, Some(direction));
    }

    pub fn get_id(&mut self) -> usize {
        return self.next_id;
    }

    fn add_window_internal(
        &mut self,
        parent_id: usize,
        direction: Option<SplitDirection>,
    ) -> Result<usize, &'static str> {
        let mut stack = vec![&mut self.root];

        while let Some(current) = stack.pop() {
            if current.id == parent_id {
                match current.node_type {
                    NodeType::Window => {
                        // If it's a Window, convert it to a Split
                        if let Some(split_direction) = direction {
                            self.next_id += 1;

                            let new_window = ContainerNode::new_window(self.next_id);

                            // Convert the current node into a split node
                            let split_node = ContainerNode::new_split(current.id, split_direction);

                            // Move the current node's data into a new child node
                            let mut new_child = ContainerNode::new_window(current.id);
                            std::mem::swap(current, &mut new_child);

                            // Update the current node to become the split node
                            *current = split_node;

                            // Add the previous node and the new window as children
                            current.add_child(new_child);
                            current.add_child(new_window);

                            return Ok(self.next_id);
                        } else {
                            return Err("Split direction is required for splitting a window");
                        }
                    }
                    NodeType::Split(_) => {
                        // Add a new window to the split or workspace
                        self.next_id += 1;

                        current.add_child(ContainerNode::new_window(self.next_id));
                        return Ok(self.next_id);
                    }
                }
            }

            // Traverse children
            for child in current.children.iter_mut() {
                stack.push(child);
            }
        }

        Err("Parent node not found")
    }
}
