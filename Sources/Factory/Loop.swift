import SwiftSyntax 

struct Loop:RandomAccessCollection 
{
    struct Thread 
    {
        let binding:String 
        let basis:[ExprSyntax]
    }

    let threads:[Thread]
    let endIndex:Int
    var startIndex:Int { 0 }

    subscript(index:Int) -> [String: ExprSyntax]
    {
        var element:[String: ExprSyntax] = .init(minimumCapacity: self.threads.count)
        for thread:Thread in self.threads 
        {
            element[thread.binding] = thread.basis[index]
        }
        return element
    }

    private 
    init(_ threads:[Thread])
    {
        self.threads = threads 
        self.endIndex = self.threads.lazy.map(\.basis.count).min() ?? 0
    }

    init(parsing arguments:TupleExprElementListSyntax, scope:[[String: [ExprSyntax]]]) throws
    {
        var zipper:[Loop.Thread] = []
        arguments:
        for argument:TupleExprElementSyntax in arguments 
        {
            guard case .identifier(let binding)? = argument.label?.tokenKind
            else 
            {
                throw Factory.MatrixError.missingBinding
            }
            if      let literal:ArrayExprSyntax = 
                argument.expression.as(ArrayExprSyntax.self)
            {
                zipper.append(.init(binding: binding, 
                    basis: literal.elements.map { $0.expression.withoutTrivia() }))
            }
            else if let variable:IdentifierExprSyntax = 
                argument.expression.as(IdentifierExprSyntax.self)
            {
                let variable:String = variable.identifier.text
                for scope:[String: [ExprSyntax]] in scope.reversed() 
                {
                    if let basis:[ExprSyntax] = scope[variable]
                    {
                        zipper.append(.init(binding: binding, basis: basis))
                        continue arguments  
                    }
                }
                throw Factory.MatrixError.undefinedBasis(variable)
            }
            else 
            {
                throw Factory.MatrixError.invalidBasis(for: binding)
            }
        }
        self.init(zipper)
    }
}