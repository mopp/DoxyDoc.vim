"=============================================================================
" File: DoxyDoc.vim
" Author: mopp
" Created: 2014-01-18
"=============================================================================
scriptencoding utf-8

if !exists('g:loaded_DoxyDoc')
    runtime! plugin/DoxyDoc.vim
endif
let g:loaded_DoxyDoc = 1

let s:save_cpo = &cpo
set cpo&vim

"-----------------------------------------------------------------------------------------
" Initialize
"-----------------------------------------------------------------------------------------
let g:doxydoc_block_style = get(g:, 'doxydoc_block_style', 'JavaDoc')
let g:doxydoc_is_insert_inter_comment = get(g:, 'doxydoc_is_insert_inter_comment ', 1)
let g:doxydoc_command_prefix = get(g:, 'doxydoc_command_prefix ', '@')
let g:doxydoc_date_format = get(g:, 'doxydoc_date_format ', '%Y-%m-%d')

if g:doxydoc_block_style == 'JavaDoc'
    let s:start_comment = '/**'
    let s:inter_comment = (g:doxydoc_is_insert_inter_comment != 0) ? ' * ' : '  '
    let s:end_comment = ' */'
elseif g:doxydoc_block_style == 'Qt'
    " TODO:
elseif g:doxydoc_block_style == 'C++'
    " TODO:
else
    throw "DoxyDoc ERROR: g:doxydoc_block_style is invalid."
endif

let s:command_author    = g:doxydoc_command_prefix . 'author '
let s:command_brief     = g:doxydoc_command_prefix . 'brief '
let s:command_date      = g:doxydoc_command_prefix . 'date '
let s:command_file      = g:doxydoc_command_prefix . 'file '
let s:command_version   = g:doxydoc_command_prefix . 'version '
let s:command_param     = g:doxydoc_command_prefix . 'param '
let s:command_return    = g:doxydoc_command_prefix . 'return '
let s:is_change = 0

let s:key_lrule_constructor = 'constructor'
let s:key_lrule_argument    = 'argument'
let s:key_lrule_function    = 'function'
let s:key_lrule_junk        = 'junk'
" if &filetype == 'c' || &filetype == 'cpp'
    " match word or word with * or word with [] or word with &
    let s:any_word_pattern = '\w\+\(::\w\+\)\=\s*\(&\|\*\|\[.*\]\)\='
    let s:lexer_rule = [
                \ [ s:key_lrule_constructor,  '\s*' . s:any_word_pattern . '\s*('],
                \ [ s:key_lrule_argument,     '\(\s*' . s:any_word_pattern . '\s*\)\+\(,\|).*\)'],
                \ [ s:key_lrule_function,     '\s*' . s:any_word_pattern . '\s\+' . s:any_word_pattern . '\s*' ],
                \ [ s:key_lrule_junk,         '\((\|).*\)' ], ]
" endif
let V = vital#of('DoxyDoc.vim')
let s:lexer = V.import('Text.Lexer').lexer(s:lexer_rule)
let s:data_string = V.import('Data.String')


"-----------------------------------------------------------------------------------------
" Local functions
"-----------------------------------------------------------------------------------------

" change and store user setting option.
function! s:change_vim_option()
    " already store option.
    if s:is_change != 0
        return
    endif
    let s:is_change = 1

    " does autoload of neobundle cause change option ?
    " so, it load lazed plugin at this.
    silent execute 'normal! i'

    let s:save_comments = &comments
    let &comments = ''
    let s:save_cinoptions = &cinoptions
    let &cinoptions = 'c1C1'
    let s:save_timeoutlen = &timeoutlen
    let &timeoutlen = 0
    let s:save_cindent = &cindent
    let &cindent = 0
    let s:save_autoindent = &autoindent
    let &autoindent = 0
    let s:save_smartindent = &smartindent
    let &smartindent = 0
    let s:save_formatoptions = &formatoptions
    let &formatoptions = ''
endfunction


" restore user setting option.
function! s:restore_vim_option()
    let &comments = s:save_comments
    let &cinoptions = s:save_cinoptions
    let &timeoutlen = s:save_timeoutlen
    let &formatoptions = s:save_formatoptions
    let &smartindent = s:save_smartindent
    let &cindent = s:save_cindent
    let &autoindent = s:save_autoindent
    let s:is_change = 0
endfunction


" add start comment block of doxygen.
function! s:add_document_start()
    silent execute 'normal! O' . s:start_comment
endfunction


" add start comment block of doxygen.
function! s:add_document_end()
    silent execute 'normal! o' . s:end_comment
endfunction


" delete matched string and return list splited by space
function! s:clean_split(str, exp)
    let subs = substitute(a:str, a:exp, '', 'g')
    return split(subs, '\s')
endfunction


" return function parameter
function! s:get_function_info(str)
    let infos = s:lexer.exec(a:str)

    " clean
    call filter(infos, 'v:val.label !=# "junk"')

    let new_infos = []
    for i in infos
        let new_i = {}
        let new_i.raw_str = i.matched_text
        let new_i.raw_str = s:data_string.trim(new_i.raw_str)
        let label = i.label

        if label == s:key_lrule_argument
            let new_i.label = s:key_lrule_argument
            let new_i.str = substitute(i.matched_text, ',\s*$\|).*$', '', 'g')
            let new_i.str = substitute(new_i.str, '\s*\[.*\]\+\s*$', '', 'g')
        elseif label == s:key_lrule_function
            let new_i.label = s:key_lrule_function
            let new_i.str = substitute(i.matched_text, ').*$', '', 'g')
        elseif label == s:key_lrule_constructor
            let new_i.label = s:key_lrule_constructor
            let new_i.str = substitute(i.matched_text, '($', '', 'g')
        endif

        let new_i.splited = split(new_i.str, '\s')

        call insert(new_infos, new_i)
    endfor

    return new_infos
endfunction



"-----------------------------------------------------------------------------------------
" Global functions
"-----------------------------------------------------------------------------------------
function! DoxyDoc#make_author_comment()
    if !exists('g:doxydoc_author_name')
        let g:doxydoc_author_name = input('Please input name of the author : ')
    endif

    if !exists('b:doxydoc_version')
        let b:doxydoc_version = input('Please input version : ')
    endif

    call s:change_vim_option()

    call s:add_document_start()

    let insert_cmd = 'normal! o' . s:inter_comment

    let fname = expand('%:t')
    execute insert_cmd . s:command_file . fname
    execute insert_cmd . s:command_brief
    let store_insert_point = line('.')
    execute insert_cmd . s:command_author . g:doxydoc_author_name
    execute insert_cmd . s:command_version . b:doxydoc_version
    execute insert_cmd . s:command_date . strftime(g:doxydoc_date_format)

    call s:add_document_end()
    call s:restore_vim_option()

    call cursor(store_insert_point, 0)
    startinsert!
endfunction


function! DoxyDoc#make_function_comment()
    let line = getline('.')
    let info = s:get_function_info(line)

    call s:change_vim_option()
    call s:add_document_start()

    let insert_cmd = 'normal! o' . s:inter_comment

    execute insert_cmd . s:command_brief
    let store_insert_point = line('.')

    for i in info
        if i.label == s:key_lrule_argument
            " add param
            execute insert_cmd . s:command_param i.splited[len(i.splited) - 1]
        elseif i.label == s:key_lrule_function && i.splited[0] != 'void'
            " add return
            execute insert_cmd . s:command_return
        endif
    endfor

    call s:add_document_end()
    call s:restore_vim_option()

    call cursor(store_insert_point, 0)
    startinsert!
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
