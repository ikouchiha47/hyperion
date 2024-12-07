package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"time"
)

type SplitDirection int

const (
	Horizontal SplitDirection = 1
	Vertical   SplitDirection = 2
)

type NodeType int

const (
	Window NodeType = 4 // Window
	Split  NodeType = 5 // Split
)

type Metadata struct {
	Name   string
	URL    string
	ID     int
	Width  int
	Height int
	Focus  bool
	Halted bool
}

//TODO: maybe check u16 is possible.

type ContainerNode struct {
	ID          int64
	ParentID    *int64
	NodeType    NodeType
	Orientation SplitDirection
	Attrs       *Metadata
	Children    []*ContainerNode
}

// NewWindow creates a new window node
func NewWindow(id int64, parentID *int64, attrs *Metadata) *ContainerNode {
	return &ContainerNode{
		ID:       id,
		ParentID: parentID,
		NodeType: Window,
		Attrs:    attrs,
		Children: nil,
	}
}

// NewSplit creates a new split node
func NewSplit(id int64, parentID *int64, direction SplitDirection) *ContainerNode {
	return &ContainerNode{
		ID:          id,
		ParentID:    parentID,
		NodeType:    Split,
		Orientation: direction,
		Attrs:       nil,
		Children:    nil,
	}
}

// AddChild adds a child node to a container
func (node *ContainerNode) AddChild(child *ContainerNode) {
	node.Children = append(node.Children, child)
}

func (node *ContainerNode) RemoveChild(windowID int64) (*ContainerNode, error) {
	for i, child := range node.Children {
		if child.ID == windowID {
			node.Children = append(node.Children[:i], node.Children[i+1:]...)
			return child, nil
		}
	}
	return nil, fmt.Errorf("window ID %d not found", windowID)
}

func (node *ContainerNode) Traverse() []*ContainerNode {
	var result []*ContainerNode
	var stack []*ContainerNode

	stack = append(stack, node)
	for len(stack) > 0 {
		current := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		result = append(result, current)

		for i := len(current.Children) - 1; i >= 0; i-- {
			stack = append(stack, current.Children[i])
		}
	}

	return result
}

type LayoutTree struct {
	Root   *ContainerNode
	PrevID int64
}

// NewLayoutTree creates a new layout tree with a root window node
func NewLayoutTree(attrs *Metadata) *LayoutTree {
	nId := time.Now().UTC().UnixNano() / int64(time.Millisecond)
	return &LayoutTree{
		Root:   NewWindow(nId, nil, attrs),
		PrevID: nId,
	}
}

// AddWindow adds a new window to the tree, creating a split if necessary
func (tree *LayoutTree) AddWindow(parentID int64, direction SplitDirection, attrs *Metadata) (int64, error) {
	stack := []*ContainerNode{tree.Root}

	for len(stack) > 0 {
		current := stack[len(stack)-1]
		stack = stack[:len(stack)-1]

		if current.ID == parentID {
			switch current.NodeType {
			case Window:
				tree.PrevID++
				newWindow := NewWindow(tree.PrevID, &current.ID, attrs)

				tree.PrevID++
				newChild := NewWindow(tree.PrevID, &current.ID, current.Attrs)

				splitNode := NewSplit(current.ID, current.ParentID, direction)
				splitNode.AddChild(newChild)
				splitNode.AddChild(newWindow)

				*current = *splitNode
				return newWindow.ID, nil

			case Split:
				tree.PrevID++
				newWindow := NewWindow(tree.PrevID, &current.ID, attrs)
				current.AddChild(newWindow)
				return newWindow.ID, nil
			}
		}

		stack = append(stack, current.Children...)
	}

	return 0, errors.New("parent node not found")
}

// UpdateAttrs finds the node with the given window ID using a stack and updates its attributes.
func (tree *LayoutTree) UpdateAttrs(windowID int64, updatedAttrs *Metadata) error {
	if tree.Root == nil {
		return fmt.Errorf("layout tree or root node is nil")
	}

	stack := []*ContainerNode{tree.Root}

	for len(stack) > 0 {
		currentNode := stack[len(stack)-1]
		stack = stack[:len(stack)-1]

		if currentNode.ID == windowID {
			currentNode.Attrs = updatedAttrs
			return nil
		}

		for _, child := range currentNode.Children {
			stack = append(stack, child)
		}
	}

	return fmt.Errorf("window ID %d not found in the tree", windowID)
}

func (tree *LayoutTree) Traverse() ([]*ContainerNode, error) {
	if tree.Root == nil {
		return nil, fmt.Errorf("empty root")
	}

	res := tree.Root.Traverse()
	return res, nil
}

func (tree *LayoutTree) RemoveWindow(windowID int64) error {
	if tree.Root.ID == windowID {
		return errors.New("cannot remove the root node")
	}

	stack := []*ContainerNode{tree.Root}

	for len(stack) > 0 {
		current := stack[len(stack)-1]
		stack = stack[:len(stack)-1]

		_, err := current.RemoveChild(windowID)
		if err == nil {
			if current.NodeType == Split && len(current.Children) == 1 {
				remainingChild := current.Children[0]
				*current = *remainingChild
			}
			return nil
		}

		stack = append(stack, current.Children...)
	}

	return fmt.Errorf("window ID %d not found", windowID)
}

func main() {
	tree := NewLayoutTree(&Metadata{
		Name: "Root Tab",
		ID:   1,
	})

	// tree.AddWindow(tree.PrevID, Horizontal, &Metadata{
	// 	Name: "Second Tab",
	// 	ID:   2,
	// })

	// tree.AddWindow

	b, err := json.MarshalIndent(tree, "", "")
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Println(string(b))
}
