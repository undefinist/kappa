package kappa.core;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
#end

abstract ComponentType(Int) from Int to Int
{
    public static macro function fromClass(c:ExprOf<Class<IComponent>>):ExprOf<ComponentType>
    {
        return macro $v{kappa.macro.ComponentMacro.getType(c)};
    }

    inline function new(i:Int)
    {
        this = i;
    }
}