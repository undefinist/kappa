package kappa.core;

#if !macro

/**
 * A view of components in the world.
 * Construct using `world.view(ComponentA + ComponentB - ComponentX - ComponentY)`.
 * 
 * e.g.  
 * Required = `{ a: ComponentA, b: ComponentB }`  
 * Excluded = `{ a: ComponentX, b: ComponentY }`
 */
@:genericBuild(kappa.core.View.ViewMacro.build())
class View<Required, Excluded>
{
}

#else

import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import haxe.macro.ExprTools;
import haxe.macro.Expr;
import kappa.macro.MacroTools;
using StringTools;

class ViewMacro
{
    public static function build():ComplexType
    {
        var filter = getFilter();
        var reqTypes = filter.required;
        var excTypes = filter.excluded;

        var className = "View"; // View_{req}___{exc}
        var inputFnArgs = [ { 
            name: "e",
            opt: false,
            t: Context.getType("kappa.core.Entity")
        } ];
        for(t in reqTypes)
        {
            var tname = TypeTools.toString(t).replace(".", "_");
            className += "_" + tname;
            inputFnArgs.push({ 
                name: tname,
                opt: false,
                t: t
            });
        }
        if(excTypes.length > 0) className += "__";
        for(t in excTypes)
            className += "_" + TypeTools.toString(t).replace(".", "_");

        try
        {
            return Context.toComplexType(Context.getType(className));
        }
        catch(e:String) 
        {
        }

        var inputFnType = Context.toComplexType(Type.TFun(inputFnArgs, ComplexTypeTools.toType(macro:Void)));
        var findFnType = Context.toComplexType(Type.TFun(inputFnArgs, ComplexTypeTools.toType(macro:Bool)));

        var required = [ for(t in reqTypes)
            kappa.macro.ComponentMacro.COMPONENT_NAMES.indexOf(MacroTools.getClassName(TypeTools.getClass(t))) ];
        var excluded = [ for(t in excTypes)
            kappa.macro.ComponentMacro.COMPONENT_NAMES.indexOf(MacroTools.getClassName(TypeTools.getClass(t))) ];

        var reqIndexExprs:Array<Expr> = [ for(i in 0...required.length) macro $v{i} ];
        var reqExprs:Array<Expr> = [ for(i in required) macro $v{i} ];
        
        // fn(entity, arr[0], arr[1], ..., arr[n - 1]);
        var fnCallArgs = ExprArrayTools.map(reqIndexExprs, (expr:Expr) -> return macro cast arr[$expr]);
        fnCallArgs.insert(0, macro _world._entities[e]); // e == entity index

        // if((arr[i] = _world._components[required[i]].get(entityindex)) == null) continue;
        var fillArgAndCheck = ExprArrayTools.map(reqExprs,
            (expr:Expr) -> return macro _world._components[$expr].get(e));
        for(i in 0...fillArgAndCheck.length)
            fillArgAndCheck[i] = macro if((arr[$v{i}] = ${fillArgAndCheck[i]}) == null) continue;

        // skip entities with excluded components
        for(i in excluded) fillArgAndCheck.push(macro if(_world._components[$v{i}].has(e)) continue);

        function generateIteration(innerExpr:Expr, ?endExpr:Expr):Expr
        {
            if(endExpr == null)
                endExpr = macro {};

            if(reqTypes.length > 0)
            {
                return macro
                {
                    var shortestPool = $v{required[0]};
                    for(i in $v{required})
                    {
                        if(_world._components[i].size < _world._components[shortestPool].size)
                            shortestPool = i;
                    }

                    var arr:Array<kappa.core.IComponent> = $v{ [ for(i in required) null ] };
                    for(e in _world._components[shortestPool].entities())
                    {
                        $b{fillArgAndCheck};
                        $innerExpr;
                    }

                    $endExpr;
                };
            }
            else
            {
                return macro
                {
                    for(e in 0..._world._entities.length)
                    {
                        if(_world._entities[e].index == e)
                        {
                            $b{fillArgAndCheck};
                            $innerExpr;
                        }
                    }

                    $endExpr;
                };
            }
        }
        
        var c = macro class $className
        {
            var _world:kappa.core.World;

            public function new(world:kappa.core.World)
            {
                _world = world;
            }

            /**
             * Iterates the view and calls function `f` for each entity.
             * It is provided with the entity itself and all the required components.
             */
            @:access(kappa.core.World)
            public function forEach(f:$inputFnType)
            {
                ${generateIteration(macro f($a{fnCallArgs}))}
            }

            /**
             * Iterates the view and returns the first entity for which predicate `pred` returns true.
             * It is provided with the entity itself and all the required components.
             * 
             * The function returns as soon as an entity is found.
             * 
             * If no entity is found, returns `Entity.INVALID`.
             */
            @:access(kappa.core.World)
            public function find(pred:$findFnType)
            {
                ${generateIteration(
                    macro if(pred($a{fnCallArgs})) return _world._entities[e],
                    macro return kappa.core.Entity.INVALID)}
            }
        };
        
        Context.defineType(c);
        return Context.toComplexType(Context.getType(className));
    }

    private static function getFilter():{ required:Array<Type>, excluded:Array<Type> }
    {
        var req:Array<Type> = [];
        var exc:Array<Type> = [];
        switch (Context.getLocalType())
        {
            case TInst(_, [t1, t2]):
                switch(t1)
                {
                    case TAnonymous(v):
                        for(f in v.get().fields)
                            req.push(f.type);
                    default:
                }
                switch(t2)
                {
                    case TAnonymous(v):
                        for(f in v.get().fields)
                            exc.push(f.type);
                    default:
                }
            default:
        }

        return { required: req, excluded: exc };
    }
}

#end