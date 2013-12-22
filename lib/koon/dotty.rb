require 'koon/download_strategy'
require 'koon/exceptions'
require 'yaml'
require 'ostruct'

class DottyUtils
  def self.deactivate dotty_name, argv
    dotty = Dotty.new dotty_name, ARGV.shift
    dotty.deactivate!
  end

  def self.fetch uri, argv
    downloader = DownloadStrategyDetector.detect(uri).new(uri)
    if downloader.target_folder.exist?
      raise "Dotty already installed"
    end
    downloader.fetch
  end

  def self.remove dotty_name, argv
    ohai "Removing"
    dotty = Dotty.new dotty_name, false
    if !dotty.is_active?
      FileUtils.rm_rf dotty.path
      ohai "Successfully removed"
    else
      ofail "Cannot remove active kit, deactivate first"
    end
  end

  def self.uninstall dotty_name, argv
    dotty = Dotty.new dotty_name, ARGV.shift
    dotty.deactivate!
    ohai "Uninstalling"
    self.remove dotty_name, argv
    dotty.after_uninstall
  end

  def self.install uri, argv
    downloader = DownloadStrategyDetector.detect(uri).new(uri)
    if downloader.target_folder.exist?
      raise "Dotty already installed"
    end
    downloader.fetch
    dotty = Dotty.new downloader.name, ARGV.shift
    dotty.activate!
    dotty.after_install
  end

  def self.activate dotty_name, argv
    dotty = Dotty.new dotty_name, ARGV.shift
    dotty.activate!
  end

  def self.update dotty_name, argv
    dotty = Dotty.new dotty_name, false
    opoo "Only dotties installed via git can be updated - but trying anyway"
    updater = GitUpdateStrategy.new dotty_name
    updater.update
    dotty.read_facts!
    dotty.after_update
  end

end

class Facts
  def initialize location
    @location = Pathname.new(location)
    @facts_file = @location + "dotty.yml"
    raise RuntimeError.new "No dotty file found in #@location" unless @facts_file.exist?
    @facts = YAML.load @facts_file.read
    @_facts = YAML.load @facts_file.read
  end

  def config_files
    @facts["config_files"].flatten.map do |file|
      @location + file
    end
  end

  def has_flavors?
    !@_facts["flavors"].nil?
  end

  def flavors
    @_facts["flavors"].keys
  end

  def flavor! which_flavor
    raise RuntimeError.new "Flavor '#{which_flavor}' does not exist -> #{flavors.join(', ')} - use: zimt <command> <kit-uri> <flavor>" unless flavors.include? which_flavor
    @facts = @_facts["flavors"][which_flavor]
  end

  def post hook_point
    if !@facts.key? "post"
      []
    else
      post_hook = @facts["post"]
      (post_hook[hook_point.to_s] || []).flatten
    end
  end
end

class Dotty

  attr_reader :name, :facts, :path

  def after_install
     @path.cd do
       ENV["CURRENT_DOTTY"] = @path
       facts.post(:install).each do |cmd|
         safe_system cmd
       end
     end
  end

  def after_update
     @path.cd do
       ENV["CURRENT_DOTTY"] = @path
       facts.post(:update).each do |cmd|
         system cmd
       end
     end
  end

  def after_uninstall
     @path.cd do
       ENV["CURRENT_DOTTY"] = @path
       facts.post(:uninstall).each do |cmd|
         system cmd
       end
     end
  end

  def initialize name, flavor=nil
    require 'cmd/list'
    raise "Dotty #{name} is not installed (#{Koon.installed_dotties})" unless Koon.installed_dotties.include? name
    @path = KOON_DOTTIES/name
    @flavor = flavor
    read_facts!
  end

  def is_installed?
    @path.exist?
  end

  def is_active?
    # move parts of this into the koon lib itself
    home_dir = ENV["HOME"]
    installed_dotties = Dir.foreach(home_dir).map do |filename|
      File.readlink File.join(home_dir, filename) if File.symlink? File.join(home_dir, filename)
    end.compact.uniq.map do |path|
      Pathname.new File.dirname(path)
    end.uniq
    if installed_dotties.length == 1
      installed_dotties[0] == @path
    elsif installed_dotties.length == 0
      false
    else
      raise "there is more than one active dotty - which is not supported ATM"
    end
  end

  def read_facts!
    @facts = Facts.new @path
    if @facts.has_flavors? && @flavor.nil?
      raise RuntimeError.new FlavorArgumentMsg % @facts.flavors.join("\n- ")
    elsif @facts.has_flavors? && @flavor != false
      @facts.flavor! @flavor
    end
  end

  def deactivate!
    ohai "Deactivating"
    files = @facts.config_files
    home_dir = ENV["HOME"]
    files.each do |file|
      pn = Pathname.new file
      FileUtils.rm_f File.join(home_dir, "." + pn.basename)
    end
  end

  def activate!
    raise AlreadyActiveError.new if is_active?
    ohai "Activating"
    files = @facts.config_files
    home_dir = ENV["HOME"]
    files.each do |file|
      # if ends in erb -> generate it
      pn = Pathname.new file
      FileUtils.ln_s file, File.join(home_dir, "." + pn.basename)
    end
  end
end
