local t = require("my-file")

-- actually check value cause exit(nil) probaby == 0
if t.value == 0 then
  os.exit(0)
else
  os.exit(1)
end
