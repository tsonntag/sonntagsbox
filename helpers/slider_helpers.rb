module SliderHelpers

	def slider id, min, max, value, opts = {}
		tag :input, :id => id, :type => 'text',
		  'data-slider-min'   => min,
			'data-slider-max'   => max, 
		  'data-slider-step'  => opts[:step]||1,
			'data-slider-value' => value.to_s,
	    'data-slider-selection'   => opts[:selection]||"after", 
		  'data-slider-orientation' => opts[:orientation]||'horizontal'
	end
end
