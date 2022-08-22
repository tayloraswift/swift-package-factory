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
        for target:SwiftSourceModuleTarget in 
            try Self.targets(context: context, filter: arguments) 
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
                    do 
                    {
                        try tool.path.string.withCString 
                        {
                            (ctool:UnsafePointer<CChar>) in 
                            try file.path.string.withCString 
                            {
                                (cfile:UnsafePointer<CChar>) in 
                                // must be null-terminated!
                                let argv:[UnsafeMutablePointer<CChar>?] = 
                                [
                                    .init(mutating: ctool), 
                                    .init(mutating: cfile), 
                                    nil
                                ]
                                var pid:pid_t = 0
                                switch posix_spawn(&pid, ctool, nil, nil, argv, nil)
                                {
                                case 0: 
                                    break 
                                case let code: 
                                    throw ToolError.init(file: file.path.string, 
                                        subtask: .posix_spawn, 
                                        status: code)
                                }
                                var status:Int32 = 0
                                switch waitpid(pid, &status, 0)
                                {
                                case pid: 
                                    break 
                                case let code:
                                    throw ToolError.init(file: file.path.string, 
                                        subtask: .waitpid, 
                                        status: code)
                                }
                                guard status == 0 
                                else 
                                {
                                    throw ToolError.init(file: file.path.string, 
                                        subtask: .factory, 
                                        status: status)
                                }
                            }
                        }
                    }

                default: 
                    continue 
                }
            }
        }
    }
}