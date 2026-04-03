# Advanced `vim.pack.add` Configuration

When adjusting `vim.pack.add`'s behaviour via its option table, particularly
the `load` option, you may or may not need to call `require("hotpot")`,
depending on the options given and whether you intend to call
`require("my-config")` afterwards.

Note that repeated calls to `require("hotpot")` are always a no-op so there is
no negative effect to keeping the `require` call.

| `{load = ?}` | call `require(hotpot)` | can `require("user")` at end of `init.lua` |
| --           | --                     | --                                         |
| `true`       | `false`                | ok                                         |
| `false`      | `false`                | fail                                       |
| `nil`        | `false`                | fail                                       |
| `true`       | `true`                 | ok                                         |
| `false`      | `true`                 | ok                                         |
| `nil`        | `true`                 | ok                                         |

Note that the above table does not include testing for `load = function`, where
it's entirely at the users discretion to call `packadd` or `packadd!` which has
similar effects to `load = true` and `load = false` respectively.

```
config:: load true require true
config:: init.lua,                               vim_did_init = 0, vim_did_enter = 0
hotpot:: plugin/hotpot.fnl,                      vim_did_init = 0, vim_did_enter = 0
hotpot:: fnl/hotpot.fnl,                         vim_did_init = 0, vim_did_enter = 0
hotpot::  fnl/hotpot.fnl exit
hotpot::  plugin/hotpot.fnl exit
config:: init.fnl require(hotpot)
config:: fnl/user/init.fnl,                      vim_did_init = 0, vim_did_enter = 0
config:: did require user
config:: config/plugin/hi.lua,                   vim_did_init = 1, vim_did_enter = 0
dummy :: nvim-plugin-dir-dummy/plugin/dummy.lua, vim_did_init = 1, vim_did_enter = 0
hotpot:: plugin/hotpot.fnl,                      vim_did_init = 1, vim_did_enter = 0
hotpot::  plugin/hotpot.fnl exit

config:: load true require false
config:: init.lua,                               vim_did_init = 0, vim_did_enter = 0
hotpot:: plugin/hotpot.fnl,                      vim_did_init = 0, vim_did_enter = 0
hotpot:: fnl/hotpot.fnl,                         vim_did_init = 0, vim_did_enter = 0
hotpot::  fnl/hotpot.fnl exit
hotpot::  plugin/hotpot.fnl exit
config:: fnl/user/init.fnl,                      vim_did_init = 0, vim_did_enter = 0
config:: did require user
config:: config/plugin/hi.lua,                   vim_did_init = 1, vim_did_enter = 0
dummy :: nvim-plugin-dir-dummy/plugin/dummy.lua, vim_did_init = 1, vim_did_enter = 0
hotpot:: plugin/hotpot.fnl,                      vim_did_init = 1, vim_did_enter = 0
hotpot::  plugin/hotpot.fnl exit

config:: load false require true
config:: init.lua,                               vim_did_init = 0, vim_did_enter = 0
config:: init.fnl require(hotpot)
hotpot:: fnl/hotpot.fnl,                         vim_did_init = 0, vim_did_enter = 0
hotpot::  fnl/hotpot.fnl exit
config:: fnl/user/init.fnl,                      vim_did_init = 0, vim_did_enter = 0
config:: did require user
config:: config/plugin/hi.lua,                   vim_did_init = 1, vim_did_enter = 0
dummy :: nvim-plugin-dir-dummy/plugin/dummy.lua, vim_did_init = 1, vim_did_enter = 0
hotpot:: plugin/hotpot.fnl,                      vim_did_init = 1, vim_did_enter = 0
hotpot::  plugin/hotpot.fnl exit

config:: load false require false
config:: init.lua,                               vim_did_init = 0, vim_did_enter = 0
config:: !!! could not require user
hotpot:: plugin/hotpot.fnl,                      vim_did_init = 1, vim_did_enter = 0
hotpot:: fnl/hotpot.fnl,                         vim_did_init = 1, vim_did_enter = 0
config:: config/plugin/hi.lua,                   vim_did_init = 1, vim_did_enter = 0
dummy :: nvim-plugin-dir-dummy/plugin/dummy.lua, vim_did_init = 1, vim_did_enter = 0
hotpot::  fnl/hotpot.fnl exit
hotpot::  plugin/hotpot.fnl exit

config:: load nil require true
config:: init.lua,                               vim_did_init = 0, vim_did_enter = 0
config:: init.fnl require(hotpot)
hotpot:: fnl/hotpot.fnl,                         vim_did_init = 0, vim_did_enter = 0
hotpot::  fnl/hotpot.fnl exit
config:: fnl/user/init.fnl,                      vim_did_init = 0, vim_did_enter = 0
config:: did require user
config:: config/plugin/hi.lua,                   vim_did_init = 1, vim_did_enter = 0
dummy :: nvim-plugin-dir-dummy/plugin/dummy.lua, vim_did_init = 1, vim_did_enter = 0
hotpot:: plugin/hotpot.fnl,                      vim_did_init = 1, vim_did_enter = 0
hotpot::  plugin/hotpot.fnl exit

config:: load nil require false
config:: init.lua,                               vim_did_init = 0, vim_did_enter = 0
config:: !!! could not require user
hotpot:: plugin/hotpot.fnl,                      vim_did_init = 1, vim_did_enter = 0
hotpot:: fnl/hotpot.fnl,                         vim_did_init = 1, vim_did_enter = 0
config:: config/plugin/hi.lua,                   vim_did_init = 1, vim_did_enter = 0
dummy :: nvim-plugin-dir-dummy/plugin/dummy.lua, vim_did_init = 1, vim_did_enter = 0
hotpot::  fnl/hotpot.fnl exit
hotpot::  plugin/hotpot.fnl exit
```

