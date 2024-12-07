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
pub enum CNodeType {
    SplitHorizontal = 0,
    SplitVertical = 1,
    Window = 2,
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

#[derive(Clone)]
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
pub struct ContainerNode {
    id: usize,
    parent_id: Option<usize>,
    node_type: NodeType,
    attrs: Option<Metadata>,
    children: Vec<Box<ContainerNode>>,
}

impl ContainerNode {
    fn new_split(id: usize, parent_id: Option<usize>, direction: SplitDirection) -> Self {
        Self {
            id,
            parent_id,
            attrs: None,
            node_type: NodeType::Split(direction),
            children: Vec::new(),
        }
    }

    fn new_window(id: usize, parent_id: Option<usize>, attrs: Option<&Metadata>) -> Self {
        Self {
            id,
            parent_id,
            attrs: attrs.cloned(),
            node_type: NodeType::Window,
            children: Vec::new(),
        }
    }

    fn add_child(&mut self, child: ContainerNode) {
        self.children.push(Box::new(child));
    }
}

#[derive(Clone)]
#[repr(C)]
pub struct CContainerNode {
    id: usize,
    parent_id: usize,
    node_type: usize,
    attrs: *const CMetadata,
    child: *mut CContainerNode,
    next: *mut CContainerNode,
}

impl CContainerNode {
    pub fn to_c(node: &ContainerNode) -> CContainerNode {
        let mut first_child: *mut CContainerNode = std::ptr::null_mut();
        let mut last_sibling: *mut CContainerNode = std::ptr::null_mut();

        // Build the children linked list
        for child in &node.children {
            let c_child = Box::into_raw(Box::new(CContainerNode::to_c(child)));
            if first_child.is_null() {
                first_child = c_child;
                last_sibling = c_child;
            } else {
                unsafe { (*last_sibling).next = c_child };
                last_sibling = c_child;
            }
        }

        CContainerNode {
            id: node.id,
            parent_id: node.parent_id.unwrap_or(0), // Use 0 for None
            node_type: match node.node_type {
                NodeType::Split(SplitDirection::Horizontal) => 0,
                NodeType::Split(SplitDirection::Vertical) => 1,
                NodeType::Window => 2,
            },
            attrs: node.attrs.as_ref().map_or(std::ptr::null(), |a| {
                Box::into_raw(Box::new(CMetadata::to_c(a)))
            }),
            child: first_child,
            next: last_sibling,
        }
    }

    pub fn free(node: *mut CContainerNode) {
        if node.is_null() {
            return;
        }

        unsafe {
            // Take ownership of the current node
            let cnode = Box::from_raw(node);

            let mut child_ptr = cnode.child;
            while !child_ptr.is_null() {
                let next_sibling = (*child_ptr).next;
                CContainerNode::free(child_ptr);
                child_ptr = next_sibling;
            }

            // Free the attributes (if any)
            if !cnode.attrs.is_null() {
                let _ = Box::from_raw(cnode.attrs as *mut CMetadata);
            }
        }
    }

