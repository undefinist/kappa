package;

import kappa.math.Quat;
import kha.Assets;
import kha.Shaders;
import kappa.gfx.Mesh;
import kappa.gfx.Material;
import kappa.core.Entity;
import kappa.Transform;
import kappa.scene.Tag;
import kappa.phys.RigidBody;
import kappa.math.Vec3;
import kappa.core.World;

class Main 
{
    public static function main() 
    {
        new kappa.Game("Game", 800, 600).run((_world:World) ->
        {
            {
                var e = _world.create();
                _world.add(e, kappa.Transform, new Vec3(0, 0, 20));
                _world.add(e, kappa.gfx.Camera);
                _world.add(e, kappa.scene.Tag);
                _world.add(e, kappa.gfx.Light).type = PointLight(20);
            }
    
            var teapot = new Mesh(kappa.format.obj.Reader.read(Assets.blobs.teapot_obj));
            var pbr = Material.load(Assets.blobs.default_mesh_mat);
            {
                var e = _world.create();
                _world.add(e, kappa.Transform, new Vec3(0, 10, 0));
                var rb = _world.add(e, kappa.phys.RigidBody, 20);
                _world.add(e, kappa.phys.SphereCollider, 2);
                _world.add(e, kappa.gfx.MeshRenderer, teapot, pbr);
                //rb.addForce(new Vec3(50, 0, 0));
            }

            {
                var e = _world.create();
                _world.add(e, kappa.Transform, new Vec3(0, 5, 0));
                var rb = _world.add(e, kappa.phys.RigidBody, 1);
                _world.add(e, kappa.phys.SphereCollider, 1);
                _world.add(e, kappa.gfx.MeshRenderer, teapot, pbr);
                //rb.addForce(new Vec3(50, 0, 0));
            }

            {
                var e = _world.create();
                var rb = _world.add(e, kappa.phys.RigidBody, 15);
                _world.add(e, kappa.phys.SphereCollider, 2);
                _world.add(e, kappa.gfx.MeshRenderer, teapot, pbr);
                //rb.addForce(new Vec3(50, 0, 0));
            }
    
            {
                var e = _world.create();
                _world.add(e, kappa.Transform, new Vec3(0, -10, 0));
                _world.add(e, kappa.phys.SphereCollider, 3);
                _world.add(e, kappa.gfx.MeshRenderer, teapot, pbr);
            }
    
            // var e = _world.create();
            // var e2 = _world.create();
            // _world.add(e, kappa.Transform);
            // _world.add(e2, kappa.Transform).position = new Vec3(1, 1, 2);
            // _world.get(e, kappa.Transform).position = new Vec3(1, 1, 1);
            // _world.add(e, kappa.Tag, "Player");
            // _world.add(e2, kappa.Tag);
            // _world.destroy(e2);
            // e2 = _world.create();
            // _world.add(e2, kappa.Transform);
    
            _world.view().forEach((e:Entity) -> trace(e));
            _world.view(Transform + Tag).forEach((entity:Entity, trans:Transform, tag:Tag) -> trace(entity, trans.position));
            _world.view(kappa.Transform - kappa.scene.Tag).forEach((entity:Entity, trans:Transform) -> trace(entity, trans.position));
        });
    }
}
