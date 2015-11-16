function obj = retrieve(format, filepath)
	switch format
		case 'antelope', retrieve_antelope(filepath)
		case 'seisan', retrieve_seisan(filepath)
		case 'hypoellipse', retrieve_hypoellipse(filepath)
	end
end