    pub fn from_c(c_container: *const CContainerNode) -> Option<ContainerNode> {
        if c_container.is_null() {
            return None;
        }

        unsafe {
            let mut node_map = std::collections::HashMap::new();
            let mut stack = vec![c_container];

            // Process the nodes iteratively
            while let Some(c_node_ptr) = stack.pop() {
                let c_node = &*c_node_ptr;

                // Create or get the Rust node
                node_map.entry(c_node_ptr).or_insert_with(|| ContainerNode {
                    id: c_node.id,
                    parent_id: if c_node.parent_id == 0 {
                        None
                    } else {
                        Some(c_node.parent_id)
                    },
                    node_type: match c_node.node_type {
                        0 => NodeType::Split(SplitDirection::Horizontal),
                        1 => NodeType::Split(SplitDirection::Vertical),
                        _ => NodeType::Window,
                    },
                    attrs: Some(CMetadata::from_c(&*c_node.attrs)),
                    children: Vec::new(),
                });

                // Process children
                let mut child_ptr = c_node.child;
                while !child_ptr.is_null() {
                    stack.push(child_ptr);

                    let child_id = (*child_ptr).id;

                    // Add the child node to the parent node's children
                    if let Some(rust_node) = node_map.get_mut(&c_node_ptr) {
                        rust_node.children.push(Box::new(ContainerNode {
                            id: child_id,
                            parent_id: Some(c_node.id),
                            node_type: NodeType::Window, // Default value for now
                            attrs: None,                 // Will be updated when processed
                            children: Vec::new(),
                        }));
                    }

                    // Move to the next sibling
                    child_ptr = (*child_ptr).next;
                }
            }

            node_map.get(&c_container).cloned()
        }
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

#[repr(C)]
pub struct CLayoutTree {
    root: *const CContainerNode,
    next_id: usize,
}

impl CLayoutTree {
    pub fn from_c(clayout: *const CLayoutTree) -> Option<LayoutTree> {
        if clayout.is_null() {
            return None;
        }

        let c_layout = unsafe { &*clayout };
        let root = CContainerNode::from_c(c_layout.root)?;

        return Some(LayoutTree {
            root,
            next_id: c_layout.next_id,
        });
    }

    pub fn new(cmetadata: *const CMetadata) -> Option<CLayoutTree> {
        if cmetadata.is_null() {
            return None;
        }

        let c_metadata = unsafe { CMetadata::from_c(&*cmetadata) };
        let layout = LayoutTree::new(&c_metadata);

        let croot = CContainerNode::to_c(&layout.root);

        return Some(CLayoutTree {
            root: &croot,
            next_id: layout.next_id,
        });
    }

    pub fn free(tree: *mut CLayoutTree) {
        if tree.is_null() {
            return;
        }

        unsafe {
            let clayout_tree = Box::from_raw(tree);

            if !clayout_tree.root.is_null() {
                CContainerNode::free(clayout_tree.root as *mut CContainerNode);
            }
        }
    }

    pub fn set_root(&mut self, root: *const CContainerNode) {
        self.root = root;
    }

    pub fn set_next_id(&mut self, next_id: usize) {
        self.next_id = next_id;
    }
}

#[derive(Debug)]
pub struct LayoutTree {
    root: ContainerNode,
    next_id: usize,
}

impl LayoutTree {
    pub fn new(attrs: &Metadata) -> Self {
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("Time went backwards")
            .as_millis() as usize;

        Self {
            root: ContainerNode::new_window(timestamp, None, Some(attrs)),
            next_id: timestamp,
        }
    }

    pub fn get_root(&mut self) -> &ContainerNode {
        return &self.root;
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
            if current.id == parent_id {
                match current.node_type {
                    NodeType::Window => {
                        // If it's a Window, convert it to a Split
                        if let Some(split_direction) = direction {
                            // Convert the current node into a split node
                            let split_node = ContainerNode::new_split(
                                current.id,
                                current.parent_id,
                                split_direction,
                            );

                            self.next_id += 1;

                            // println!("split node {:?}", split_node);

                            let new_window =
                                ContainerNode::new_window(self.next_id, Some(current.id), attrs);

                            // println!("new window: {:?}", new_window);

                            // Move the current node's data into a new child node
                            self.next_id += 1;

                            let mut new_child = ContainerNode::new_window(
                                self.next_id,
                                Some(current.id),
                                current.attrs.clone().as_ref(),
                            );
                            // println!("new child {:?}", new_child);

                            // std::mem::swap(current, &mut new_child);
                            // new_child.attrs = current.attrs.clone();
                            new_child.children = current.children.clone();

                            // println!("swampeed {:?}", new_child);

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

                        current.add_child(ContainerNode::new_window(
                            self.next_id,
                            Some(current.id),
                            attrs,
                        ));
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

    pub fn remove_window(&mut self, window_id: usize) -> Result<(), &'static str> {
        if self.root.id == window_id {
            return Err("Cannot remove the root node");
        }

        let mut stack = vec![&mut self.root];
        while let Some(current) = stack.pop() {
            for i in 0..current.children.len() {
                if current.children[i].id == window_id {
                    let _removed_node = current.children.remove(i);

                    // If the parent is a split and has only one child left, collapse the split
                    if let NodeType::Split(_) = current.node_type {
                        if current.children.len() == 1 {
                            // Replace the split with its remaining child
                            let remaining_child = current.children.remove(0);
                            *current = *remaining_child;
                        }
                    }

                    return Ok(());
                }
            }

            // Add children to the stack for further traversal
            for child in &mut current.children {
                stack.push(child);
            }
        }

        Err("Window ID not found")
    }
}
