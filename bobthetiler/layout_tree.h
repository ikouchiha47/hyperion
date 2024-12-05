#ifndef LAYOUT_TREE_H
#define LAYOUT_TREE_H

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct LayoutTree LayoutTree;

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

typedef struct AddWindowResult {
  bool success;
  uintptr_t window_id;
  const int8_t *error_message;
} AddWindowResult;

struct LayoutTree *layout_tree_new(const struct CMetadata *cmetadata);

void layout_tree_free(struct LayoutTree *tree);

struct AddWindowResult layout_tree_add_window(struct LayoutTree *tree,
                                              uintptr_t parent_id,
                                              uint32_t direction,
                                              const struct CMetadata *metadata);

#endif  /* LAYOUT_TREE_H */
