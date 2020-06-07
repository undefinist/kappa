package kappa;

import kappa.math.Vec3;
import kappa.math.Quat;
import kappa.math.Mat4;
import kappa.core.IComponent;

@:structInit
class Transform implements IComponent
{
    public var position:Vec3;
    public var rotation:Quat;
    public var scale:Vec3;

    public var right(get, never):Vec3;
    function get_right():Vec3
    {
        var composed:Mat4 = local;
        return new Vec3(composed._00, composed._01, composed._02).normalized();
    }

    public var up(get, never):Vec3;
    function get_up():Vec3
    {
        var composed:Mat4 = local;
        return new Vec3(composed._10, composed._11, composed._12).normalized();
    }

    public var forward(get, never):Vec3;
    function get_forward():Vec3
    {
        var composed:Mat4 = local;
        return new Vec3(composed._20, composed._21, composed._22).normalized().mult(-1);
    }

    public var local(get, never):Mat4;
    function get_local():Mat4
    {
        return Mat4.translation(position.x, position.y, position.z)
                .multmat(rotation.matrix())
                .multmat(Mat4.scale(scale.x, scale.y, scale.z));
    }

    public function init():Void
    {
        position = new Vec3();
        rotation = new Quat();
        scale = new Vec3(1, 1, 1);
    }
}