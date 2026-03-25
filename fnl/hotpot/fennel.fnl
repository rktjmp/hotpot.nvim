(let [fennel (require :hotpot.vendor.fennel)
      {: path : macro-path} fennel]
  ;; Fennels default paths dont include "fnl/" directories which are pretty
  ;; core to us so insert them. Note we do not insert any "normal vim rtp"
  ;; paths, as generally we just need to fix where macros can be found and
  ;; users should but them in `fnl/...`;
  (set fennel.path
       (.. (table.concat [:./fnl/?.fnl :./fnl/?/init.fnl] ";")
           fennel.path))
  (set fennel.macro-path
       (.. (table.concat [:./fnl/?.fnlm
                          :./fnl/?/init.fnlm
                          :./fnl/?.fnl
                          :./fnl/?/init-macros.fnl
                          :./fnl/?/init.fnl]
                         ";")
           fennel.macro-path))
  (values fennel))
