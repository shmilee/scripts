local mod = {
    a = 8,
    show = function(self, i)
        print('show: a=', self.a, 'and i=', i)
    end,
}

function mod.fun1(i)
    print(tostring(mod), 'mod fun1: i=', i, 'a=', mod.a)
end

function mod.fun2(i)
    print(tostring(mod), 'mod fun2: i^2=', i^2)
end

function mod:fun3(i)
    print(tostring(self), 'mod fun3: i^3=', i^3)
end

function mod:fun4(i)
    print(tostring(self), 'mod fun4: i^4=', i^4)
end

function mod.do_all(i)
    mod.fun1(i)
    mod.fun2(i)
    mod:fun3(i)
    mod:fun4(i)
end

mod:show(999)

return mod
