use std::time::{SystemTime, UNIX_EPOCH};
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

#[repr(C)]
pub struct CMetadata {
    pub name: *const i8,
    pub id: usize,
    pub x: usize,
    pub y: usize,
    pub width: usize,
    pub height: usize,
    pub focus: bool,
    pub halted: bool,
}

impl CMetadata {
    pub fn to_c(metadata: &Metadata) -> Self {
        return Self {
            name: metadata.name,
            id: metadata.id,
            x: metadata.x.unwrap_or(0),
            y: metadata.y.unwrap_or(0),
            width: metadata.width.unwrap_or(0),
            height: metadata.height.unwrap_or(0),
            focus: metadata.focus,
            halted: metadata.halted,
        };
    }

    pub fn from_c(cmetadata: &CMetadata) -> Metadata {
        let x = match cmetadata.x {
            0 => None,
            x => Some(x),
        };
        let y = match cmetadata.y {
            0 => None,
            y => Some(y),
        };
        let width = match cmetadata.width {
            0 => None,
            w => Some(w),
        };
        let height = match cmetadata.height {
            0 => None,
            h => Some(h),
        };

        return Metadata {
            name: cmetadata.name,
            id: cmetadata.id,
            x,
            y,
            width,
            height,
            focus: cmetadata.focus,
            halted: cmetadata.halted,
        };
    }
}

#[derive(Debug, Clone)]
pub struct Metadata {
    name: *const i8,
    id: usize,
    x: Option<usize>,
    y: Option<usize>,
    width: Option<usize>,
    height: Option<usize>,
    focus: bool,
    halted: bool,
}

impl Metadata {
    pub fn new(
        name: *const i8,
        id: usize,
        x: Option<usize>,
        y: Option<usize>,
        width: Option<usize>,
        height: Option<usize>,
    ) -> Self {
        return Self {
            name,
            id,
            x,
            y,
            width,
            height,
            focus: true,
            halted: false,
        };
    }

    pub fn toggle_focus(&mut self) {
        self.focus = !self.focus
    }
}

#[derive(Debug, Clone)]
struct ContainerNode {
    parent_id: usize,
    node_type: NodeType,
    attrs: Option<Metadata>,
    children: Vec<Box<ContainerNode>>,
}

impl ContainerNode {
    fn new_split(id: usize, direction: SplitDirection) -> Self {
        Self {
            parent_id: id,
            attrs: None,
            node_type: NodeType::Split(direction),
            children: Vec::new(),
        }
    }

    fn new_window(id: usize, attrs: Option<&Metadata>) -> Self {
        Self {
            parent_id: id,
            attrs: attrs.cloned(),
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
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("Time went backwards")
            .as_millis() as usize;

        Self {
            root: ContainerNode::new_window(timestamp, None),
            next_id: timestamp,
        }
    }

    pub fn add_window(
        &mut self,
        parent_id: usize,
        direction: SplitDirection,
        attrs: Option<&Metadata>,
    ) -> Result<usize, &'static str> {
        return self.add_window_internal(parent_id, Some(direction), attrs);
    }

    pub fn get_id(&mut self) -> usize {
        return self.next_id;
    }

    fn add_window_internal(
        &mut self,
        parent_id: usize,
        direction: Option<SplitDirection>,
        attrs: Option<&Metadata>,
    ) -> Result<usize, &'static str> {
        let mut stack = vec![&mut self.root];

        while let Some(current) = stack.pop() {
            if current.parent_id == parent_id {
                match current.node_type {
                    NodeType::Window => {
                        // If it's a Window, convert it to a Split
                        if let Some(split_direction) = direction {
                            self.next_id += 1;

                            let new_window = ContainerNode::new_window(self.next_id, attrs);

                            // Convert the current node into a split node
                            let split_node =
                                ContainerNode::new_split(current.parent_id, split_direction);

                            // Move the current node's data into a new child node
                            let mut new_child = ContainerNode::new_window(current.parent_id, attrs);
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

                        current.add_child(ContainerNode::new_window(self.next_id, attrs));
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
