package kappa;

import kappa.math.Vec3;
import kha.Scheduler;
import kappa.gfx.GraphicsSystem;
import kappa.core.Entity;
import kha.Assets;
import kha.System;
import kappa.core.World;
import kappa.phys.PhysicsSystem;
import kappa.util.Signal;
import kappa.Transform;
import kappa.scene.Tag;

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

        var phys = _world.addSystem(new PhysicsSystem());
        var gfx = _world.addSystem(new GraphicsSystem());

        _world.scheduleUpdate(phys.update);
        _world.scheduleRender(gfx.render);
    }

    public function run(callback:(world:World)->Void)
    {
		#if js
        function loadLibAmmo(name:String, ammoCallback:()->Void)
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
				js.Syntax.code("Ammo({print:print, instantiateWasm:instantiateWasm}).then(ammoCallback)");
				#else
				js.Syntax.code("Ammo({print:print}).then(ammoCallback)");
				#end
			});
		}
		#end

        function oninit()
        {
            _world.init();
            _world.lateInit();

            if(callback != null)
                callback(_world);

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
