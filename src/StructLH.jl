module StructLH

using ArgCheck, DocStringExtensions

export retrieve_property, has_property, retrieve_child_property
export merge_object_arrays!, reduce_object_vector


"""
	$(SIGNATURES)

Retrieve a property from an object or its child objects.
If the property is not unique, returns the first match and then stops.
Returns `nothing` if not found.
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

Retrieve a property in a child object of a given name.
Does not retrieve property from object itself.
This helps when properties are not unique.
"""
function retrieve_child_property(o, childName :: Symbol, pName :: Symbol)
    # First retrieve the child
    child = retrieve_property(o, childName);
    @assert !isnothing(child)  "Cannot find $childName"
    return retrieve_property(child, pName)
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

`reduceFct` takes a vector of numeric inputs and returns a single numeric output that is of compatible size and type so it can be written back into an instance of the objects contained in `oVecV`.

To handle `Nan` or `missing`, make sure that `reduceFct` appropriately handles or skips them.

Optional input `fieldTypes` indicates which non-numeric field types to use as well.

Limitation: Because the output object is of the same type as the input objects in `oVecV`, it is not possible to apply `reduceFct` that returns a different type from its inputs. For example, `mean` of integers does not work.
"""
function reduce_object_vector(oVecV :: Vector{T1},  reduceFct :: Function;
    fieldTypes :: Vector = []) where T1

    # Allocate output object
    oOut = deepcopy(oVecV[1]);
    # Loop over numeric fields
    pnV = propertynames(oOut);
    for pn in pnV
        xM = reduce_one_field(oVecV, pn, reduceFct; fieldTypes = fieldTypes);
        if !isnothing(xM)
            setfield!(oOut, pn, xM);
        end
    end
    return oOut
end


# Apply `reduceFct` to one field in a vector of objects.
# Returns `nothing` if reduction not possible.
function reduce_one_field(oVecV :: Vector{T1},  pn,  reduceFct :: Function;
    fieldTypes :: Vector = []) where T1

    n = length(oVecV);
    fieldM = getfield(oVecV[1], pn);
    fType = typeof(fieldM);
    xM = nothing;

    if (fType <: AbstractFloat)  ||  (fType ∈ fieldTypes)
        # Scalar field
        if hasmethod(reduceFct, (Vector{fType},))
            xM = reduceFct([getfield(oVecV[iObj], pn) for iObj = 1 : n]);
        end

    elseif isa(fieldM, Array)  &&  (eltype(fieldM) <: AbstractFloat)
        # Array field
        if hasmethod(reduceFct, (Vector{eltype(fieldM)},))
            xM = similar(fieldM);
            # Loop over elements in the field
            for j = 1 : length(xM)
                xM[j] = reduceFct([getfield(oVecV[iObj], pn)[j] for iObj = 1 : n]);
            end
            @assert size(xM) == size(fieldM)  "Size mismatch: $(size(xM)) vs $(size(fieldM))"
        end
    end

    if !isnothing(xM)
        # Result can only be used if the resulting object matches `fieldM`
        @argcheck (typeof(xM) == fType)
        if hasmethod(size, (fType,))
            @argcheck (size(xM) == size(fieldM))
        end
    end
    return xM
end



"""
    merge_object_arrays!

Merge all arrays (and vectors) from object `oSource` into the corresponding arrays
in another object `oTg` (at given index values `idxV`).
If target does not have corresponding field: behavior is governed by `skipMissingFields`.

# Arguments
- idxV
    `Vector{Integer}` or other iterable with integer results. Indexes the first dimension of each object to be copied.
    The assignment is: `oSource.x[i1,:] => oTg.x[idxV[i1],:]`.
"""
function merge_object_arrays!(oSource, oTg, idxV,
    skipMissingFields :: Bool; dbg :: Bool = false)

    nameV = fieldnames(typeof(oSource));
    for name in nameV
        xSrc = getfield(oSource, name);
        if isa(xSrc,  Array)
            # Does target have this field?
            if isdefined(oTg, name)
                xTg = getfield(oTg, name);
                if dbg
                    @assert size(xSrc, 1) == length(idxV)
                    @assert size(xSrc)[2:end] == size(xTg)[2:end] "Size mismatch: $(size(xSrc)) vs $(size(xTg))"
                end
                # The n-dim array code also works for Vectors, but is less efficient.
                if isa(xSrc, Vector)
                    xTg[idxV] .= xSrc;
                elseif isa(xSrc, Matrix)
                    xTg[idxV, :] .= xSrc;
                else
                    # For multidimensional arrays (we don't know the dimensions!)
                    # we need to loop over "rows". This is expensive.
                    for (i1, idx) in enumerate(idxV)
                        # This selects target "row" `idx`
                        tgView = selectdim(xTg, 1, idx);
                        # Copy source "row" `i1` into target row (in place, hence [:])
                        tgView[:] = selectdim(xSrc, 1, i1);
                    end
                end
            elseif !skipMissingFields
                error("Missing field $name in target object")
            end
        end
    end
    return nothing
end



end # module
