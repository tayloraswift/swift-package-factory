import PackagePlugin

#if os(Linux)
import Glibc
#elseif os(macOS)
import Darwin 
#endif 

@main 
struct Main:CommandPlugin
{
    private static 
    func targets(context:PluginContext, filter:[String]) throws -> [SwiftSourceModuleTarget] 
    {
        var targets:[String: [SwiftSourceModuleTarget]] = [:]
        for target:any Target in context.package.targets 
        {
            guard let target:SwiftSourceModuleTarget = target as? SwiftSourceModuleTarget 
            else 
            {
                continue 
            }
            targets[target.name, default: []].append(target)
        }
        if filter.isEmpty 
        {
            return targets.sorted { $0.key < $1.key } .flatMap(\.value)
        }
        else 
        {
            return try filter.flatMap 
            {
                (name:String) -> [SwiftSourceModuleTarget] in 
                if let targets:[SwiftSourceModuleTarget] = targets[name]
                {
                    return targets 
                }
                else 
                {
                    throw MissingTargetError.init(name: name)
                }
            }
        }
    }
    func performCommand(context:PluginContext, arguments:[String]) throws 
    {
        let tool:PluginContext.Tool = try context.tool(named: "swift-package-factory")
        for target:SwiftSourceModuleTarget in try Self.targets(context: context, filter: arguments) 
        {
            for file:File in target.sourceFiles
            {
                guard case .unknown = file.type 
                else 
                {
                    continue 
                }
                switch file.path.extension 
                {
                case "spf", "swiftpf", "factory":
                    #if os(macOS)
                    tool.path.string.withCString 
                    {
                        (tool:UnsafePointer<CChar>) in 
                        file.path.string.withCString 
                        {
                            (file:UnsafePointer<CChar>) in 
                            var pid:pid_t = 0
                            posix_spawn(&pid, tool, nil, nil, [.init(mutating: tool), .init(mutating: file)], nil)
                            var status:Int32 = 0
                            waitpid(pid, &status, 0)
                        }
                    }
                    
                    #else
                    switch system("\(tool.path.string) \(file.path.string)")
                    {
                    case 0: 
                        break 
                    case let code: 
                        print("failed to transform file '\(file.path.string)' (exit code: \(code))")
                    }
                    #endif
                default: 
                    continue 
                }
            }
        }
    }
}