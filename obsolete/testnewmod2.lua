local mod = dofile('./testmod.lua')

local old_fun1 = mod.fun1
function mod.fun1(i)
    old_fun1(i)
    print(tostring(mod), 'new mod fun1: i=', i, 'a=', mod.a)
    print(tostring(old_fun1), 'vs', tostring(mod.fun1))
end

local old_fun4 =mod.fun4
function mod:fun4(i)
    old_fun4(self, i)
    print(tostring(self), 'new mod fun4: i^4=', i^4, 'a=',self.a)
    print(tostring(old_fun4), 'vs', tostring(mod.fun4))
end

i=3
print('i=',i)
mod.do_all(i)

return mod
