" ============================================================================
"    Copyright: Copyright (C) 2007,2016 Michael Hofmann
"               Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. Like anything else that's free,
"               errormarker.vim is provided *as is* and comes with no
"               warranty of any kind, either expressed or implied. In no
"               event will the copyright holder be liable for any damages
"               resulting from the use of this software.
" Name Of File: errormarker.vim
"  Description: Sets markers for compile errors
"   Maintainer: Michael Hofmann (mh21 at mh21 dot de)
"      Version: See g:loaded_errormarker for version number.
"        Usage: Normally, this file should reside in the plugins
"               directory and be automatically sourced. If not, you must
"               manually source this file using ':source errormarker.vim'.

" === Support for automatic retrieval (Vim script 642) ===================

" GetLatestVimScripts: 1861 1 :AutoInstall: errormarker.vim



" === Initialization =====================================================

" Exit when the Vim version is too old or missing some features
if v:version < 700 || !has("signs") || !has("autocmd")
    finish
endif

" Exit quickly when the script has already been loaded or when 'compatible'
" is set.
if exists("g:loaded_errormarker") || &compatible
    finish
endif

" Version number.
let g:loaded_errormarker = "0.2.2"

let s:save_cpo = &cpo
set cpo&vim

command ErrorAtCursor call s:ShowErrorAtCursor()
command RemoveErrorMarkers call s:RemoveErrorMarkers()

function! s:DefineVariable(name, default)
    if !exists(a:name)
        execute 'let ' . a:name . ' = "' . escape(a:default, '\"') . '"'
    endif
endfunction


" === Variables ==========================================================

let s:iconpath = expand("<sfile>:h:h") . "/icons/"

" Defines the icon to show for errors in the gui
call s:DefineVariable("g:errormarker_erroricon", s:iconpath . "error.ico")

" Defines the icon to show for warnings in the gui
call s:DefineVariable("g:errormarker_warningicon", s:iconpath . "warning.ico")

" Defines the icon to show for infos in the gui
call s:DefineVariable("g:errormarker_infoicon", s:iconpath . "info.ico")

" Defines the text (two characters) to show in the gui
call s:DefineVariable("g:errormarker_errortext", "EE")
call s:DefineVariable("g:errormarker_warningtext", "WW")
call s:DefineVariable("g:errormarker_infotext", "II")

" Defines the highlighting group to use in the gui
call s:DefineVariable("g:errormarker_errorgroup", "ErrorMsg")
call s:DefineVariable("g:errormarker_warninggroup", "Todo")
call s:DefineVariable("g:errormarker_infogroup", "Todo")

" Defines the highlighting group to use for the marker in the gui
call s:DefineVariable("g:errormarker_errortextgroup", "ErrorMsg")
call s:DefineVariable("g:errormarker_warningtextgroup", "Todo")
call s:DefineVariable("g:errormarker_infotextgroup", "Todo")

" Defines the error types that should be treated as warning
call s:DefineVariable("g:errormarker_warningtypes", "wW")

" Defines the error types that should be treated as info
call s:DefineVariable("g:errormarker_infotypes", "iI")



" === Global =============================================================

" Define the signs
let s:erroricon = ""
if filereadable(g:errormarker_erroricon)
    let s:erroricon = " icon=" . escape(g:errormarker_erroricon, '| \')
endif
let s:warningicon = ""
if filereadable(g:errormarker_warningicon)
    let s:warningicon = " icon=" . escape(g:errormarker_warningicon, '| \')
endif
let s:infoicon = ""
if filereadable(g:errormarker_infoicon)
    let s:infoicon = " icon=" . escape(g:errormarker_infoicon, '| \')
endif

execute "sign define errormarker_error text=" . g:errormarker_errortext .
            \ " linehl=" . g:errormarker_errorgroup .
            \ " texthl=" . g:errormarker_errortextgroup .
            \ s:erroricon

execute "sign define errormarker_warning text=" . g:errormarker_warningtext .
            \ " linehl=" . g:errormarker_warninggroup .
            \ " texthl=" . g:errormarker_warningtextgroup .
            \ s:warningicon

execute "sign define errormarker_info text=" . g:errormarker_infotext .
            \ " linehl=" . g:errormarker_infogroup .
            \ " texthl=" . g:errormarker_infotextgroup .
            \ s:infoicon


let s:positions = {}

" Setup the autocommands
augroup errormarker
    autocmd QuickFixCmdPost make call <SID>SetErrorMarkers()
augroup END


" === Functions ==========================================================

function! s:ShowErrorAtCursor()
    let [l:bufnr, l:lnum] = getpos(".")[0:1]
    let l:bufnr = bufnr("%")
    for l:d in getqflist()
        if (l:d.bufnr != l:bufnr || l:d.lnum != l:lnum)
            continue
        endif
        redraw | echomsg l:d.text
    endfor
    echo
endfunction

function! s:RemoveErrorMarkers()
    for l:key in keys(s:positions)
        execute ":sign unplace " . l:key
    endfor

    let s:positions = {}

    if !has('gui_running')
        redraw!
    endif
endfunction

function! s:SetErrorMarkers()
    if has ('balloon_eval')
        let &balloonexpr = "<SNR>" . s:SID() . "_ErrorMessageBalloons()"
        set ballooneval
    endif

    for l:key in keys(s:positions)
        execute ":sign unplace " . l:key
    endfor

    let s:positions = {}
    for l:d in getqflist()
        if (l:d.bufnr == 0 || l:d.lnum == 0)
            continue
        endif

        let l:key = l:d.bufnr . l:d.lnum
        if has_key(s:positions, l:key)
            continue
        endif
        let s:positions[l:key] = 1

        let l:name = "errormarker_error"
        if strlen(l:d.type)
            if stridx(g:errormarker_warningtypes, l:d.type) >= 0
                let l:name = "errormarker_warning"
            elseif stridx(g:errormarker_infotypes, l:d.type) >= 0
                let l:name = "errormarker_info"
            endif
        endif
        execute ":sign place " . l:key . " line=" . l:d.lnum . " name=" .
                    \ l:name . " buffer=" . l:d.bufnr
    endfor

    if !has('gui_running')
        redraw!
    endif
endfunction

function! s:ErrorMessageBalloons()
    for l:d in getqflist()
        if (d.bufnr == v:beval_bufnr && d.lnum == v:beval_lnum)
            return l:d.text
        endif
    endfor
    return ""
endfunction

function! s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction


" === Cleanup ============================================================

let &cpo = s:save_cpo

finish
