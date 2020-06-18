package kappa.phys;

import kappa.math.Vec3;
import kha.FastFloat;
import kappa.core.IComponent;

@:require(kappa.Transform)
class RigidBody implements IComponent
{
    @:initArg public var mass:FastFloat = 1;
    
    @:allow(kappa.phys.PhysicsSystem)
    var _body:bullet.Bt.RigidBody = null;

    public function addForce(force:Vec3)
    {
        _body.applyCentralForce(new bullet.Bt.Vector3(force.x, force.y, force.z));
    }
}