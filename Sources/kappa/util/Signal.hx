package kappa.util;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;
using StringTools;

class SignalMacro
{
    public static function build():ComplexType
    {
        var tfun:ComplexType;
        var tparams:Array<Type> = [];
        var tdoc:String;

        switch(Context.getLocalType())
        {
            case TInst(cls, [ fun = TFun(params, _) ]):
                tdoc = cls.get().doc;
                tfun = Context.toComplexType(fun);
                for(a in params)
                    tparams.push(a.t);
            default:
        }

        var module = Context.getLocalModule();

        var name = "Signal";
        for(t in tparams)
            name += "_" + TypeTools.toString(t).replace(".", "_");
        if(tparams.length == 0)
            name += "_Void";

        try
        {
            return Context.toComplexType(Context.getType(name));
        }
        catch(e:String) 
        {
        }

        var pos = Context.currentPos();
        var callArgs:Array<Expr> = [ for(i in 0...tparams.length) macro $i{"_" + i} ];

        var c:TypeDefinition = {
            pack: [],
            name: name,
            kind: TDAbstract(macro:Array<$tfun>),
            fields: [
                {
                    name: "new",
                    access: [APublic, AInline],
                    kind: FFun({
                        args: [],
                        ret: null,
                        expr: macro this = []
                    }),
                    pos: pos
                },
                {
                    name: "fire",
                    access: [APrivate, AInline],
                    kind: FFun({
                        args: [ for(i in 0...tparams.length) { name: "_" + i, type: Context.toComplexType(tparams[i]) } ],
                        ret: null,
                        expr: macro for(f in this) if(f != null) f($a{callArgs})
                    }),
                    meta: [
                        {
                            name: ":allow",
                            pos: pos,
                            params: [ macro $p{module.split(".")} ]
                        }
                    ],
                    pos: pos
                },
                {
                    name: "listen",
                    access: [APublic, AInline],
                    kind: FFun({
                        args: [ { name: "listener", type: tfun } ],
                        ret: macro:kappa.util.Signal.SlotId,
                        expr: macro {
                            var i = 0;
                            for(x in this)
                            {
                                if(x == null)
                                    break;
                                ++i;
                            }
                            this.insert(i, listener);
                            return i;
                        }
                    }),
                    pos: pos
                },
                {
                    name: "unlisten",
                    access: [APublic, AInline],
                    kind: FFun({
                        args: [ { name: "slot", type: macro:Int } ],
                        ret: null,
                        expr: macro this[slot] = null
                    }),
                    pos: pos
                },
                {
                    name: "unlistenFn",
                    access: [APublic, AInline],
                    kind: FFun({
                        args: [ { name: "slot", type: macro:$tfun } ],
                        ret: null,
                        expr: macro this[this.indexOf(slot)] = null
                    }),
                    pos: pos
                }
            ],
            doc: tdoc,
            pos: pos
        };

        Context.defineType(c);
        return Context.toComplexType(Context.getType(name));
    }
}

#else

import haxe.Constraints.Function;

typedef SlotId = Int;

/**
 * Creates a signal of function type T, `(Args...)->Void` where `Args...` are the listener arguments.
 * `.fire` is automatically restricted to the calling module.
 */
@:genericBuild(kappa.util.Signal.SignalMacro.build())
class Signal<T:Function>
{
}

#end