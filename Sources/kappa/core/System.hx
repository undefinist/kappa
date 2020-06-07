package kappa.core;

import kappa.core.World;

class System
{
    @:allow(kappa.core.World)
    var _world:World;
    
    public function init():Void {};
    public function lateInit():Void {};
}