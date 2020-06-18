package kappa.phys;

import kha.FastFloat;
import kappa.math.Vec3;
import kappa.core.IComponent;

class SphereCollider implements IComponent
{
    @:initArg public var radius:FastFloat = 1;
    @:initArg public var center:Vec3 = {};

    @:allow(kappa.phys.PhysicsSystem)
    var _body:bullet.Bt.RigidBody = null;
}