using GAP
pkgpath =
  GAP.EvalString("List(DirectoriesLibrary(\"pkg\"), d->Filename(d, \"\"))")
home = string(normpath(joinpath(ENV["HOME"], ".gap")), "/")
for path in GAP.gap_to_julia(pkgpath)
  if !startswith(path, home)
    print(path)
    exit(0)
  end
end
exit(1)
