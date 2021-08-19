; Manages and exposes Hotpot options
; Mostly these should be "set" via hotpot.setup

; These options are only applied to hotpots toolchain, not anything
; under api.compile, etc etc.
(local default-options {:compiler {:modules {}
                                   :macros {:env :_COMPILER}}})
(var user-options {})

(fn path-to-list [path]
  ; turns "my.option" into [:my :option]
  (let [path (.. "." path)
        path (string.gsub path "_" "-")]
    (icollect [p (string.gmatch path "%.([%a%d-]+)")] p)))

(fn dig [path users defaults]
  ; given [:my :option :path], dig through options for a value
  ; we preference user options, but if they return nil, we try the defaults
  (let [[key & rest] path
        user (?. users key)
        default (?. defaults key)]
    (match [user default (length rest)]
      [nil nil _] nil ; nothing hit a value, give up
      [value _ 0] value ; user had option, no more path
      [_ value 0] value ; default had option, no more path
      [?next-users ?next-defaults _] (dig rest ?next-users ?next-defaults))))
  
(fn get-option [option-name]
  (local path (path-to-list option-name))
  (dig path user-options default-options))

(fn set-user-options [options]
  ; we just accept options "wholesale" for now, no "set by key path".
  (set user-options options))

{: set-user-options
 : get-option}
