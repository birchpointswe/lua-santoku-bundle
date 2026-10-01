-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2023 Birch Point SWE
local str = require("santoku.string")
local fsposix = require("santoku.fs.posix")

local ok, dir = fsposix.cwd()
str.split(dir, "/"):each(function ()

end)
