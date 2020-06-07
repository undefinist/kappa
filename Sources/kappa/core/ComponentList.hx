package kappa.core;

#if macro
import haxe.macro.Context;
import haxe.macro.TypeTools;
import haxe.macro.Expr;
#end

class ComponentList 
{
    macro public static function getNames():ExprOf<Array<String>>
    {
        Context.onGenerate(function (types) 
        {
            var compInterface = Context.getType("kappa.core.IComponent");
            var names = [];
            var self = TypeTools.getClass(Context.getType("kappa.core.ComponentList"));
            for (t in types)
            {
                if(Context.unify(t, compInterface))
                {
                    switch(t) 
                    {
                        case TInst(_.get() => c, _):
                            if (c.name != "IComponent")
                                names.push(Context.makeExpr(c.name, c.pos));
                        default:
                    }
                }
            }
            
            self.meta.remove('classes');
            self.meta.add('classes', names, self.pos);
        });
        
        return macro cast haxe.rtti.Meta.getType(kappa.core.ComponentList).classes;
    }
}