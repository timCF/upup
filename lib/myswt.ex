defmodule Upup.Myswt do
	use Silverb, [
		{"@imgregexp", ~r/^http\:\/\/cs\d+\.vk\.me/}
	]
	require Myswt
	Myswt.callback_module do
		#
		#	TODO
		#
	end
end
