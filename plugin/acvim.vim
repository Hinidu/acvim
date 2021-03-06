nnoremap <F5> :call RunSolution()<cr>
nnoremap <F7> :call Compile(0)<cr>
nnoremap <F9> :call RunExecutor()<cr>
nnoremap <leader>at :!addtest<cr>
nnoremap <leader>io :call ToggleIO()<cr>

let s:io_is_open = 0
function! ToggleIO()
    if s:io_is_open
        bunload in
        bunload out
        let s:io_is_open = 0
    else
        let s:io_is_open = 1
        let l:cur_window = winnr()
        botright 12 split in
        rightbelow vsplit out
        setlocal autoread
        execute l:cur_window . "wincmd w"
    endif
endfunction

function! FindRedirectedFile(code, type)
    let l:matches = matchlist(a:code,
                \ '\vfreopen\(\s*"([^;]*)"\s*,[^;]*,\s*' . a:type . '\)')
    if len(l:matches) > 0 && !empty(l:matches[1])
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

function! Compile(silent)
    wall
    cgetexpr system('compile ' . bufname('*.cpp'))
    if len(getqflist())
        botright copen
        return 0
    else
        cclose
        if !a:silent
            echom 'Successful compilation!'
        endif
    endif
    return 1
endfunction

function! RunSolution()
    call Compile(1)
    wall
    let [l:input_file, l:output_file] = FindIONames()
    if !empty(l:input_file)
        execute 'silent !cp in ' . l:input_file
    endif
    execute '!runsolution ' . substitute(bufname('*.cpp'), '\v\.cpp$', '', 'g')
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

function! RunExecutor()
    let l:files = FindIONames()
    execute 'silent !echo INPUT_NAME=' . l:files[0] ' > .acmrc'
    execute 'silent !echo OUTPUT_NAME=' . l:files[1] ' >> .acmrc'
    !executor
endfunction
