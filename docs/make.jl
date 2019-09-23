using Documenter, StructLH

makedocs(
    modules = [StructLH],
    format = :html,
    checkdocs = :exports,
    sitename = "StructLH.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/hendri54/StructLH.jl.git",
)
