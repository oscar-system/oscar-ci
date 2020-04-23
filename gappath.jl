using GAP
try
  print(GAP.gap_exe())
catch
  print(normpath(joinpath(dirname(Base.find_package("GAP")), "../gap.sh")))
end

