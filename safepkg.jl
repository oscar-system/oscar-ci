module SafePkg
  include("packages.jl")

  using Pkg

  build_type = get(ENV, "BUILDTYPE", "master")

  Master(name) = PackageSpec(path=string(name, ".jl"))
  Stable(name) = get(locations, name, PackageSpec(name=name))
  GetPackageSpec(name) = build_type == "master" ? Master(name) : Stable(name)

  function LogPkgErr(err)
    msg = replace(replace(replace(err.msg,
      r"├|└" => "+"), r"─" => "-"), r"│" => "|")
    try
      open(pkglog, "a") do fp
	write(fp, string("=== failed to add package ", name, "\n"))
	write(fp, string(msg, "\n"))
      end
    catch
      # ignore IO errors
    end
  end

  function Safe(action; onerror = nothing)
    try
      action()
    catch err
      if onerror !== nothing
	onerror(err)
      end
      for (exception, backtrace) in Base.catch_stack()
	showerror(stdout, exception, backtrace)
	println()
      end
    end
  end

  function add_smart(name)
    Safe(()->Pkg.add(GetPackageSpec(name)); onerror = err -> LogPkgErr(err))
  end

  function add(pkg)
    Safe(()->Pkg.add(pkg))
  end

  function build(name)
    Safe(()->Pkg.build(name))
  end

  function precompile()
    Safe(()->Pkg.precompile(); onerror = err ->LogPkgErr(err))
  end

  function update()
    Safe(()->Pkg.update())
  end

end
