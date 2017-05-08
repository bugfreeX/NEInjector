## NEInjector
dylib injector for mach-o binaries

## API
```objective-c
/**
dylib injector for mach-o binaries

@param machoPath mach-o file path
@param dylibPath .dylib file path
*/
+(void)injectMachoPath:(NSString *)machoPath dylibPath:(NSString *)dylibPath;
```


## Usage
```objective-c
[NEInjector injectMachoPath:@"~.xxx/Payload/xxx.app/machoFileName" dylibPath:@"~.xxx/Payload/xxx.app/xxxx.dylib"];
```
