package kappa.core;

/**
 * Building blocks in the ECS.  
 * Components must have arg-less constructors or no constructors at all. (They will be auto-added)
 * 
 * **Default Init**  
 * All initialized fields are initialized in an auto-generated private function `__defaultInit(args...)`.
 * See example below.
 * 
 * **Init**  
 * You can also add an init function in the form: `public function init(args...)`  
 * `init` gets called when a component is added or recycled.  
 * If no `init` is defined, it will be auto-generated to call `__defaultInit`.
 * 
 * **@:initArg**  
 * You can also mark fields to be included as optional args in `init` and `__defaultInit` using the meta tag `@:initArg`.
 * If the arg is null, then it will be default initialized to your expr.
 * 
 * This means you can write a _pure_ component where you only define fields and default values.
 * 
 * **@:require**  
 * You can also add component dependencies using `@:require(<Components...>)` on the class.
 * When the component is added, it's dependencies are auto-added if not added yet.
 * 
 * **Example**  
 * ```
 * @:require(kappa.Transform)
 * class Foo implements IComponent
 * {
 *     @:initArg public var x = 5;
 *     public var y = 4.2;
 * 
 *     // the following are auto-generated
 *     public function new() {}
 *     inline private function __defaultInit(?_x:Int)
 *     {
 *         x = _x == null ? 5 : _x;
 *         y = 4.2;
 *     }
 *     public function init(?_x:Int)
 *     {
 *         __defaultInit(_x);
 *     }
 * }
 * ```
 * 
 * **Adding components**  
 * To add a component to an entity, just call:  
 * `world.add(e, ThisComponent, args...)` where `args...` are the arguments for `init`.
 */
#if !macro
@:autoBuild(kappa.macro.ComponentMacro.build())
#end
@:keepSub
interface IComponent
{
    public var __type(get, never):ComponentType;
}