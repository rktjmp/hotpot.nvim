local t = require("my_file")

-- actually check value cause exit(nil) probaby == 0
if t.value == 10 then
  os.exit(0)
else
  os.exit(1)
end
