package kappa.gfx;

import kappa.math.Quat;
import kha.graphics4.Graphics2;
import kha.graphics4.PipelineState;
import kha.graphics4.IndexBuffer;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexStructure;
import kha.graphics4.Graphics;
import kappa.core.System;
import kappa.gfx.Camera;
import kappa.Transform;
import kappa.math.Mat4;

class GraphicsSystem extends System
{
	var pipeline:PipelineState;
    var vbo:VertexBuffer;
    var ibo:IndexBuffer;

    public function new()
    {
    }

    override function init()
    {
        vbo = new VertexBuffer(6 * 4, Graphics2.createColoredVertexStructure(), StaticUsage);
        {
            var sz = 0.5;
            var cpy = [
                 sz,  sz,  sz, 1,1,1,1,// 0, 0, 1, // front
                 sz, -sz,  sz, 1,1,1,1,// 0, 0, 1,
                -sz, -sz,  sz, 1,1,1,1,// 0, 0, 1,
                -sz,  sz,  sz, 1,1,1,1,// 0, 0, 1,
                 sz,  sz, -sz, 1,1,1,1,// 0, 0,-1, // back
                 sz, -sz, -sz, 1,1,1,1,// 0, 0,-1,
                -sz, -sz, -sz, 1,1,1,1,// 0, 0,-1,
                -sz,  sz, -sz, 1,1,1,1,// 0, 0,-1,
                -sz,  sz,  sz, 1,1,1,1,//-1, 0, 0, // left
                -sz,  sz, -sz, 1,1,1,1,//-1, 0, 0,
                -sz, -sz, -sz, 1,1,1,1,//-1, 0, 0,
                -sz, -sz,  sz, 1,1,1,1,//-1, 0, 0,
                 sz,  sz,  sz, 1,1,1,1,// 1, 0, 0, // right
                 sz,  sz, -sz, 1,1,1,1,// 1, 0, 0,
                 sz, -sz, -sz, 1,1,1,1,// 1, 0, 0,
                 sz, -sz,  sz, 1,1,1,1,// 1, 0, 0,
                 sz,  sz,  sz, 1,1,1,1,// 0, 1, 0, // top
                 sz,  sz, -sz, 1,1,1,1,// 0, 1, 0,
                -sz,  sz, -sz, 1,1,1,1,// 0, 1, 0,
                -sz,  sz,  sz, 1,1,1,1,// 0, 1, 0,
                 sz, -sz,  sz, 1,1,1,1,// 0,-1, 0, // bottom
                 sz, -sz, -sz, 1,1,1,1,// 0,-1, 0,
                -sz, -sz, -sz, 1,1,1,1,// 0,-1, 0,
                -sz, -sz,  sz, 1,1,1,1,// 0,-1, 0
            ];
            var data = vbo.lock();
            for(i in 0...data.length)
                data[i] = cpy[i];
            vbo.unlock();
        }

        ibo = new IndexBuffer(24, StaticUsage);
        {
            var cpy = [
                1, 0, 3,
                2, 1, 3,
                4, 5, 7,
                5, 6, 7,
                8, 9, 11,
                9, 10, 11,
                13, 12, 15,
                14, 13, 15,
                16, 17, 19,
                17, 18, 19,
                21, 20, 23,
                22, 21, 23,
            ];
            var data = ibo.lock();
            for(i in 0...data.length)
                data[i] = cpy[i];
            ibo.unlock();
        }

        pipeline = Graphics2.createColoredPipeline(Graphics2.createColoredVertexStructure());
        pipeline.compile();
    }

    public function render(g:Graphics)
    {
        _world.view(Camera + Transform).forEach((entity, camera, transform) -> {
            var w = kha.System.windowWidth();
            var h = kha.System.windowHeight();
            g.begin();
            g.viewport(cast w * camera.rect.x0, cast h * camera.rect.y0,
                       cast w * camera.rect.x1, cast h * camera.rect.y1);
            g.clear(0x6495EDff);
            g.setPipeline(pipeline);
            var proj = Mat4.perspectiveProjection(
                camera.fieldOfView, (camera.rect.width * w) / (camera.rect.height * h), camera.nearPlane, camera.farPlane);

            // rotate 180 so camera is more intuitive
            var view = transform.local.multmat(Quat.fromAxisAngle(transform.up, Math.PI).matrix()).inverse();

            g.setMatrix(pipeline.getConstantLocation("projectionMatrix"), proj.multmat(view)); 
            g.setVertexBuffer(vbo);
            g.setIndexBuffer(ibo);
            g.drawIndexedVertices();
            g.end();
        });

    }
}