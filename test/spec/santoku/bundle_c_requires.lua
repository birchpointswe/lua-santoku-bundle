local test = require("santoku.test")
local bundle = require("santoku.bundle")
local err = require("santoku.error")
local arr = require("santoku.array")
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
  local stderr, status = {}, nil
  for ev, _, a, b in sys.pread({ build("without"), stderr = true }) do
    if ev == "stderr" then
      arr.push(stderr, a)
    elseif ev == "exit" then
      status = b
    end
  end
  local msg = arr.concat(stderr)
  err.assert(status ~= 0, "the bundle without a.requires must fail at runtime")
  err.assert(str.find(msg, "no field package.preload['fx.b']", 1, true), msg)

  sys.execute({ "rm", "-rf", out })

end)
