package kappa.gfx;

import kappa.Transform;
import kappa.core.System;
import kappa.gfx.Camera;
import kappa.gfx.LightData;
import kappa.math.Mat4;
import kappa.math.Quat;
import kappa.math.Vec3;
import kappa.res.ResourceId;
import kha.FastFloat;
import kha.SystemImpl;
import kha.graphics4.Graphics;
import kha.graphics4.PipelineState;

@:structInit
class RenderObject
{
    public var mesh:Mesh;
    public var material:Material;
    public var transform:Mat4;
}

class GraphicsSystem extends System
{
    var debugPipeline:PipelineState;

    var move:Vec3 = new Vec3();
    var rx:FastFloat = 0;
    var ry:FastFloat = 0;

    var prevTime:Float = 0;

    public var debug(default, null):DebugRenderer = new DebugRenderer();

    public function new()
    {
    }

    override function init()
    {
        kha.input.Keyboard.get().notify(onKeyDown, onKeyUp);

        if(debugPipeline == null)
        {
            debugPipeline = DebugPrimitive.createDebugPipeline();
            debugPipeline.compile();
        }
    }

    public function render(g:Graphics)
    {
        debug._data.sort((info1, info2) -> return info1.mesh.shape - info2.mesh.shape);

        var lightData:Array<LightData> = [];
        _world.view(Light + Transform).forEach((entity, light, transform) ->
        {
            if(light.enabled)
                lightData.push(LightData.create(light, transform));
        });

        _world.view(Camera + Transform).forEach((entity, camera, transform) -> 
        {
            transform.rotation = transform.rotation.mul(Quat.fromAxisAngle(new Vec3(0, 1, 0), rx * 0.02));
            transform.rotation = transform.rotation.mul(Quat.fromAxisAngle(transform.right, ry * 0.02));

            transform.position += transform.forward * move.z * 0.1; 
            transform.position += transform.right * move.x * 0.1; 
            transform.position += transform.up * move.y * 0.1; 

            final w = kha.System.windowWidth();
            final h = kha.System.windowHeight();
            g.begin();
            g.viewport(cast w * camera.rect.x0, cast h * camera.rect.y0,
                       cast w * camera.rect.x1, cast h * camera.rect.y1);
            g.clear(0xFF6495ED);

            final inv_view = transform.local;
            final view:Mat4 = inv_view.inverse();
            
            final proj = Mat4.perspectiveProjection(
                camera.fieldOfView, (camera.rect.width * w) / (camera.rect.height * h), camera.nearPlane, camera.farPlane);

            var renderables:Array<RenderObject> = [];
            
            _world.view(MeshRenderer + Transform).forEach((entity, renderer, transform) -> 
            {
                renderables.push({
                    mesh: renderer.mesh,
                    material: renderer.material,
                    transform: view * transform.local
                });
            });

            // batch by:
            // - material
            // - texture
            // - material instance
            renderables.sort((object1, object2) -> object1.material.id - object2.material.id);

            var currMat:ResourceId = 0;
            var pipeline:PipelineState = null;
            for(obj in renderables)
            {
                if(obj.material.id != currMat)
                {
                    pipeline = obj.material.pipeline;
                    g.setPipeline(pipeline);

                    g.setInt(pipeline.getConstantLocation("light_count"), lightData.length);
                    for(i in 0...lightData.length)
                    {
                        var light = lightData[i];
                        g.setInt(pipeline.getConstantLocation('lights[$i].type'), light.type);
                        g.setVector3(pipeline.getConstantLocation('lights[$i].color'), light.color);
                        g.setVector3(pipeline.getConstantLocation('lights[$i].v_pos'), (cast view * light.position.toVec4(0) : Vec3));
                        g.setVector3(pipeline.getConstantLocation('lights[$i].v_dir'), (cast view * light.direction.toVec4(1) : Vec3));
                        g.setFloat(pipeline.getConstantLocation('lights[$i].cos_inner'), light.cosInner);
                        g.setFloat(pipeline.getConstantLocation('lights[$i].cos_outer'), light.cosOuter);
                        g.setFloat(pipeline.getConstantLocation('lights[$i].falloff'), light.falloff);
                        g.setFloat(pipeline.getConstantLocation('lights[$i].intensity'), light.intensity);
                    }
                    
                    g.setMatrix(pipeline.getConstantLocation("projection_transform"), proj); 
                    g.setMatrix(pipeline.getConstantLocation("inverse_view_transform"), inv_view);

                    currMat = obj.material.id;
                }

                var modelview = obj.transform;
                var normTfm = modelview.inverse().transpose();
                
                g.setMatrix(pipeline.getConstantLocation("modelview_transform"), modelview);
                g.setMatrix(pipeline.getConstantLocation("normal_transform"), normTfm);

                obj.mesh.bind(g);
                g.drawIndexedVertices();
            };

            // debug draw
            g.setPipeline(debugPipeline);
            g.setMatrix(debugPipeline.getConstantLocation("projection_transform"), proj);
            var prevMesh:DebugPrimitive = null;
            for(data in debug._data)
            {
                if(data.mesh != prevMesh)
                    data.mesh.bind(g);
                var modelview = view * data.transform;
                g.setMatrix(debugPipeline.getConstantLocation("modelview_transform"), modelview);
                g.setVector3(debugPipeline.getConstantLocation("color"), data.color);
                drawLines(DebugPrimitive.sphere.indicesCount);
            }

            g.end();
        });

        var time = kha.Scheduler.time();
        var dt = time - prevTime;
        prevTime = time;
        for(data in debug._data)
            data.duration -= dt;
        debug._data = debug._data.filter(info -> info.duration > 0);
    }

    function drawLines(count:Int)
    {
        #if js
        SystemImpl.gl.drawElements(js.html.webgl.GL.LINES, count, js.html.webgl.GL.UNSIGNED_INT, 0);
        #end
    }








    function onKeyDown(key:kha.input.KeyCode)
    {
        switch (key)
        {
            case W: move.z++;
            case S: move.z--;
            case A: move.x--;
            case D: move.x++;
            case Q: move.y++;
            case E: move.y--;

            case Left: rx--;
            case Right: rx++;
            case Up: ry++;
            case Down: ry--;

            default:
        }
    }

    function onKeyUp(key:kha.input.KeyCode)
    {
        switch (key)
        {
            case W: move.z--;
            case S: move.z++;
            case A: move.x++;
            case D: move.x--;
            case Q: move.y--;
            case E: move.y++;

            case Left: rx++;
            case Right: rx--;
            case Up: ry--;
            case Down: ry++;

            default:
        }
    }
}