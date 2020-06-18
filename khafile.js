let project = new Project('kappa');

project.addSources('Sources');
project.addShaders('Shaders/**');

project.addLibrary("json2object");

project.addLibrary("iron_format");
project.addLibrary("haxebullet");

project.addAssets('assets/**', {
    nameBaseDir: 'assets',
    destination: 'assets/{dir}/{name}',
    name: '{dir}/{name}'
});
if(platform == Platform.DebugHTML5 || platform == Platform.HTML5 || platform == Platform.HTML5Worker)
    project.addAssets('Libraries/haxebullet/ammo/ammo.js');
else if(platform == Platform.Krom)
{
    project.addAssets('Libraries/haxebullet/ammo/ammo.wasm.js');
    project.addAssets('Libraries/haxebullet/ammo/ammo.wasm.wasm');
}

resolve(project);
