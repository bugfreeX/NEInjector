##NEInject
dylib injector for mach-o binaries

###API
```
/**
dylib injector for mach-o binaries

@param machoPath mach-o file path
@param dylibPath .dylib file path
*/
+(void)injectMachoPath:(NSString *)machoPath dylibPath:(NSString *)dylibPath;
```


##Usage
```
[NEInject injectMachoPath:@"~.xxx/Payload/xxx.app/execFileName" dylibPath:@"~.xxx/Payload/xxx.app/xxxx.dylib"];
```
