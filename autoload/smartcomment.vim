if !exists("g:smartcomment_loaded")
	let g:smartcomment_loaded = 0
endif

if g:smartcomment_loaded == 0
	autocmd BufReadPost,FileType,Syntax,EncodingChanged * call ParseComments()
endif
let g:smartcomment_loaded = 1
