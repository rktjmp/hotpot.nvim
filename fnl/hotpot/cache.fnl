(let []
  (var *tree nil)
  (var *current nil)

  (fn create []
    (set *tree {:__name "_tree_root__"})
    (set *current nil)
    (print "cache creation" *tree.__name *tree *current))

  (fn down [name]
    (print ">> cache down" name)
    (if (= *current nil)
      (set *current {:__parent *tree :__name name})
      (set *current {:__parent *current :__name name}))
    (tset *tree name *current)
    (print "update cache.*current" *current (vim.inspect *current) "tree" *tree)
    *current)

  (fn up []
    (print "<< cache up" *current.__name)
    (set *current *current.__parent)
    (print "update cache.*current" *current "tree" *tree)
    *current)

  (fn set_ [key val]
    (print "== cache set tree: " *tree)
    (print "== cache set" *current *current.__name key val)
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
   : create})
