#ifndef LAYOUT_TREE_H
#define LAYOUT_TREE_H

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct CMetadata {
  const int8_t *name;
  uintptr_t id;
  uintptr_t x;
  uintptr_t y;
  uintptr_t width;
  uintptr_t height;
  bool focus;
  bool halted;
} CMetadata;

typedef struct CContainerNode {
  uintptr_t id;
  uintptr_t parent_id;
  uintptr_t node_type;
  const struct CMetadata *attrs;
  struct CContainerNode *child;
  struct CContainerNode *next;
} CContainerNode;

typedef struct CLayoutTree {
  const struct CContainerNode *root;
  uintptr_t next_id;
} CLayoutTree;

typedef struct AddWindowResult {
  bool success;
  uintptr_t window_id;
  const int8_t *error_message;
} AddWindowResult;

struct CLayoutTree *layout_tree_new(const struct CMetadata *cmetadata);

void layout_tree_free(struct CLayoutTree *tree);

struct AddWindowResult layout_tree_add_window(struct CLayoutTree *tree,
                                              uintptr_t parent_id,
                                              uint32_t direction,
                                              const struct CMetadata *cmetadata);

bool layout_tree_remove_window(struct CLayoutTree *tree, uintptr_t window_id);

#endif  /* LAYOUT_TREE_H */
