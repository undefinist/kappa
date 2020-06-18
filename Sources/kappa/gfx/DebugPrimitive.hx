package kappa.gfx;

import kha.Shaders;
import kha.graphics4.BlendingFactor;
import kha.graphics4.PipelineState;
import kha.graphics4.VertexStructure;
import kha.graphics4.IndexBuffer;
import kha.graphics4.VertexBuffer;
import haxe.io.UInt32Array;
import haxe.io.Float32Array;
import kappa.math.Vec3;

class DebugPrimitive
{
    static var _sphere:DebugPrimitive;
    public static var sphere(get, never):DebugPrimitive;
    static function get_sphere() { return _sphere == null ? (_sphere = createWireSphere(1, 0.1, 16, 8)) : _sphere; }

    static function createWireSphere(radius:Float, thickness:Float, sectorCount:Int, stackCount:Int):DebugPrimitive
    {
        var vertices:Array<Vec3> = [];
        var indices:Array<UInt> = [];
    
        var sectorStep = 2 * Math.PI / sectorCount;
        var stackStep = Math.PI / stackCount;
        var sectorAngle = 0.0, stackAngle = 0.0; 
    
        for(i in 0...stackCount + 1)
        {
            stackAngle = Math.PI / 2 - i * stackStep;        // starting from pi/2 to -pi/2

            var y = radius * Math.sin(stackAngle);           // r * sin(u)
            var xz = radius * Math.cos(stackAngle);          // r * cos(u)
    
            // add (sectorCount+1) vertices per stack
            // the first and last vertices have same position and normal, but different tex coords
            for(j in 0...sectorCount + 1)
            {
                sectorAngle = j * sectorStep;           // starting from 0 to 2pi
                var x = xz * Math.cos(sectorAngle);
                var z = xz * Math.sin(sectorAngle);
                vertices.push(new Vec3(x, y, z));
            }
        }
    
        // indices
        //  k1--k1+1
        //  |    |
        //  |    |
        //  k2--k2+1
        for(i in 0...stackCount)
        {
            for(j in 0...sectorCount)
            {
                var k1 = i * (sectorCount + 1) + j;
                var k2 = k1 + (sectorCount + 1);

                indices.push(k1); indices.push(k2);
                indices.push(k1); indices.push(k1+1);
            }
        }

        var data:MeshData = { positions: new Float32Array(vertices.length * 3), indices: UInt32Array.fromArray(indices) };
        for(i in 0...vertices.length)
        {
            data.positions[i * 3 + 0] = vertices[i].x;
            data.positions[i * 3 + 1] = vertices[i].y;
            data.positions[i * 3 + 2] = vertices[i].z;
        }

        return new DebugPrimitive(data, 0);
    }



    static final _structure:VertexStructure = createVertexStructure();

    var _vb:VertexBuffer;
    var _ib:IndexBuffer;
    public var shape(default, null):Int;
    public var indicesCount(get, never):Int;
    function get_indicesCount()
    {
        return _ib.count();
    }

    public function new(data:MeshData, shape:Int)
    {
        this.shape = shape;

        _vb = new VertexBuffer(Std.int(data.positions.length / 3), _structure, StaticUsage);
        {
            var buf = _vb.lock();
            var i = 0, n = 0;
            while(i < buf.length)
            {
                buf[i++] = data.positions[n * 3 + 0];
                buf[i++] = data.positions[n * 3 + 1];
                buf[i++] = data.positions[n * 3 + 2];
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
        return structure;
    }

    public static function createDebugPipeline():PipelineState
    {
        var pipeline = new PipelineState();
        pipeline.inputLayout = [ _structure ];
        pipeline.vertexShader = Shaders.debug_vert;
        pipeline.fragmentShader = Shaders.debug_frag;
		pipeline.blendSource = BlendingFactor.BlendOne;
		pipeline.blendDestination = BlendingFactor.InverseSourceAlpha;
		pipeline.alphaBlendSource = BlendingFactor.BlendOne;
        pipeline.alphaBlendDestination = BlendingFactor.InverseSourceAlpha;
        pipeline.depthMode = Always;
        pipeline.depthWrite = false;
        return pipeline;
    }
}