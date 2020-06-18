package kappa.gfx;

#if !macro

typedef ShaderVariable =
{
    var name:String;
    var type:String;
}

typedef ShaderDataType =
{
    var name:String;
    var members:Array<ShaderVariable>;
}

@:build(kappa.gfx.ShaderInterface.ShaderInterfaceMacro.build())
@:structInit
class ShaderInterface
{
    public var inputs:Array<ShaderVariable>;
    public var outputs:Array<ShaderVariable>;
    public var uniforms:Array<ShaderVariable>;
    public var types:Array<ShaderDataType>;
}

#else

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.Field;

class ShaderInterfaceMacro
{
    public static macro function build():Array<Field>
    {
        var fields = Context.getBuildFields();

		var manifestPath = kha.internal.AssetsBuilder.findResources() + "files.json";
		var content = haxe.Json.parse(sys.io.File.getContent(manifestPath));

		// rebuild Shaders module whenever manifest file is changed
		Context.registerModuleDependency(Context.getLocalModule(), manifestPath);

        var files:Iterable<Dynamic> = content.files;
        var mapInit:Array<Expr> = [];

        for (file in files) 
        {
			var name: String = file.name;
			var fixedName: String = name;
			var dataName = fixedName + "Data";
			var filenames: Array<String> = file.files;

            if (file.type == "shader")
            {
                mapInit.push(macro $v{name} => {
                    inputs: $v{file.inputs},
                    outputs: $v{file.outputs},
                    uniforms: $v{file.uniforms},
                    types: $v{file.types}
                });
            }
        }
        
        var type = Context.getLocalType();
        var complex = Context.toComplexType(type);
        fields.push({
            name: "map",
            kind: FProp("default", "null", macro:Map<String, $complex>, macro $a{mapInit}),
            pos: Context.currentPos(),
            access: [ APublic, AStatic ]
        });

        return fields;
    }
}

#end