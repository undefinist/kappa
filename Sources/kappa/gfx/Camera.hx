package kappa.gfx;

import kha.FastFloat;
import kappa.core.IComponent;
import kappa.math.Rect;

class Camera implements IComponent
{
    public var nearPlane:FastFloat;
    public var farPlane:FastFloat;
    public var depth:FastFloat;
    public var fieldOfView:FastFloat;
    public var rect:Rect;

    public function init()
    {
        nearPlane = 0.1;
        farPlane = 100;
        depth = 0;
        fieldOfView = Math.PI * 90 / 180;
        rect = { x0: 0, y0: 0, x1: 1, y1: 1 };
    }
}