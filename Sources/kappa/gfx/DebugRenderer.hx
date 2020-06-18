package kappa.gfx;

import kha.FastFloat;
import kappa.math.Vec3;
import kappa.math.Color;
import kappa.math.Mat4;

@:allow(kappa.gfx.GraphicsSystem)
@:structInit
private class DebugInfo
{
    var mesh:DebugPrimitive;
    var transform:Mat4;
    var color:Color;
    var duration:FastFloat;
}

class DebugRenderer
{
    public var matrix:Mat4 = Mat4.identity();

    @:allow(kappa.gfx.GraphicsSystem)
    var _data:Array<DebugInfo> = [];

    public function new() {}

    public function drawWireSphere(center:Vec3, radius:FastFloat, color:Color = 0xff00ff00, duration:FastFloat = 0)
    {
        _data.push({ 
            mesh: DebugPrimitive.sphere, 
            transform: matrix
                * Mat4.translation(center.x, center.y, center.z)
                * Mat4.scale(radius, radius, radius),
            color: color,
            duration: duration });
    }

    public function clear()
    {
        _data.resize(0);
    }
}