package kappa.core;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;
import haxe.macro.Type.ClassType;
import kappa.macro.ComponentMacro;
#else
import kha.Scheduler;
import kappa.core.IComponent;
import kappa.core.ComponentPool;
import kappa.core.Entity;
import kappa.core.System;
import kappa.util.Signal;
#end

class World 
{
    #if !macro
    
    /**
     * List of all entities, whether dead or alive.
     * When an entity is destroyed, the version is bumped by 1,
     * and the index part forms a linked-list of destroyed entities starting at `destroyed_head_`.
     * An entity is alive when it's index part == index in the array.
     */
    private var _entities:Array<Entity>;
    private var _destroyedHead:Entity;
    private var _to_destroy:Array<Entity>;

    private var _components:Array<ComponentPool>;
    private var _systems:Array<System>;

    private var _lastTime:Float;
    private var _updatePasses:Array<(dt:Float)->Void>;
    private var _renderPasses:Array<(g:kha.graphics4.Graphics)->Void>;

    /**
     * Signal that fires when a component is added to an entity. Called after component's `.init`.
     */
    public var onComponentAdded(default, null):Signal<Entity->IComponent->Void>;
    
    /**
     * Signal that fires when a component is removed.
     */
    public var onComponentRemoved(default, null):Signal<Entity->IComponent->Void>;

    public function new() 
    {
        _entities = [];
        _destroyedHead = Entity.INVALID;
        _to_destroy = [];
        
        var a:Array<String> = ComponentList.getNames();
        _components = [];
        for(i in a) 
            _components.push(new ComponentPool());

        _systems = [];

        _lastTime = 0;
        _updatePasses = [];
        _renderPasses = [];

        onComponentAdded = new Signal<Entity->IComponent->Void>();
        onComponentRemoved = new Signal<Entity->IComponent->Void>();
    }

    public function init()
    {
        for(s in _systems)
            s.init();
    }

    public function lateInit()
    {
        for(s in _systems)
            s.lateInit();
    }

    public function update()
    {
        var currTime = Scheduler.time();
        var dt = currTime - _lastTime;
        for(pass in _updatePasses)
            pass(dt);
        clearDestructionQueue();
        _lastTime = currTime;
    }

    public function render(g:kha.graphics4.Graphics)
    {
        for(pass in _renderPasses)
            pass(g);
    }

    public function scheduleUpdate(pass:(dt:Float)->Void)
    {
        _updatePasses.push(pass);
    }

    public function scheduleRender(pass:(g:kha.graphics4.Graphics)->Void)
    {
        _renderPasses.push(pass);
    }

    /**
     * Creates a new entity.
     * @return Entity
     */
    public function create():Entity
    {
        if(_destroyedHead.valid) // recycle destroyed, pop linked list
        {
            var head = _destroyedHead;
            _destroyedHead = _entities[_destroyedHead].index;
            _entities[head].index = head;
            return _entities[head];
        }
        else 
        {
            _entities.push(Entity.make(_entities.length, 0));
            return _entities[_entities.length - 1];
        }
    }

    /**
     * Destroys the given entity **immediately**. For most cases, use `queueDestroy` instead.
     * @param e The entity to destroy.
     */
    public function destroy(e:Entity)
    {
        for(pool in _components)
        {
            if(pool.has(e.index))
            {
                var c = pool.get(e.index);
                pool.remove(e.index);
                onComponentRemoved.fire(e, c);
            }
        }

        // bump version and extend destroyed linked list
        _entities[e.index] = Entity.make(_destroyedHead, _entities[e.index].version + 1);
        _destroyedHead = e.index;
    }

    /**
     * Queues an entity for destruction. The destruction queue is cleared at the end of the frame.
     * You can also call or schedule `clearDestructionQueue` manually.
     * @param e The entity to queue for destruction.
     */
    public function queueDestroy(e:Entity)
    {
        _to_destroy.push(e);
    }

    /**
     * Destroys all the entities queued for destruction.
     * This is called at the end of the frame.
     * You can also call/schedule it manually.
     */
    public function clearDestructionQueue()
    {
        for(e in _to_destroy)
            destroy(e);
        _to_destroy.resize(0);
    }
    
    /**
     * Checks whether given entity is currently alive or not.
     * If it is _queued_ for destruction, it is still alive.
     */
    inline public function isAlive(e:Entity):Bool
    {
        return _entities[e.index] == e.index;
    }

