package kappa.gfx;

import kha.FastFloat;
import kappa.core.IComponent;
import kappa.gfx.LightType;
import kappa.math.Color;

class Light implements IComponent
{
    @:initArg public var type:LightType = PointLight(5);
    @:initArg public var intensity:FastFloat = 1;
    @:initArg public var color:Color = 0xffffffff;
    public var enabled:Bool = true;
}