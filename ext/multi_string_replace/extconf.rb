require 'mkmf'

# Optional: allow users to tweak optimization flags
base_opt = '-O3 -fno-strict-aliasing'
optflags = ENV['MSR_OPTFLAGS'] || base_opt
optflags += ' -march=native' if ENV['MSR_NATIVE'] == '1'

with_cflags(optflags) do
	# avoid treating warnings as errors across diverse compilers
	with_werror(false) do
		create_header
		create_makefile 'multi_string_replace/multi_string_replace'
	end
end