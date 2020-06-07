package kappa.phys;

import bullet.Bt.Ammo;
import kappa.core.IComponent;
import kappa.core.System;
import bullet.*;

class PhysicsSystem extends System
{
    var collisionConfiguration:Bt.DefaultCollisionConfiguration;
    var dispatcher:Bt.CollisionDispatcher;
    var broadphase:Bt.DbvtBroadphase;
    var solver:Bt.SequentialImpulseConstraintSolver;
    var dynamicsWorld:Bt.DiscreteDynamicsWorld;

    public function new() {}

    override public function init() 
    {
        var collisionConfiguration = new Bt.DefaultCollisionConfiguration();
        var dispatcher = new Bt.CollisionDispatcher(collisionConfiguration);
        var broadphase = new Bt.DbvtBroadphase();
        var solver = new Bt.SequentialImpulseConstraintSolver();
        var dynamicsWorld = new Bt.DiscreteDynamicsWorld(dispatcher, broadphase, solver, collisionConfiguration);

        _world.onComponentAdded.listen((rb:IComponent) -> {
            if(!Std.is(rb, RigidBody))
                return;
        });
    }

    override public function lateInit() 
    {
    }
}