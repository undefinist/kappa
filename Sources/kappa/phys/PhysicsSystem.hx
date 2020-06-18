package kappa.phys;

import kappa.math.Quat;
import kappa.gfx.DebugRenderer;
import kappa.core.ComponentType;
import kappa.math.Vec3;
import kappa.core.Entity;
import kappa.core.IComponent;
import kappa.core.System;
import kappa.Transform;

class PhysicsSystem extends System
{
    var _collisionConfiguration:bullet.Bt.DefaultCollisionConfiguration;
    var _dispatcher:bullet.Bt.CollisionDispatcher;
    var _broadphase:bullet.Bt.DbvtBroadphase;
    var _solver:bullet.Bt.SequentialImpulseConstraintSolver;
    var _dynamicsWorld:bullet.Bt.DiscreteDynamicsWorld;

    // entity index => Bt.RigidBody
    var _btRigidBodies:Array<bullet.Bt.RigidBody> = [];

    var _debug:DebugRenderer;

    public function new() {}

    override public function init() 
    {
        _collisionConfiguration = new bullet.Bt.DefaultCollisionConfiguration();
        _dispatcher = new bullet.Bt.CollisionDispatcher(_collisionConfiguration);
        _broadphase = new bullet.Bt.DbvtBroadphase();
        _solver = new bullet.Bt.SequentialImpulseConstraintSolver();
        _dynamicsWorld = new bullet.Bt.DiscreteDynamicsWorld(_dispatcher, _broadphase, _solver, _collisionConfiguration);

        _world.onComponentAdded.listen((e, comp) ->
        {
            if(comp.__type == ComponentType.fromClass(RigidBody)) 
                onRigidBodyAdded(e, cast comp);
            if(comp.__type == ComponentType.fromClass(SphereCollider)) 
                onSphereColliderAdded(e, cast comp);
        });

        _debug = _world.findSystem(kappa.gfx.GraphicsSystem).debug;

        // var groundShape = new bullet.Bt.StaticPlaneShape(new bullet.Bt.Vector3(0, 1, 0), 1);
        // var groundTransform = new bullet.Bt.Transform();
        // groundTransform.setIdentity();
        // groundTransform.setOrigin(new bullet.Bt.Vector3(0, -2, 0));
        // var centerOfMassOffsetTransform = new bullet.Bt.Transform();
        // centerOfMassOffsetTransform.setIdentity();
        // var groundMotionState = new bullet.Bt.DefaultMotionState(groundTransform, centerOfMassOffsetTransform);

        // var groundRigidBodyCI = new bullet.Bt.RigidBodyConstructionInfo(0.01, groundMotionState, cast groundShape, new bullet.Bt.Vector3(0, 0, 0));
        // var groundRigidBody = new bullet.Bt.RigidBody(groundRigidBodyCI);
        // _dynamicsWorld.addRigidBody(groundRigidBody);
    }

    override public function lateInit() 
    {
    }

    private function onRigidBodyAdded(e:Entity, rb:RigidBody)
    {
        var btrb = _btRigidBodies[e.index];
        var trans = _world.get(e, Transform);

        if(btrb == null)
        {
            var ci = createBtRigidBodyCI(trans, rb.mass, null);
            btrb = new bullet.Bt.RigidBody(ci);
            _dynamicsWorld.addRigidBodyToGroup(btrb, 0, 0); // prevent collisions since no shape
            registerBtRigidBody(e, btrb);
        }
        else 
        { 
            // convert static rb to dynamic rb
            _dynamicsWorld.removeRigidBody(btrb);
            var inertia = new bullet.Bt.Vector3(0, 0, 0);
            btrb.getCollisionShape().calculateLocalInertia(rb.mass, inertia);
            btrb.setMassProps(rb.mass, inertia);
            _dynamicsWorld.addRigidBody(btrb);
        }

        rb._body = btrb;
    }

