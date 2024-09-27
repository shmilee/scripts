const liteloader_dir = require("path").join(
    '/opt/QQ/resources/app',
    // or user's XDG_CONFIG_HOME
    //require("os").homedir(), '.config',
    'LiteLoaderQQNT'
);
if (require("fs").existsSync(liteloader_dir)) {
    console.log('Use LiteLoaderQQNT in %s', liteloader_dir);
    if (process.env.LITELOADERQQNT_PROFILE) {
        console.log('Use LITELOADERQQNT_PROFILE in %s', process.env.LITELOADERQQNT_PROFILE);
    } else {
        console.warn('!!!!! LITELOADERQQNT_PROFILE not set!');
    }
    require(liteloader_dir);
} else {
    // default QQ
    require(require("path").join(process.resourcesPath, "app/app_launcher/index.js"));
    setTimeout(() => {
        // qqnt.buildVersion >= 28060
        global.launcher.installPathPkgJson.main = "./application/app_launcher/index.js";
    }, 0);
}
