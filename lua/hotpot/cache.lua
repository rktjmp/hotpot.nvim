 local __tree = {__name = "__tree_root__"}
 local __current = __tree

 print("cache creation", __tree.__name, __tree, __current, __current.__name)

 local function down(name)
 print("cache down", name)
 __current = {__name = name, __parent = __current}
 print("update cache.__current", __current)
 __tree[name] = __current
 return __current end

 local function up()
 print("cache up", __current.__name)
 __current = __current.__parent
 print("update cache.__current", __current)
 return __current end

 local function set_(key, val)
 print("cache set", __current.__name, key, val)
 __current[key] = val
 return __current end

 local function whole_graph()
 return __tree end

 local function current_graph()
 return __current end

 return {["current-graph"] = current_graph, ["whole-graph"] = whole_graph, down = down, set = set_, up = up}