    public function addSystem<T:System>(sys:T):T
    {
        _systems.push(sys);
        sys._world = this;
        return sys;
    }

    public function findSystem<T:System>(systemClass:Class<T>):T
    {
        for(sys in _systems)
        {
            if(Std.is(sys, systemClass))
                return cast sys;
        }
        return null;
    }

    @:noCompletion @:noDoc @:generic // internal, does not call init or callbacks.
    public function __addOfType<T:haxe.Constraints.Constructible<Void->Void> & IComponent>(e:Entity, ctype:ComponentType, _:Class<T>):T
    {
        var ret:T = cast _components[ctype].recycle(e.index);
        if(ret == null)
            ret = _components[ctype].add(e.index, new T());
        return ret;
    }

    @:noCompletion @:noDoc // internal
    public function __addOfTypeSignalFire(e:Entity, c:IComponent)
    {
        onComponentAdded.fire(e, c);
    }

    @:noCompletion @:noDoc // internal
    public function __removeOfType(e:Entity, ctype:ComponentType)
    {
        onComponentRemoved.fire(e, _components[ctype].remove(e.index));
    }

    @:noCompletion @:noDoc // internal
    inline public function __getOfType(e:Entity, ctype:ComponentType):IComponent
    {
        return _components[ctype].get(e.index);
    }

    @:noCompletion @:noDoc // internal
    inline public function __hasOfType(e:Entity, ctype:ComponentType):Bool
    {
        return _components[ctype].has(e.index);
    }

    #end // #if !macro

    #if macro 

    private static function buildDependencies(klass:ClassType, deps:Array<Expr>)
    {
        if(klass.meta.has(":require"))
        {
            for(m in klass.meta.extract(":require"))
            {
                for(p in m.params)
                {
                    var type = Context.getType(ExprTools.toString(p));
                    buildDependencies(TypeTools.getClass(type), deps);
                    deps.push(p);
                }
            }
        }
    }

    #end
    
    /**
     * Add a component to entity `e`. The component must have an arg-less constructor.  
     * If the given component has component dependencies via `@:require(<Components...>)`, adds the dependencies FIRST if needed.
     * Usage: `world.add(e, Component, <init-fn args...>)`
     * @param e The entity
     * @param cls The component class
     * @param args Args for the component's init function
     */
    public macro function add<T:IComponent>(world:ExprOf<World>, e:ExprOf<Entity>, cls:ExprOf<Class<T>>, args:Array<Expr>):ExprOf<T>
    {
        var type = Context.getType(ExprTools.toString(cls));
        var ctype = Context.toComplexType(type);
        var klass = TypeTools.getClass(type);
        if(!TypeTools.unify(type, Context.getType("kappa.core.IComponent")))
            Context.fatalError("World#add argument 2 must be a IComponent class", cls.pos);
        switch(klass.constructor.get().type)
        {
            case TLazy(f):
                switch(f())
                {
                    case TFun(args, _):
                        if(args.length != 0)
                            Context.fatalError("World#add IComponent needs arg-less constructor!", cls.pos);
                    default:
                        throw "unreachable";
                }
            case TFun(args, _):
                if(args.length != 0)
                    Context.fatalError("World#add IComponent needs arg-less constructor!", cls.pos);
            default:
                throw "unreachable";
        }
        
        var deps:Array<Expr> = [];
        buildDependencies(klass, deps);
        
        // remove duplicate deps
        for(i in 0...deps.length - 1)
        {
            for(j in i + 1...deps.length)
            {
                if(deps[i].expr.equals(deps[j].expr))
                    deps[j] = null;
            }
        }
        deps = deps.filter(expr -> expr != null);

        var addDepsExprs:Array<Expr> = [];
        for(expr in deps)
        {
            var ctype = Context.toComplexType(Context.getType(ExprTools.toString(expr)));
            var id = kappa.macro.ComponentMacro.getType(expr);
            addDepsExprs.push(macro
            {
                if(!$world.__hasOfType($e, $v{id}))
                {
                    var comp = ((cast $world.__addOfType($e, $v{id}, $expr)) : $ctype);
                    comp.init();
                    $world.__addOfTypeSignalFire($e, comp);
                }
            });
        }

        // enforce code hinting using (expr : type) check
        return macro
        { ( {
            $b{ addDepsExprs };
            var comp = ((cast $world.__addOfType($e, $v{kappa.macro.ComponentMacro.getType(cls)}, $cls)) : $ctype);
            comp.init($a{args});
            $world.__addOfTypeSignalFire($e, comp);
            comp; // return value of block
        } : $ctype); };
    }

