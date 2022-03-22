local mod = dofile('./testmod.lua')
local newmod = setmetatable({}, {__index=mod})

function newmod.fun1(i)
    print(tostring(mod), 'new mod fun1: i=', i, 'a=', mod.a)
end


function newmod:fun4(i)
    print(tostring(self), 'new mod fun4: i^4=', i^4, 'a=',self.a)
    print(tostring(self), 'new mod call fun1 in fun4:')
    self.fun1(i)
    print(tostring(self), 'new mod call fun2 in fun4:')
    self.fun2(i)
    print(tostring(self), 'new mod call fun3 in fun4:')
    self:fun3(i)
end

i=5
print('i=',i)
newmod.do_all(i)

print('---')
newmod:fun4(i)

return newmod
