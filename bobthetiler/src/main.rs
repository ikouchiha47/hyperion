use std::ffi::CString;
pub mod tiler;

fn main() {
    println!("Hello, world!");

    let name = CString::new("New Tab").expect("should be const star");
    println!("horizontal {:p}", name.as_ptr());

    let damn = tiler::Metadata::new(name.as_ptr(), 1, None, None, None, None);

    let mut container = tiler::LayoutTree::new(&damn);

    let name = CString::new("Horizontal Tab").expect("should be const star");
    println!("horizontal {:p}", name.as_ptr());

    let horizontal_damn = tiler::Metadata::new(name.as_ptr(), 1, None, None, None, None);
    let parent_id = container.get_id();
    let next_id = container
        .add_window(
            parent_id,
            tiler::SplitDirection::Horizontal,
            Some(&horizontal_damn),
        )
        .unwrap();

    let _ = container
        .add_window(next_id, tiler::SplitDirection::Vertical, None)
        .unwrap();

    let _ = container
        .add_window(parent_id, tiler::SplitDirection::Horizontal, None)
        .unwrap();

    println!("{:#?}", container);
}

/*
*
LayoutTree {
    root: ContainerNode {
        id: 1,
        node_type: Split(
            Horizontal,
        ),
        children: [
            ContainerNode {
                id: 1,
                node_type: Window,
                children: [],
            },
            ContainerNode {
                id: 2,
                node_type: Split(
                    Vertical,
                ),
                children: [
                    ContainerNode {
                        id: 2,
                        node_type: Window,
                        children: [],
                    },
                    ContainerNode {
                        id: 3,
                        node_type: Window,
                        children: [],
                    },
                ],
            },
            ContainerNode {
                id: 4,
                node_type: Window,
                children: [],
            },
        ],
    },
    next_id: 4,
}
* */
