import SwiftSyntaxParser 
import SwiftSyntax 

public 
enum Factory 
{
    public static 
    func transform(syntax source:SourceFileSyntax) throws -> SourceFileSyntax 
    {
        let transformer:Transformer = .init()
        let output:SourceFileSyntax = transformer.visit(source)
        if let error:any Error = transformer.errors.first 
        {
            throw error 
        }
        else 
        {
            return output
        }
    }
    public static 
    func transform(source:String, filenameForDiagnostics:String = "") throws -> String
    {
        let source:SourceFileSyntax = try SyntaxParser.parse(source: source, 
            filenameForDiagnostics: filenameForDiagnostics)
        return try Self.transform(syntax: source).description
    }
}