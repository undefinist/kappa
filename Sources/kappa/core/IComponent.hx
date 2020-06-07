package kappa.core;

/**
 * Building blocks in the ECS.  
 * Components must have arg-less constructors or no constructors at all. (They will be auto-added)  
 * You can also add an init function in the form:  
 * `public function init(args...)`  
 * `init` gets called when a component is added or recycled.  
 * Then, to add the component to an entity, just call:
 * `world.add(e, ThisComponent, args...)`
 */
#if !macro
@:autoBuild(kappa.macro.ComponentMacro.build())
#end
@:keepSub
interface IComponent
{
}