## -----------  struct2dict

"""
	$(SIGNATURES)

Struct that contains information about one node in the `Dict` created by `struct2dict`.
"""
struct NodeInfo
    type :: DataType
    size
    value
end

Base.isequal(n1 :: NodeInfo, n2 :: NodeInfo) = 
    (n1.type == n2.type)  &&  (n1.size == n2.size)  &&  (n1.value == n2.value);

"""
	$(SIGNATURES)

Convert a `struct` to a nested `Dict`. Known leaf types, such as strings, arrays become `NodeInfo` entries in the `Dict`. `struct`s become their own `Dict`s.

The purpose is to convert a `struct` into a `Dict` of simple "built-in" types that can be serialized. Each leaf entry contains information about the `DataType` of the leaf, so that the object can be reconstructed. In case the data are saved to a format that does not preserve size information, the size of the object is also saved.
"""
function struct2dict(s)
    d = Dict{Symbol, Any}();
    for pName in propertynames(s)
        d[pName] = struct2dict(getproperty(s, pName));
    end
    return d
end

scalar2dict(s) = NodeInfo(typeof(s), nothing, s);
struct2dict(s :: Number) = scalar2dict(s);
struct2dict(s :: AbstractString) = scalar2dict(s);
struct2dict(s :: Symbol) = scalar2dict(s);
struct2dict(s :: Dict) = scalar2dict(s);

array2dict(s :: AbstractArray{T}) where T = NodeInfo(typeof(s), size(s), s);
struct2dict(s :: AbstractArray{F1}) where F1 <: Number = array2dict(s);
struct2dict(s :: AbstractArray{F1}) where F1 <: AbstractString = array2dict(s);
struct2dict(s :: AbstractArray{F1}) where F1 <: Symbol = array2dict(s);

# ---------------