local pglj_hook = {}

pglj_hook._DESCRIPTION = "LuaJIT FFI postgres hook"
pglj_hook._VERSION     = "pglj_hook 0.1"

local pgdef = {}

pgdef.elog = { 
	["LOG"] = 15,
	["INFO"] = 17,
	["NOTICE"] = 18,
	["WARNING"] = 19,
	["ERROR"] = 20,
	["FATAL"] = 21,
	["PANIC"] = 22
}

local ffi = require('ffi')

local NULL = ffi.new'void*'

ffi.cdef[[
extern bool errstart(int elevel, const char *filename, int lineno,
		 const char *funcname, const char *domain);
extern void errfinish(int dummy,...);
int	errmsg(const char *fmt,...);
]]

log = function(text)
  ffi.C.errstart(pgdef.elog["LOG"], "", 0, nil, nil)
  ffi.C.errfinish(ffi.C.errmsg(tostring(text)))
end

pgerror = function(text)
  ffi.C.errstart(pgdef.elog["ERROR"], "", 0, nil, nil)
  ffi.C.errfinish(ffi.C.errmsg(tostring(text)))
end

ffi.cdef[[
typedef uintptr_t Datum;

typedef void (*check_password_hook_type) (const char *username, const char *password, int password_type, Datum validuntil_time, bool validuntil_null);

check_password_hook_type check_password_hook;
]]

local check_password_old = ffi.C.check_password_hook
local check_password = function(username, password, password_type, validuntil_time, validuntil_null)
  if (#ffi.string(password) < 5) then
    pgerror('password is too short')
  end
  
end

check_password = ffi.cast("check_password_hook_type", check_password)


ffi.cdef[[
typedef struct Port Port;
typedef void (*ClientAuthentication_hook_type) (Port * port, int value);
ClientAuthentication_hook_type ClientAuthentication_hook;
]]
local ClientAuthentication_old = ffi.C.ClientAuthentication_hook

ffi.cdef[[int getpid(void);]]

local ClientAuthentication = function(port, value)
  log("ClientAuthentication hook test start for pid = "..tostring(ffi.C.getpid()))
  if (ClientAuthentication_old ~= NULL) then
    ClientAuthentication_old(port, value)
  end
  
  log("ClientAuthentication hook test end")
end
ClientAuthentication = ffi.cast("ClientAuthentication_hook_type", ClientAuthentication)


function pglj_hook._PG_init (...)
  ffi.C.check_password_hook = check_password
  ffi.C.ClientAuthentication_hook = ClientAuthentication
  log("pglj_hook init")
end

function pglj_hook._PG_fini (...)
  ffi.C.ClientAuthentication_hook = ClientAuthentication_old
  ffi.C.check_password_hook = check_password_old
  log("pglj_hook fini")
end


return pglj_hook