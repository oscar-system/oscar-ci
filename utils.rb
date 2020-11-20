require "fileutils"

module FileUtils
  def rm_tree(path)
    chmod_R("u=rwx", path, force: true)
    rm_rf(path)
  end
  def atomic_write(file, data)
    File.write(file+".tmp", data)
    FileUtils.mv(file+".tmp", file, force: true)
  end
  module_function :rm_tree, :atomic_write
end

