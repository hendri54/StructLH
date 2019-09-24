using StructLH
using Test

struct RTP2
    r1
    r2
end

struct RTP3
    r4
    r2
end

struct RTP1
    x :: RTP2
    y :: RTP3
end

mutable struct ROV
    x
    y
    z
end

function string_sum(sV :: Vector{String})
    outStr = "";
    for s in sV
        outStr = outStr * s;
    end
    return outStr
end


@testset "StructLH" begin
    @testset "Retrieve property" begin
        x = RTP2(1, 2);
        y = RTP3(4, 5);
        z = RTP1(x, y);

        @test has_property(z, :r1)
        @test !has_property(z, :r12)
        r1 = retrieve_property(z, :r1);
        @test r1 == x.r1
        r2 = retrieve_property(z, :r2);
        @test r2 == x.r2
        r3 = retrieve_property(z, :r3);
        @test isnothing(r3)
        r4 = retrieve_property(z, :x);
        @test isa(r4, RTP2)
    end

    @testset "Reduce object vector" begin
        rov1 = ROV(rand(3,2), 1.23, "a");
        rov2 = ROV(rand(3,2), 3.2, "b");
        rov3 = ROV(rand(3,2), 0.6, "c");
        objV = [rov1, rov2, rov3];
        oOut = reduce_object_vector(objV, sum);

        @test oOut.y ≈ rov1.y .+ rov2.y .+ rov3.y
        @test oOut.x ≈ rov1.x .+ rov2.x .+ rov3.x

        oOut2 = reduce_object_vector(objV, string_sum, fieldTypes = [String]);
        @test oOut2.z == "abc"
    end
end

# ---------------
