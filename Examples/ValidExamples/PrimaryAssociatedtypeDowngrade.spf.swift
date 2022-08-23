
#if swift(>=5.7)
/// This is an evolving protocol with a primary 
/// associatedtype.
protocol EvolvingProtocolA<Element, Index>
{
    associatedtype Element 
    associatedtype Index:Strideable

    init()
}
#else 
/// This is an evolving protocol with a primary 
/// associatedtype.
protocol EvolvingProtocolA
{
    associatedtype Element 
    associatedtype Index:Strideable

    init()
}
#endif 
#if swift(>=5.7)
/// This is an evolving protocol with a primary 
/// associatedtype.
protocol EvolvingProtocolB<Element, Index>
{
    associatedtype Element 
    associatedtype Index:Strideable

    init()
}
#else 
/// This is an evolving protocol with a primary 
/// associatedtype.
protocol EvolvingProtocolB
{
    associatedtype Element 
    associatedtype Index:Strideable

    init()
}
#endif 
#if swift(>=5.7)
/// Another example.
protocol AnotherProtocol<Wrapped>
{
    associatedtype Wrapped
    associatedtype Projection
}
#else 
/// Another example.
protocol AnotherProtocol
{
    associatedtype Wrapped
    associatedtype Projection
}
#endif 
