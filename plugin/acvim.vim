nnoremap <F5> :call RunSolution()<cr>
nnoremap <F7> :cexpr system('compile')<cr>:botright copen<cr>
nnoremap <F9> :!executor<cr>
nnoremap <leader>at :!addtest<cr>
nnoremap <leader>io :call ToggleIO()<cr>

let s:io_is_open = 0
function! ToggleIO()
    if s:io_is_open
        bdelete in
        bdelete out
        let s:io_is_open = 0
    else
        let s:io_is_open = 1
        let l:cur_window = winnr()
        botright 10 split in
        rightbelow vsplit out
        setlocal autoread
        execute l:cur_window . "wincmd w"
    endif
endfunction

function! FindRedirectedFile(code, type)
    let l:matches = matchlist(a:code,
                \ '\vfreopen\(\s*"([^;]*)"\s*,[^;]*,\s*' . a:type . '\)')
    if !empty(l:matches[1])
        return substitute(l:matches[1], '\v"\s*"', '', 'g')
    else
        return ''
    endif
endfunction

function! FindIONames()
    let l:source_name = bufname('*.cpp')
    let l:preprocessed = system('g++ -E ' . expand(l:source_name))
    return [FindRedirectedFile(l:preprocessed, 'stdin')
        \ , FindRedirectedFile(l:preprocessed, 'stdout')]
endfunction

function! RunSolution()
    let [l:input_file, l:output_file] = FindIONames()
    if !empty(l:input_file)
        execute 'silent !cp in ' . l:input_file
    endif
    !runsolution
    if !empty(l:input_file)
        execute 'silent !rm ' . l:input_file
    endif
    if !empty(l:output_file)
        execute 'silent !mv ' . l:output_file ' out'
        let l:out_window = bufwinnr('out')
        if l:out_window != -1
            let l:cur_window = winnr()
            execute l:out_window . "wincmd w"
            edit!
            execute l:cur_window . "wincmd w"
        endif
    endif
endfunction