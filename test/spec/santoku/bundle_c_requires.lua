local test = require("santoku.test")
local bundle = require("santoku.bundle")
local err = require("santoku.error")
local sys = require("santoku.system")
local str = require("santoku.string")
local env = require("santoku.env")
local fs = require("santoku.fs")

test("a C module's .requires sidecar pulls its runtime requires into the bundle", function ()

  local res = fs.absolute("test/res/c-requires")
  local out = fs.join(res, "build")
  local lib = fs.join(out, "lib")
  local fx = fs.join(lib, "fx")

  sys.execute({ "rm", "-rf", out })
  fs.mkdirp(fx)

  local cc = env.var("CC", "cc")
  local incdir = sys.sh({ "luarocks", "config", "variables.LUA_INCDIR" })()
  local libdir = sys.sh({ "luarocks", "config", "variables.LUA_LIBDIR" })()
  local libfile = sys.sh({ "luarocks", "config", "variables.LUA_LIBDIR_FILE" })()
  local libname = str.stripprefix(fs.stripextension(libfile), "lib")

  for _, m in ipairs({ "a", "b" }) do
    sys.execute({ cc, "-c", "-fPIC", "-I", incdir,
      fs.join(res, "fx", m .. ".c"), "-o", fs.join(fx, m .. ".o") })
    fs.writefile(fs.join(fx, m .. ".link"), m .. ".o\n")
    fs.writefile(fs.join(fx, m .. ".so"), "")
  end

  local function build (name)
    bundle(fs.join(res, "main.lua"), fs.join(out, name), {
      path = fs.join(lib, "?.lua"),
      cpath = fs.join(lib, "?.so"),
      flags = { "-I", incdir, "-L", libdir, "-l", libname, "-l", "m" },
    })
    return fs.join(out, name, "main")
  end

  fs.writefile(fs.join(fx, "a.requires"), "fx.b\n")
  err.assert(sys.sh({ build("with") })() == "from b")

  fs.rm(fs.join(fx, "a.requires"))
  err.assert(not err.pcall(function ()
    return sys.sh({ build("without") })()
  end))

  sys.execute({ "rm", "-rf", out })

end)
