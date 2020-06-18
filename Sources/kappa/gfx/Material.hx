package kappa.gfx;

import kha.graphics4.VertexStructure;
import kha.graphics4.BlendingFactor;
import kha.graphics4.PipelineState;
import kha.Shaders;
import kha.Blob;
import kha.graphics4.CullMode;
import kha.graphics4.VertexShader;
import kha.graphics4.FragmentShader;
import kappa.gfx.UniformValue;

@:noCompletion
enum abstract _CullMode(String) {
    var Clockwise;
    var CounterClockwise;
    var None;
}

@:noCompletion
class MaterialData
{
    public var vertexShader:String;
    public var fragmentShader:String;
    public var depthWrite:Bool;
    public var cullMode:_CullMode;
    public var parameters:Map<String, UniformValue>;
}

class Material extends kappa.res.Resource
{
    var uniforms:Map<String, UniformValue>;
    public var vertexShader(default, null):VertexShader;
    public var fragmentShader(default, null):FragmentShader;
    public var pipeline(default, null):PipelineState;

    public static function load(blob:Blob)
    {
        var parser = new json2object.JsonParser<MaterialData>();
        var data = parser.fromJson(blob.toString());
        return new Material(data);
    }

    private function new(data:MaterialData)
    {
        super();

        vertexShader = Reflect.field(Shaders, data.vertexShader);
        fragmentShader = Reflect.field(Shaders, data.fragmentShader);

        pipeline = new PipelineState();
        pipeline.vertexShader = vertexShader;
        pipeline.fragmentShader = fragmentShader;

        // build structure from inputs
        var structure = new VertexStructure();
        for(input in ShaderInterface.map.get(data.vertexShader).inputs)
        {
            if(input.name.indexOf("gl_") == 0)
                continue;
            structure.add(input.name, switch(input.type) {
                case "float": Float1;
                case "vec2": Float2;
                case "vec3": Float3;
                case "vec4": Float4;
                case "mat4": Float4x4;
                default: throw "only float, vec2, vec3, vec4, and mat4 vertex inputs supported!";
            });
        }
        pipeline.inputLayout = [ structure ];

        pipeline.blendSource = BlendingFactor.BlendOne;
        pipeline.blendDestination = BlendingFactor.InverseSourceAlpha;
        pipeline.alphaBlendSource = BlendingFactor.BlendOne;
        pipeline.alphaBlendDestination = BlendingFactor.InverseSourceAlpha;
        pipeline.depthMode = LessEqual;
        pipeline.depthWrite = data.depthWrite;
        pipeline.cullMode = switch(data.cullMode) {
            case Clockwise: CullMode.Clockwise;
            case CounterClockwise: CullMode.CounterClockwise;
            case None: CullMode.None;
        };

        pipeline.compile();
    }
}