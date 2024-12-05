use crate::tiler::{CMetadata, LayoutTree, SplitDirection};
use std::ptr;

#[repr(C)]
pub struct AddWindowResult {
    pub success: bool,
    pub window_id: usize,
    pub error_message: *const i8,
}

#[no_mangle]
pub extern "C" fn layout_tree_new() -> *mut LayoutTree {
    Box::into_raw(Box::new(LayoutTree::new()))
}

#[no_mangle]
pub extern "C" fn layout_tree_free(tree: *mut LayoutTree) {
    if !tree.is_null() {
        let _ = unsafe { Box::from_raw(tree) };
    }
}

#[no_mangle]
pub extern "C" fn layout_tree_add_window(
    tree: *mut LayoutTree,
    parent_id: usize,
    direction: u32,
    metadata: *const CMetadata,
) -> AddWindowResult {
    if tree.is_null() {
        return AddWindowResult {
            success: false,
            window_id: 0,
            error_message: "LayoutTree is null\0".as_ptr() as *const i8,
        };
    }

    if metadata.is_null() {
        return AddWindowResult {
            success: false,
            window_id: 0,
            error_message: "Metadata is null\0".as_ptr() as *const i8,
        };
    }

    let metadata = unsafe { &*metadata };
    let metadata_rust = CMetadata::from_c(&metadata);

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

    match unsafe { (*tree).add_window(parent_id, direction, Some(&metadata_rust)) } {
        Ok(window_id) => AddWindowResult {
            success: true,
            window_id,
            error_message: ptr::null(),
        },
        Err(_) => AddWindowResult {
            success: false,
            window_id: 0,
            error_message: "Failed to add window\0".as_ptr() as *const i8,
        },
    }
}
