<div align="center">
  
***`factory`***<br>`0.1.0`

</div>

**`factory`** is a structured, type-safe source generation tool. It is intended to be a replacement for (and improvement over) the `gyb` tool!

## Overview 

`factory` was designed with the following goals in mind:

1.  Template files should look like normal `.swift` files, so highlighters and IDEs don’t freak out. 

2.  Templates should be **safe**, and prohibit arbitrary string splicing or token substitutions.

3.  Templates should work well with documentation comments.

4.  Template syntax should be minimal, purely additive, and source generation tooling should accept and return vanilla `.swift` sources unchanged.

5.  Template users should be able to use as much or as little templating as they like, and using templating on one declaration should not increase the cognitive burden of the rest of the code in the file.

6.  Templating systems should nudge users towards using **the least amount of templating necessary** for their use-case.

7.  Template sources should be self-explanatory, and understandable by developers who have never heard of `swift-package-factory`.

In a nutshell: 

> [`Basic.spf`](Examples/ValidExamples/Basic.spf)
```swift 
extension Int
{
    @matrix(__ordinal__: [i, j, k], __value__: [0, 1, 2])
    @inlinable public 
    var __ordinal__:Int 
    {
        __value__
    }

    @basis 
    let cases:[Never] = [a, b]

    enum Cases:Int
    {
        @matrix(__case__: cases)
        case __case__
    }

    @matrix(__case__: cases)
    public static 
    var __case__:Self 
    {
        Cases.__case__.rawValue
    }
}
```

> [`Basic.spf.swift`](Examples/ValidExamples/Basic.spf.swift)
```swift 
extension Int
{
    @inlinable public 
    var i:Int 
    {
        0
    }
    @inlinable public 
    var j:Int 
    {
        1
    }
    @inlinable public 
    var k:Int 
    {
        2
    }

    enum Cases:Int
    {
        case a
        case b
    }

    public static 
    var a:Self 
    {
        Cases.a.rawValue
    }

    public static 
    var b:Self 
    {
        Cases.b.rawValue
    }
}
```

## Getting started 

Check out the [`Examples`](Examples/) directory to learn how to use SPF!