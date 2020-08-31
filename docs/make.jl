using Documenter, StructLH, FilesLH

makedocs(
    modules = [StructLH],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    checkdocs = :exports,
    sitename = "StructLH.jl",
    pages = Any["index.md"]
)

pkgDir = rstrip(normpath(@__DIR__, ".."), '/');
@assert endswith(pkgDir, "StructLH")
deploy_docs(pkgDir; trialRun = false);

# deploydocs(
#     repo = "github.com/hendri54/StructLH.jl.git",
# )
