(fn call [ast scope ...]
  (match ast
    [[:+]] (table.insert ast 1))
  (values nil))

{:name :module-plugin
 :call call
 :versions [:1.2.1]}
