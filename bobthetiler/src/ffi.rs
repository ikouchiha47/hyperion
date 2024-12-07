use crate::tiler::{CContainerNode, CLayoutTree, CMetadata, SplitDirection};

#[repr(C)]
pub struct AddWindowResult {
    pub success: bool,
    pub window_id: usize,
    pub error_message: *const i8,
}

#[no_mangle]
pub extern "C" fn layout_tree_new(cmetadata: *const CMetadata) -> *mut CLayoutTree {
    if cmetadata.is_null() {
        return std::ptr::null_mut();
    }

    let layout_tree = CLayoutTree::new(cmetadata);

    if let Some(tree) = layout_tree {
        Box::into_raw(Box::new(tree))
    } else {
        std::ptr::null_mut()
    }
}

#[no_mangle]
pub extern "C" fn layout_tree_free(tree: *mut CLayoutTree) {
    if !tree.is_null() {
        CLayoutTree::free(tree);
    }
}

#[no_mangle]
pub extern "C" fn layout_tree_add_window(
    tree: *mut CLayoutTree,
    parent_id: usize,
    direction: u32,
    cmetadata: *const CMetadata,
) -> AddWindowResult {
    if tree.is_null() {
        return AddWindowResult {
            success: false,
            window_id: 0,
            error_message: "LayoutTree is null\0".as_ptr() as *const i8,
        };
    }

    if cmetadata.is_null() {
        return AddWindowResult {
            success: false,
            window_id: 0,
            error_message: "Metadata is null\0".as_ptr() as *const i8,
        };
    }

    let direction = match direction {
        0 => SplitDirection::Horizontal,
        1 => SplitDirection::Vertical,
        _ => {
            return AddWindowResult {
                success: false,
                window_id: 0,
                error_message: "Invalid direction\0".as_ptr() as *const i8,
            };
        }
    };

    let c_layout_tree = unsafe { &mut *tree };
    let metadata = unsafe { CMetadata::from_c(&*cmetadata) };

    // Convert the CLayoutTree back into a Rust LayoutTree
    let mut layout_tree = match CLayoutTree::from_c(c_layout_tree) {
        Some(tree) => tree,
        None => {
            return AddWindowResult {
                success: false,
                window_id: 0,
                error_message: "Failed to reconstruct LayoutTree\0".as_ptr() as *const i8,
            };
        }
    };

    match layout_tree.add_window(parent_id, direction, Some(&metadata)) {
        Ok(window_id) => {
            let updated_root =
                Box::into_raw(Box::new(CContainerNode::to_c(&layout_tree.get_root())));

            c_layout_tree.set_root(updated_root);
            c_layout_tree.set_next_id(layout_tree.get_id());

            AddWindowResult {
                success: true,
                window_id,
                error_message: std::ptr::null(),
            }
        }
        Err(e) => AddWindowResult {
            success: false,
            window_id: 0,
            error_message: e.as_ptr() as *const i8,
        },
    }
}

#[no_mangle]
pub extern "C" fn layout_tree_remove_window(tree: *mut CLayoutTree, window_id: usize) -> bool {
    if tree.is_null() {
        return false;
    }

    let c_layout_tree = unsafe { &mut *tree };

    // Convert the CLayoutTree back into a Rust LayoutTree
    let mut layout_tree = match CLayoutTree::from_c(c_layout_tree) {
        Some(tree) => tree,
        None => return false,
    };

    if layout_tree.remove_window(window_id).is_ok() {
        // Update the root node in the CLayoutTree after removing a window
        let updated_root = Box::into_raw(Box::new(CContainerNode::to_c(&layout_tree.get_root())));

        c_layout_tree.set_root(updated_root);
        c_layout_tree.set_next_id(layout_tree.get_id());

        true
    } else {
        false
    }
}