    private function onSphereColliderAdded(e:Entity, col:SphereCollider)
    {
        var rb = _world.get(e, RigidBody);
        var trans = _world.get(e, Transform);

        var shape = new bullet.Bt.SphereShape(col.radius);
        shape.setLocalScaling(k2bVec3(trans.scale));

        // construct static collider
        if(rb == null)
        {
            var ci = createBtRigidBodyCI(trans, 0, shape);
            col._body = new bullet.Bt.RigidBody(ci);
            _dynamicsWorld.addRigidBody(col._body);
            registerBtRigidBody(e, col._body);
        }
        else 
        {
            updateBtRigidBodyShape(rb, shape);
        }
    }

    private function updateBtRigidBodyShape(rb:RigidBody, shape:bullet.Bt.CollisionShape)
    {
        _dynamicsWorld.removeRigidBody(rb._body);

        rb._body.setCollisionShape(shape);

        var inertia = new bullet.Bt.Vector3(0, 0, 0);
        if(shape != null)
            shape.calculateLocalInertia(rb.mass, inertia);
        rb._body.setMassProps(rb.mass, inertia);

        _dynamicsWorld.addRigidBody(rb._body);
    }

    private function createBtRigidBodyCI(trans:Transform, mass:Float, shape:bullet.Bt.CollisionShape):bullet.Bt.RigidBodyConstructionInfo
    {
        var btTrans = new bullet.Bt.Transform();
        var pos = trans.position;
        var rot = trans.rotation;
        btTrans.setOrigin(new bullet.Bt.Vector3(pos.x, pos.y, pos.z));
        btTrans.setRotation(new bullet.Bt.Quaternion(rot.x, rot.y, rot.z, rot.w));
        var com = new bullet.Bt.Transform();
        com.setIdentity();
        var inertia = new bullet.Bt.Vector3(0, 0, 0);
        if(shape != null)
            shape.calculateLocalInertia(mass, inertia);
        return new bullet.Bt.RigidBodyConstructionInfo(mass, new bullet.Bt.DefaultMotionState(btTrans, com), shape, inertia);
    }

    private function registerBtRigidBody(e:Entity, rb:bullet.Bt.RigidBody)
    {
        if(e.index >= _btRigidBodies.length)
            _btRigidBodies.resize(e.index + 1);
        _btRigidBodies[e.index] = rb;

        rb.setUserIndex(e);
    }

    public function update(dt:Float)
    {
        _dynamicsWorld.stepSimulation(dt);

        var dispatcher = _dispatcher;

        // // Collision
        // for (i in 0...dispatcher.getNumManifolds()) {
        //     var m:bullet.Bt.PersistentManifold = dispatcher.getManifoldByIndexInternal(i);
        //     var b0:bullet.Bt.CollisionObject = m.getBody0();
        //     var b1:bullet.Bt.CollisionObject = m.getBody1();
        //     trace((cast b0.getUserIndex() : Entity), (cast b1.getUserIndex() : Entity));
        // }

        _world.view(Transform + RigidBody).forEach((entity, transform, rb) -> 
        {
            var rbTrans = new bullet.Bt.Transform();
            rb._body.getMotionState().getWorldTransform(rbTrans);
            transform.position = b2kVec3(rbTrans.getOrigin());
            transform.rotation = b2kQuat(rbTrans.getRotation());
            //trace(_btRigidBodies);
        });

        _world.view(Transform + SphereCollider).forEach((entity, transform, collider) -> 
        {
            _debug.matrix = transform.local;
            _debug.drawWireSphere(collider.center, collider.radius);
        });
    }

    static function b2kVec3(vec:bullet.Bt.Vector3):Vec3
    {
        return new Vec3(vec.x(), vec.y(), vec.z());
    }
    static function k2bVec3(vec:Vec3):bullet.Bt.Vector3
    {
        return new bullet.Bt.Vector3(vec.x, vec.y, vec.z);
    }
    
    static function b2kQuat(quat:bullet.Bt.Quaternion):Quat
    {
        return new Quat(quat.x(), quat.y(), quat.z(), quat.w());
    }
}