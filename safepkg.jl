module SafePkg
  include("packages.jl")

  using Pkg

  @enum Mode stable master

  global mode = stable

  function set_mode(m)
    global mode
    mode = m
  end

  localpath(p) = "$(ENV["WORKSPACE"])/$(p).jl"

  Master(name) = get(locations, name, PackageSpec(path=localpath(name)))
  Stable(name) = get(locations, name, PackageSpec(name=name))
  GetPackageSpec(name) = mode == stable ? Stable(name) : Master(name)

  global pkglog = ".pkgerrors"

  function LogPkgErr(err, name = nothing)
    try
      msg = replace(replace(replace(err.msg,
	r"├|└" => "+"), r"─" => "-"), r"│" => "|")
      open(pkglog, "a") do fp
	if name !== nothing
	  write(fp, string("=== failed to add package ", name, "\n"))
	end
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
    Safe(()->Pkg.add(GetPackageSpec(name));
         onerror = err -> LogPkgErr(err, name))
  end

  function add(pkg)
    if startswith(pkg, "https:")
      pkg = PackageSpec(url=pkg)
    elseif startswith(pkg, "/")
      pkg = PackageSpec(path=pkg)
    end
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
