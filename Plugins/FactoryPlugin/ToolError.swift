public
struct ToolError:Error 
{
    public
    enum Subtask:String 
    {
        case posix_spawn = "posix_spawn"
        case waitpid = "waitpid" 
        case factory = "swift-package-factory"
    }

    public
    let file:String
    public 
    let subtask:Subtask 
    public 
    let status:Int32
}
extension ToolError:CustomStringConvertible
{
    public 
    var description:String 
    {
        "failed to transform file '\(self.file)' (\(self.subtask.rawValue) exited with code \(self.status))"
    }
}
