(local __tree {:__name "__tree_root__"})
(var __current __tree)

(print "cache creation" __tree.__name __tree __current __current.__name)

(fn down [name]
  (print "cache down" name)
  (set __current {:__parent __current :__name name})
  (print "update cache.__current" __current)
  (tset __tree name __current)
  __current)

(fn up []
  (print "cache up" __current.__name)
  (set __current __current.__parent)
  (print "update cache.__current" __current)
  __current)

(fn set_ [key val]
  (print "cache set" __current.__name key val)
  (tset __current key val)
  __current)

(fn whole-graph []
  __tree)

(fn current-graph []
  __current)

{: down
 : up
 : whole-graph
 : current-graph
 :set set_}
