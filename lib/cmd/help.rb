HELP = <<-EOS
Example usage:
  Synopsis:
    zimt <cmd> <pkg-uri/name> [<flavor>] [--name=<name>] [--version] [--no-hooks]

  zimt ls

  zimt fetch <pkg-uri>
  zimt fetch <pkg-uri>

  zimt install <pkg-uri>
  zimt install <pkg-uri> <flavor>

  zimt activate <pkg-name>
  zimt activate <pkg-name> <flavor>

  zimt deactivate <pkg-name>
  zimt deactivate <pkg-name> <flavor>

  zimt remove <pkg-name>
  zimt update <pkg-name>

Troubleshooting:
  zimt help
  zimt info <pkg-name>
  zimt validate <local-directory>

For further help visit:
  https://github.com/kairichard/zimt
EOS

module Koon extend self
  def help
    puts HELP
  end
  def help_s
    HELP
  end
end
