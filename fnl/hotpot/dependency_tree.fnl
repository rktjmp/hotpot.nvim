;; NOTE: This is used in the macro loader, so you may not use any
;; macros in here, or probably any requires either to avoid
;; circular compile chains.

(var *tree nil)
(var *current nil)

(fn create []
  (set *tree {:__name "_tree_root__"})
  (set *current nil)
  ;; (dinfo "cache creation" *tree.__name *tree *current)
  *tree)

(fn down [name]
  ;; (dinfo ">> cache down" name)
  (if (= *current nil)
    (set *current {:__parent *tree :__name name})
    (set *current {:__parent *current :__name name}))
  (tset *tree name *current)
  ;;(dinfo "update cache.*current" *current (vim.inspect *current) "tree" *tree)
  *current)

(fn up []
  ;;(dinfo "<< cache up" *current.__name)
  (set *current *current.__parent)
  ;;(dinfo "update cache.*current" *current "tree" *tree)
  *current)

(fn set_ [key val]
  ;;  (dinfo "== cache set tree: " *tree)
  ;;  (dinfo "== cache set" *current *current.__name key val)
  (tset *current key val)
  *current)

(fn whole-graph []
  *tree)

(fn current-graph []
  *current)

(create)

{: down
 : up
 : whole-graph
 : current-graph
 :set set_
 : create}
