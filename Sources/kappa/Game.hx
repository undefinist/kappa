package kappa;

import kappa.math.Vec3;
import kha.Scheduler;
import js.Syntax;
import kappa.gfx.GraphicsSystem;
import kappa.core.Entity;
import kha.Assets;
import kha.System;
import kappa.core.World;
import kappa.phys.PhysicsSystem;
import kappa.util.Signal;
import kappa.Transform;
import kappa.Tag;

class Game
{
    var _world:World;

    var _title:String;
    var _width:Int;
    var _height:Int;

    public function new(title:String, width:Int, height:Int)
    {
        _world = new World();

        _title = title;
        _width = width;
        _height = height;

        _world.addSystem(new PhysicsSystem());
        var gfx = _world.addSystem(new GraphicsSystem());

        _world.scheduleRender(gfx.render);

        // var sign = new Signal<Entity->Void>();
        // var slot = sign.listen((e:Entity) -> trace(e));
        // sign.fire(100);
        // sign.unlisten(slot);
        // sign.fire(100);

        {
            var e = _world.create();
            _world.add(e, kappa.Transform).position = new Vec3(0, 0, -10);
            _world.add(e, kappa.gfx.Camera);
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

        // _world.view().forEach((e:Entity) -> trace(e));
        // _world.view(Transform + Tag).forEach((entity:Entity, trans:Transform, tag:Tag) -> trace(entity, trans.position));
        // _world.view(kappa.Transform - kappa.Tag).forEach((entity:Entity, trans:Transform) -> trace(entity, trans.position));
    }

    public function run()
    {
		#if js
        function loadLibAmmo(name:String, callback:()->Void)
        {
            Assets.loadBlobFromPath(name, function(b:kha.Blob)
            {
				js.Syntax.code("(1, eval)({0})", b.toString());
				function print(s:String) { trace(s); };
				#if kha_krom
                function instantiateWasm(imports, successCallback)
                {
					var wasmbin = Krom.loadBlob("ammo.wasm.wasm");
					var module = new js.lib.webassembly.Module(wasmbin);
					var inst = new js.lib.webassembly.Instance(module, imports);
					successCallback(inst);
					return inst.exports;
				};
				js.Syntax.code("Ammo({print:print, instantiateWasm:instantiateWasm}).then(callback)");
				#else
				js.Syntax.code("Ammo({print:print}).then(callback)");
				#end
			});
		}
		#end

        function oninit()
        {
            _world.init();
            _world.lateInit();

            Scheduler.addTimeTask(function () { update(); }, 0, 1 / 60);
            System.notifyOnFrames(function (framebuffers) { render(framebuffers[0].g4); });
        }

        System.start({title: _title, width: _width, height: _height}, function(_)
        {
            // Just loading everything is ok for small projects
            Assets.loadEverything(function() 
            {
                #if kha_krom
                loadLibAmmo("ammo.wasm.js", oninit);
                #elseif js
                loadLibAmmo("ammo.js", oninit);
                #else
                oninit();
                #end
            });
        });
        
    }

    function update():Void
    {
        _world.update();
    }

    function render(g:kha.graphics4.Graphics) : Void 
    {
        _world.render(g);
    }
}
