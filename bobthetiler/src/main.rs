pub mod tiler;

fn main() {
    println!("Hello, world!");

    let mut container = tiler::LayoutTree::new();

    let parent_id = container.get_id();
    let next_id = container
        .add_window(parent_id, tiler::SplitDirection::Horizontal, None)
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
