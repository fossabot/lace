require 'koon/dotty'
require 'koon/exceptions'

module Koon extend self
	def install
		resource = ARGV.shift
		raise ResourceNotSpecified if not resource
		DottyUtils.install resource, ARGV
	end
end
