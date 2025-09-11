require 'mkmf'

# Optional: allow users to tweak optimization flags
optflags = ENV['MSR_OPTFLAGS'] || '-O3 -fno-strict-aliasing'
warnflags = ENV['MSR_WARNFLAGS']

with_cflags(optflags) do
	# avoid treating warnings as errors across diverse compilers
	with_werror(false) do
		create_header
		create_makefile 'multi_string_replace/multi_string_replace'
	end
end