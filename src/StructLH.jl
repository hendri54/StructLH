module StructLH

using ArgCheck, DocStringExtensions

export @common_fields
export retrieve_property, has_property, retrieve_child_property
export merge_object_arrays!, reduce_object_vector
export ApplyFctResult, apply_fct_to_object, obj_name, obj_type, fct_value, children
export describe, describe_object, show_description
export NodeInfo, struct2dict, dict2struct!

include("helpers.jl");
include("retrieve.jl")
include("reduce.jl");
include("struct2dict.jl")
include("traverse_object.jl")

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

    nameV = propertynames(oSource);
    for name in nameV
        xSrc = getproperty(oSource, name);
        if isa(xSrc,  Array)
            # Does target have this field?
            if hasproperty(oTg, name)
                xTg = getproperty(oTg, name);
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
