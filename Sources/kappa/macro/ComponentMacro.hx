package kappa.macro;

#if macro
import kappa.core.ComponentType;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;
#end

@:dce
class ComponentMacro
{
    #if macro
    public static var COMPONENT_NAMES(default, never):Array<String> = [];

    public static function getType(c:ExprOf<Class<kappa.core.IComponent>>):ComponentType
    {
        var ctype = TypeTools.getClass(Context.getType(ExprTools.toString(c)));
        var cname = MacroTools.getClassName(ctype);

        return cast COMPONENT_NAMES.indexOf(cname);
    }
    #end

    public static macro function build():Array<Field>
    {
        var fields = Context.getBuildFields();
        var ctor:Field = null;
        var init:Field = null;

        for(f in fields)
        {
            if(f.name == "new")
            {
                switch(f.kind)
                {
                    case FFun(f):
                        if(f.args.length > 0)
                        {
                            Context.fatalError("Components require constructor to be arg-less.", Context.currentPos());
                            return fields;
                        }
                    default:
                        Context.fatalError("unknown", Context.currentPos());
                        return fields;
                }
                ctor = f;
            }
            else if(f.name == "init")
            {
                init = f;
            }
        }

        // public function new() {  super(); // if required  }
        if(ctor == null)
        {
            var ctorFun:Function = { 
                expr: Context.getLocalClass().get().superClass == null ? macro {} : macro super(), 
                ret: null, 
                args: [] 
            };
            fields.push({ 
                name: "new", 
                access: [Access.APublic],
                kind: FieldType.FFun(ctorFun),
                pos: Context.currentPos()
            });
        }

        // public function init() {}
        if(init == null)
        {
            var initFun:Function = { 
                expr: macro {}, 
                ret: null, 
                args: [] 
            };
            fields.push({ 
                name: "init", 
                access: [Access.APublic],
                kind: FieldType.FFun(initFun),
                pos: Context.currentPos()
            });
        }

        var cname = MacroTools.getClassName(Context.getLocalClass().get());
        var index = COMPONENT_NAMES.push(cname) - 1;

        return fields;
    }
}