{
  lib,
  pkgs,
  ...
}:
{
  programs.vim =
    let
      commonConfig = {
        enable = true;
        defaultEditor = true;

        # Plugins that have some additional config are configured in an
        # later, with the plugin and the config kept together in a semi-modular
        # fashion.
        plugins = with pkgs.vimPlugins; [
          jq-vim
          plantuml-syntax
          vim-nix
          vim-openscad
          # TODO: make vimtex conditional on whether latexmk is installed, since
          # the plugin complains when opening a LaTeX file if it can't find
          # latexmk.
          vimtex
        ];
      };

      # TODO Work out where to organise this, or whether I can just remove it
      # thanks to having https://github.com/tpope/vim-sensible present by
      # default.
      configToReview = {
        extraConfig = ''
          " Stop using vi-compatible settings!
          set nocompatible

          " Keep using the current indent level when starting a new line.
          set autoindent

          " Make backspace useful.
          set backspace=indent,eol,start

          " Always have a status line and the current position in the file.
          set laststatus=2
          set ruler

          " Always have some context above and below the cursor.
          set scrolloff=3

          " Show details of selected text when selecting it.
          set showcmd

          " Use incremental search.
          set incsearch

          " Tab completion of Vim commands.
          set wildmenu
          set wildmode=longest,list

          " Put the relative line number in the margin, with the current line
          " listed with its current line number.
          set number
          set relativenumber
          highlight LineNr ctermfg=gray

          " Default shell syntax, per `:help ft-sh-syntax`
          let g:is_bash = 1

          " Allow toggling between relative numbers and absolute line numbers by
          " pressing ^N.
          function! NumberToggle()
            if(&relativenumber == 1)
              set norelativenumber
              set number
              highlight LineNr ctermfg=darkgray
            else
              set relativenumber
              highlight LineNr ctermfg=gray
            endif
          endfunc
          nnoremap <C-n> :call NumberToggle()<CR>

          " Show whitespace in a useful fashion.  Note this disables the
          " `linebreak` setting, so to `set linebreak` you'll also need to `set
          " nolist`.
          set list listchars=tab:\ \ ,trail:-

          " When entering a bracket, show its partner.
          set showmatch

          " Insert the comment leader when hitting Enter within a comment in
          " Insert mode, or when hitting o/O in Normal mode.
          set formatoptions+=r formatoptions+=o

          " Syntax higlighting is big and clever.
          syntax enable

          " In LaTeX files, don't spell check comments.
          let g:tex_comment_nospell=1

          " If using the spell checker, we're writing in British English.
          set spelllang=en_gb

          " Set features that only work in Vim 7.4 or higher.
          if version >= 704
            " Have the value of shiftwidth follow that of tabstop, and the value
            " of softtabstop follow shiftwidth.
            set shiftwidth=0
            set softtabstop=-1
          endif

          " Search for selected text, forwards or backwards (taken from
          " <http://vim.wikia.com/wiki/Search_for_visually_selected_text>).
          vnoremap <silent> * :<C-U>
            \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
            \gvy/<C-R><C-R>=substitute(
            \escape(@", '/\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
            \gV:call setreg('"', old_reg, old_regtype)<CR>
          vnoremap <silent> # :<C-U>
            \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
            \gvy?<C-R><C-R>=substitute(
            \escape(@", '?\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
            \gV:call setreg('"', old_reg, old_regtype)<CR>
        '';
      };

      rainbowConfig = {
        # The USP of this plugin, at least last time I checked, is that it would
        # also colour things like if/then blocks in shell scripts.
        #
        # Enable it by default, and disable shell error checking, because I find
        # it reports errors that aren't.
        plugins = [ pkgs.vimPlugins.rainbow ];
        extraConfig = ''
          let g:rainbow_active = 1
          let g:sh_no_error = 1
        '';
      };
    in
    lib.mkMerge [
      commonConfig
      configToReview
      rainbowConfig
    ];
}
