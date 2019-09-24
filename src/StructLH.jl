module StructLH

using ArgCheck, DocStringExtensions

export retrieve_property, has_property
export reduce_object_vector


"""
	$(SIGNATURES)

Retrieve a property from an object or its child objects.
"""
function retrieve_property(o, pName :: Symbol)
    if isdefined(o, pName)
        outVal = getproperty(o, pName);
    else
        outVal = nothing;
        pn = propertynames(o);
        for propName in pn
            outVal = retrieve_property(getproperty(o, propName), pName);
            if !isnothing(outVal)
                break;
            end
        end
    end
    return outVal
end


"""
	$(SIGNATURES)

Does object or a child object have a property?
"""
function has_property(o, pName :: Symbol)
    return !isnothing(retrieve_property(o, pName))
end


"""
	$(SIGNATURES)

Given a vector of mutable structs, compute a function of all numeric fields.

Example use case: Compute the mean and standard deviation of simulated model statistics.

`reduceFct` takes a vector of numeric inputs and returns a single numeric output that is of compatible size and type so it can be written back into an instance of the objects contained in `oVecV`

Optional input `fieldTypes` indicates which non-numeric field types to use as well.
"""
function reduce_object_vector(oVecV :: Vector{T1},  reduceFct :: Function;
    fieldTypes :: Vector = []) where T1
    # Allocate output object
    oOut = deepcopy(oVecV[1]);
    n = length(oVecV);

    # Loop over numeric fields
    pnV = propertynames(oOut);
    for pn in pnV
        fieldM = getfield(oVecV[1], pn);
        fType = typeof(fieldM);

        if fType <: AbstractFloat
            # Scalar field
            if hasmethod(reduceFct, (Vector{fType},))
                xM = reduceFct([getfield(oVecV[iObj], pn) for iObj = 1 : n]);
                @assert typeof(xM) == fType
                setfield!(oOut, pn, xM);
            end

        elseif isa(fieldM, Array)  &&  (eltype(fieldM) <: AbstractFloat)
            # Array field
            if hasmethod(reduceFct, (Vector{eltype(fieldM)},))
                xM = similar(fieldM);
                # Loop over elements in the field
                for j = 1 : length(xM)
                    xM[j] = reduceFct([getfield(oVecV[iObj], pn)[j] for iObj = 1 : n]);
                end
                @assert typeof(xM) == fType
                @assert size(xM) == size(fieldM)  "Size mismatch: $(size(xM)) vs $(size(fieldM))"
                setfield!(oOut, pn, xM);
            end

        elseif fType ∈ fieldTypes
            # Try to call `reduceFct` on vector of fields
            @assert hasmethod(reduceFct, (Vector{fType},))
            xM = reduceFct([getfield(oVecV[iObj], pn) for iObj = 1 : n]);
            # Result can only be used if the resulting object matches `fieldM`
            @argcheck (typeof(xM) == fType)
            if hasmethod(size, (fType,))
                @argcheck (size(xM) == size(fieldM))
            end
            setfield!(oOut, pn, xM);
        end
    end

    return oOut
end

end # module
