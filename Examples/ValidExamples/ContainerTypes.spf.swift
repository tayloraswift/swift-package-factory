

enum Variant 
{
    func `as`(_:Int.Type = Int.self) -> Int?
    {
        nil 
    }
    func `as`(_:Int?.Type = Int?.self) -> Int??
    {
        nil 
    }
    func `as`(_:[Int].Type = [Int].self) -> [Int]?
    {
        nil 
    }
    func `as`(_:[Int: Int].Type = [Int: Int].self) -> [Int: Int]?
    {
        nil 
    }
    func `as`(_:(Int, Int).Type = (Int, Int).self) -> (Int, Int)?
    {
        nil 
    }
    func `as`(_:((Int, Int) throws -> Int).Type = ((Int, Int) throws -> Int).self) -> ((Int, Int) throws -> Int)?
    {
        nil 
    }
}