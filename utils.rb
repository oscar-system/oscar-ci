require "fileutils"

module FileUtils
  def rm_tree(path)
    chmod_R("u=rwx", path, force: true)
    rm_rf(path)
  end
  module_function :rm_tree
end
