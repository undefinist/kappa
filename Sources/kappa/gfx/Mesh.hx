package kappa.gfx;

import kha.Shaders;
import kha.graphics4.IndexBuffer;
import kha.graphics4.VertexBuffer;
import kha.graphics4.BlendingFactor;
import kha.graphics4.Graphics;
import kha.graphics4.IndexBuffer;
import kha.graphics4.PipelineState;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexStructure;

class Mesh
{
    static final _structure:VertexStructure = createVertexStructure();

    var _vb:VertexBuffer;
    var _ib:IndexBuffer;

    public function new(data:MeshData)
    {
        _vb = new VertexBuffer(Std.int(data.positions.length / 3), _structure, StaticUsage);
        {
            var buf = _vb.lock();
            var i = 0, n = 0;
            while(i < buf.length)
            {
                buf[i++] = data.positions[n * 3 + 0];
                buf[i++] = data.positions[n * 3 + 1];
                buf[i++] = data.positions[n * 3 + 2];
                buf[i++] = data.normals[n * 3 + 0];
                buf[i++] = data.normals[n * 3 + 1];
                buf[i++] = data.normals[n * 3 + 2];
                buf[i++] = data.texCoords[n * 2 + 0];
                buf[i++] = data.texCoords[n * 2 + 1];
                buf[i++] = data.tangents[n * 3 + 0];
                buf[i++] = data.tangents[n * 3 + 1];
                buf[i++] = data.tangents[n * 3 + 2];
                ++n;
            }
            _vb.unlock();
        }

        _ib = new IndexBuffer(data.indices.length, StaticUsage);
        {
            var buf = _ib.lock();
            for(i in 0...buf.length)
                buf[i] = data.indices[i];
            _ib.unlock();
        }
    }

    public function bind(g:kha.graphics4.Graphics)
    {
        g.setVertexBuffer(_vb);
        g.setIndexBuffer(_ib);
    }

    public static function createVertexStructure():VertexStructure
    {
        var structure = new VertexStructure();
        structure.add("position", Float3);
        structure.add("normal", Float3);
        structure.add("uv", Float2);
        structure.add("tangent", Float3);
        return structure;
    }

    public static function createMeshPipeline():PipelineState
    {
        var pipeline = new PipelineState();
        pipeline.inputLayout = [ _structure ];
        pipeline.vertexShader = Shaders.mesh_vert;
        //pipeline.fragmentShader = Shaders.pbr_forward_frag;
		pipeline.blendSource = BlendingFactor.BlendOne;
		pipeline.blendDestination = BlendingFactor.InverseSourceAlpha;
		pipeline.alphaBlendSource = BlendingFactor.BlendOne;
        pipeline.alphaBlendDestination = BlendingFactor.InverseSourceAlpha;
        pipeline.depthMode = LessEqual;
        pipeline.depthWrite = true;
        //pipeline.cullMode = Clockwise;
        return pipeline;
    }

}