using Documenter, StructLH

makedocs(
    modules = [StructLH],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    checkdocs = :exports,
    sitename = "StructLH.jl",
    pages = Any["index.md"]
)

# deploydocs(
#     repo = "github.com/hendri54/StructLH.jl.git",
# )
