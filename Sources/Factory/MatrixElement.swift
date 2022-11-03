import SwiftSyntax
import SwiftSyntaxBuilder

protocol MatrixElement:DeclSyntaxProtocol 
{
    var attributes:AttributeListSyntax? { get set }
}
extension AssociatedtypeDeclSyntax:MatrixElement {}
extension ClassDeclSyntax:MatrixElement {}
extension EnumCaseDeclSyntax:MatrixElement {}
extension EnumDeclSyntax:MatrixElement {}
extension ExtensionDeclSyntax:MatrixElement {}
extension FunctionDeclSyntax:MatrixElement {}
extension ImportDeclSyntax:MatrixElement {}
extension InitializerDeclSyntax:MatrixElement {}
extension OperatorDeclSyntax:MatrixElement {}
extension PrecedenceGroupDeclSyntax:MatrixElement {}
extension ProtocolDeclSyntax:MatrixElement {}
extension StructDeclSyntax:MatrixElement {}
extension SubscriptDeclSyntax:MatrixElement {}
extension TypealiasDeclSyntax:MatrixElement {}
extension VariableDeclSyntax:MatrixElement {}

extension MatrixElement 
{
    private 
    func matrixExpanded(_ loops:ArraySlice<Loop>, substitutions:[[String: ExprSyntax]]) 
        throws -> [DeclSyntax]
    {
        if let loop:Loop = loops.first 
        {
            var instances:[DeclSyntax] = []
            for iteration:[String: ExprSyntax] in loop 
            {
                instances.append(contentsOf: try self.matrixExpanded(loops.dropFirst(), 
                    substitutions: substitutions + [iteration]))
            }
            return instances
        }
        else 
        {
            let instantiator:Instantiator = .init(substitutions)
            let declaration:DeclSyntax 
            switch self 
            {
            case let base as AssociatedtypeDeclSyntax:  declaration = instantiator.visit(base)
            case let base as ClassDeclSyntax:           declaration = instantiator.visit(base)
            case let base as EnumCaseDeclSyntax:        declaration = instantiator.visit(base)
            case let base as EnumDeclSyntax:            declaration = instantiator.visit(base)
            case let base as ExtensionDeclSyntax:       declaration = instantiator.visit(base)
            case let base as FunctionDeclSyntax:        declaration = instantiator.visit(base)
            case let base as ImportDeclSyntax:          declaration = instantiator.visit(base)
            case let base as InitializerDeclSyntax:     declaration = instantiator.visit(base)
            case let base as OperatorDeclSyntax:        declaration = instantiator.visit(base)
            case let base as PrecedenceGroupDeclSyntax: declaration = instantiator.visit(base)
            case let base as ProtocolDeclSyntax:        declaration = instantiator.visit(base)
            case let base as StructDeclSyntax:          declaration = instantiator.visit(base)
            case let base as SubscriptDeclSyntax:       declaration = instantiator.visit(base)
            case let base as TypealiasDeclSyntax:       declaration = instantiator.visit(base)
            case let base as VariableDeclSyntax:        declaration = instantiator.visit(base)
            default: 
                fatalError("unreachable")
            }
            if let error:any Error = instantiator.errors.first 
            {
                throw error
            }
            return [declaration]
        }
    }
    mutating 
    func removeAttributes<Recognized>(
        where recognize:(AttributeListSyntax.Element) throws -> Recognized?) 
        rethrows -> [Recognized]?
    {
        guard let attributes:AttributeListSyntax = self.attributes 
        else 
        {
            return nil 
        }
        var removed:[Recognized] = []
        // if we delete a node, its leading trivia should coalesce with the 
        // leading trivia of the next node 
        var kept:[AttributeListSyntax.Element] = []
        var doccomment:Trivia? = nil
        for attribute:AttributeListSyntax.Element in attributes 
        {
            if let recognized:Recognized = try recognize(attribute) 
            {
                // if this would be the first attribute, save the leading trivia, 
                // as it may contain a doccomment!
                if  case nil = doccomment, kept.isEmpty, 
                    let trivia:Trivia = attribute.leadingTrivia
                {
                    doccomment = trivia
                }
                removed.append(recognized)
            }
            else if let saved:Trivia = doccomment
            {
                // this *discards* the attribute’s *own* leading trivia!
                // if we do not throw it away, the preceding doccomment
                // will be orphaned, which is even worse!
                kept.append(attribute.withLeadingTrivia(saved))
                doccomment = nil
            }
            else 
            {
                kept.append(attribute)
            }
        }
        if removed.isEmpty 
        {
            return nil 
        }
        else
        {
            self.attributes = kept.isEmpty ? nil : .init(kept)
        }
        // need to check this again, in case there were no other attributes 
        // around to adopt the doccomment
        if let doccomment:Trivia
        {
            // this *discards* the declaration’s *own* leading trivia!
            // if we do not throw it away, the preceding doccomment
            // will be orphaned, which is even worse!
            self = self.withLeadingTrivia(doccomment)
        }
        return removed
    }
    func expanded(scope:[[String: [ExprSyntax]]]) throws -> [DeclSyntax]
    {
        var template:Self = self 
        let retro:[Void]? = try template.removeAttributes 
        {
            guard   case .customAttribute(let attribute) = $0, 
                    case "retro"? = attribute.simpleName
            else 
            {
                return nil 
            }
            if case _? = attribute.argumentList 
            {
                throw Factory.RetroError.unexpectedArguments
            }
            else 
            {
                return ()
            }
        }
        let loops:[Loop]? = try template.removeAttributes 
        {
            guard   case .customAttribute(let attribute) = $0,
                    case "matrix"? = attribute.simpleName
            else 
            {
                return nil 
            }
            if let arguments:TupleExprElementListSyntax = attribute.argumentList
            {
                return try .init(parsing: arguments, scope: scope)
            }
            else 
            {
                throw Factory.MatrixError.missingArguments
            }
        }

        var declarations:[DeclSyntax] 
        if let loops:[Loop]
        {
            declarations = try template.matrixExpanded(loops[...], substitutions: [])
        }
        else 
        {
            declarations = [.init(template)]
        }
        if case _? = retro
        {
            // ensure that *every* declaration starts with a newline
            declarations.prependMissingNewlines()
            declarations = try declarations.retroExpanded()
        }
        else if declarations.count > 1 
        {
            // ensure that *ever* declaration after the first one 
            // starts with a newline 
            declarations[1...].prependMissingNewlines()
        }

        return declarations
    }
}
extension Sequence<DeclSyntax> 
{
    func retroExpanded() throws -> [DeclSyntax]
    {
        try self.map 
        {
            (declaration:DeclSyntax) in 

            guard let declaration:ProtocolDeclSyntax = declaration.as(ProtocolDeclSyntax.self)
            else 
            {
                throw Factory.RetroError.expectedProtocol
            }
            guard case _? = declaration.primaryAssociatedTypeClause 
            else 
            {
                throw Factory.RetroError.expectedPrimaryAssociatedTypeClause
            }

            let modern:IfConfigClauseSyntax = .init(
                poundKeyword: .poundIfKeyword(
                    leadingTrivia: .newlines(1), 
                    trailingTrivia: .spaces(1)), 
                condition: .init(FunctionCallExprSyntax.init(
                    calledExpression: .init(IdentifierExprSyntax.init(
                        identifier: .identifier("swift"), 
                        declNameArguments: nil)), 
                    leftParen: .leftParenToken(), 
                    argumentList: .init(
                    [
                        .init(label: nil, colon: nil, 
                            expression: .init(PrefixOperatorExprSyntax.init(
                                operatorToken: .prefixOperator(">="), 
                                postfixExpression: .init(FloatLiteralExprSyntax.init(
                                    floatingDigits: .floatingLiteral("5.7"))))), 
                            trailingComma: nil)
                    ]), 
                    rightParen: .rightParenToken(), 
                    trailingClosure: nil, 
                    additionalTrailingClosures: nil)), 
                elements: .decls(
                [
                    .init(decl: declaration)
                ]))
            let retro:IfConfigClauseSyntax = .init(
                poundKeyword: .poundElseKeyword(leadingTrivia: .newlines(1)), 
                condition: nil, 
                elements: .decls(
                [
                    .init(decl: declaration.withPrimaryAssociatedTypeClause(nil))
                ]))
            let block:IfConfigDeclSyntax = .init(
                clauses: .init([modern, retro]), 
                poundEndif: .poundEndifKeyword(leadingTrivia: .newlines(1)))

            return .init(block)
        }
    }
}
extension MutableCollection<DeclSyntax> 
{
    mutating 
    func prependMissingNewlines() 
    {
        for index:Index in self.indices
        {
            guard let before:Trivia = self[index].leadingTrivia 
            else 
            {
                self[index] = self[index].withLeadingTrivia(.newlines(1))
                continue 
            }
            guard case true? = before.first?.isLinebreak
            else 
            {
                self[index] = self[index].withLeadingTrivia(.init(
                    pieces: [.newlines(1)] + before))
                continue
            }
        }
    }
}
