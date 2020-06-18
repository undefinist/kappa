package kappa.macro;

#if macro
import kappa.core.ComponentType;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;
using Lambda;
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
        var pos = Context.currentPos();

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
                            Context.fatalError("Components require constructor to be arg-less.", pos);
                            return fields;
                        }
                    default:
                        Context.fatalError("unknown", pos);
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
                kind: FFun(ctorFun),
                pos: pos
            });
        }

        { // public function __defaultInit() { <fields_to_init> }
            var fieldsToInit:Array<Field> = [];
            for(f in fields)
            {
                switch(f.kind)
                {
                    case FVar(_, e) | FProp(_, _, _, e):
                        if(e != null)
                            fieldsToInit.push(f);
                    default:
                }
            }
            var initExprs = [ for(f in fieldsToInit) switch(f.kind) {
                case FVar(_, e) | FProp(_, _, _, e):
                    f.meta.exists(item -> item.name == ":initArg") ?
                        macro $i{f.name} = $i{"_" + f.name} == null ? $e : $i{"_" + f.name} :
                        macro $i{f.name} = $e;
                default:
                    null;
            } ];
            var initArgs:Array<FunctionArg> = [];
            for(f in fieldsToInit)
            {
                if(f.meta.exists(item -> item.name == ":initArg"))
                {
                    initArgs.push(switch(f.kind) {
                        case FVar(t, e) | FProp(_, _, t, e):
                            { name: "_" + f.name, type: t, opt: true };
                        default:
                            null;
                    });
                }
            }

            var defaultInitFun:Function = { 
                expr: macro $b{initExprs}, 
                ret: null, 
                args: initArgs
            };
            fields.push({ 
                name: "__defaultInit", 
                access: [Access.APrivate, Access.AInline],
                kind: FFun(defaultInitFun),
                doc: "_(Auto-generated)_\n```\n" + [ for(e in initExprs) ExprTools.toString(e) ].join(";\n") + ";\n```",
                pos: pos
            });
        }

        // public function init() { __defaultInit(); }
        if(init == null)
        {
            var initFun:Function = { 
                expr: macro __defaultInit($a{switch(fields[fields.length - 1].kind) {
                    case FFun(f): [ for(arg in f.args) macro $i{arg.name} ];
                    default: [];
                }}), 
                ret: null, 
                args: switch(fields[fields.length - 1].kind) {
                    case FFun(f): f.args;
                    default: [];
                }
            };
            fields.push({ 
                name: "init", 
                access: [Access.APublic],
                kind: FFun(initFun),
                doc: fields[fields.length - 1].doc,
                pos: pos
            });
        }

        var klass = Context.getLocalClass().get();
        var cname = MacroTools.getClassName(klass);
        var index = COMPONENT_NAMES.push(cname) - 1;

        if(klass.superClass == null)
        {
            fields.push({
                name: "__type",
                access: [Access.APublic],
                kind: FProp("get", "never", macro:kappa.core.ComponentType),
                pos: pos
            });
        }
        fields.push({
            name: "get___type",
            access: klass.superClass == null ? [ Access.AInline ] : [Access.AInline, Access.AOverride],
            kind: FFun({
                expr: macro return $v{index},
                ret: macro:kappa.core.ComponentType,
                args: []
            }),
            pos: pos
        });

        trace(cname, index);

        return fields;
    }
}