    /**
     * Remove a component from entity `e`.
     * Usage: `world.remove(e, Component)`
     * @param e The entity
     * @param cls The component class
     */
    public macro function remove<T:IComponent>(world:ExprOf<World>, e:ExprOf<Entity>, cls:ExprOf<Class<T>>):ExprOf<T>
    {
        var type = Context.getType(ExprTools.toString(cls));
        var ctype = Context.toComplexType(type);
        if(!TypeTools.unify(type, Context.getType("kappa.core.IComponent")))
            Context.fatalError("World#remove argument 2 must be a IComponent class", cls.pos);
        return macro $world.__removeOfType($e, $v{kappa.macro.ComponentMacro.getType(cls)});
    }

    /**
     * Gets a component in entity `e`.
     * Usage: `world.get(e, Component)`
     * @param e The entity
     * @param cls The component class
     * @return The component, or `null` if it doesn't exist.
     */
    public macro function get<T:IComponent>(world:ExprOf<World>, e:ExprOf<Entity>, cls:ExprOf<Class<T>>):ExprOf<T>
    {
        var type = Context.getType(ExprTools.toString(cls));
        var ctype = Context.toComplexType(type);
        if(!TypeTools.unify(type, Context.getType("kappa.core.IComponent")))
            Context.fatalError("World#get argument 2 must be a IComponent class", cls.pos);
        // enforce code hinting using : type check
        return macro ((cast $world.__getOfType($e, $v{kappa.macro.ComponentMacro.getType(cls)})) : $ctype);
    }

    #if macro
    private static function processFilterExpr(filter:ExprOf<Class<IComponent>>,
                                              required:Array<ExprOf<Class<IComponent>>>,
                                              excluded:Array<ExprOf<Class<IComponent>>>):Bool
    {
        switch(filter.expr)
        {
            case EBinop(op, e1, e2):
                if(op != OpSub && op != OpAdd)
                    Context.fatalError("view filter should be in the form ComponentA + ComponentB - ComponentX", filter.pos);
                if(processFilterExpr(e1, required, excluded))
                    required.push(e1);
                if(processFilterExpr(e2, required, excluded))
                    (op == OpSub ? excluded : required).push(e2);
                return false;
            case EUnop(op, postFix, e): // must be -Component
                if(postFix || op != OpNeg)
                    Context.fatalError("view filter should be in the form ComponentA + ComponentB - ComponentX", filter.pos);
                if(processFilterExpr(e, required, excluded))
                    excluded.push(e);
                return false;
            case EField(_, _):
                return true;
            case EConst(_):
                return true;
            default:
                Context.fatalError("view filter should be in the form ComponentA + ComponentB - ComponentX", filter.pos);
                return false;
        }
    }
    #end
    
    /**
     * Creates a view of components for iteration.  
     * Usage: `world.view(filter)` where `filter` is in the form A + B - C - D,
     * meaning all entities with components A and B, and without components C and D.
     */
    public macro function view(world:ExprOf<World>, ?filter:ExprOf<Class<IComponent>>):Expr
    {
        var required:Array<ExprOf<Class<IComponent>>> = [];
        var excluded:Array<ExprOf<Class<IComponent>>> = [];
        
        if(ExprTools.toString(filter) != "null") {
            if(processFilterExpr(filter, required, excluded)) // returns true if not binop or unop
                required.push(filter);
        }

        var fields:Array<Field> = [];
        var counter:Int = 0;
        for(e in required)
        {
            var t = Context.getType(ExprTools.toString(e));
            fields.push({ 
                name: "_" + String.fromCharCode("a".code + counter++),
                pos: Context.currentPos(), 
                kind: FVar(Context.toComplexType(t)) 
            });
        }
        var req:ComplexType = TAnonymous(fields);

        fields = [];
        counter = 0;
        for(e in excluded)
        {
            var t = Context.getType(ExprTools.toString(e));
            fields.push({ 
                name: "_" + String.fromCharCode("a".code + counter++),
                pos: Context.currentPos(), 
                kind: FVar(Context.toComplexType(t)) 
            });
        }
        var exc:ComplexType = TAnonymous(fields);

        return macro new kappa.core.View<$req, $exc>($world);
    }
}