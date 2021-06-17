" ============================================================================
" File:        notebook.vim
" Description: Vim plugin to annotate text, source code, etc.
" Author:      Walter Di Carlo
" Licence:     Vim licence
" Website:     https://github.com/wdicarlo/vim-notebook
" Version:     0.2
" Note:        
" Changes:
"    2012/08/09 version 0.1:
"         * initial release
"    2013/08/18 version 0.2
"         * added support for relative reference to files
" TODO:
"   * add support for multiple sub-projects
" ============================================================================
scriptencoding utf-8

if &cp || exists('s:nb_loaded')
    finish
endif

if v:version < 700
    echohl ErrorMsg
    echomsg 'Notebook: Vim version is too old, Notebook requires at least 7.0'
    echohl None
    finish
endif

let s:nb_loaded="loaded"
let s:nb_context=3
let s:nb_folder=$HOME.'/.notebook'
let s:nb_config=$HOME.'/.notebook/notebook.rc'
let s:nb_items = sort(['Text', 'Action', 'Query', 'Session', 'Patch', 'Import', 'List' ])
let s:nb_mode = 0 " partial mode
let s:nb_root_hook = "NOTEBOOK_ROOT"

function! NB_FindRoot(dir)
    let root=a:dir
    if match(a:dir, "/$")
        let root=substitute(a:dir,"/$","","")
    endif
    let root_files = [ '.svn', '.git', '.notebook_root' ]
    for root_file in root_files
        let s:nb_root = root."/".root_file
        if isdirectory(s:nb_root) > 0 
            let s:nb_root = substitute(s:nb_root,"/".root_file,"","")
            break
        endif
        let s:nb_root = finddir( root_file, root.";")
        if isdirectory(s:nb_root) > 0 
            let s:nb_root = substitute(s:nb_root,"/".root_file,"","")
            break
        endif
    endfor
    if s:nb_root == ""
        let s:nb_root = root
    else
        let s:nb_mode = 1 " full mode
    endif
    return s:nb_root
endfunction
function! NB_PrintRoot()
    echomsg "Notebook Root: ".s:nb_root
    if s:nb_mode == 0
        echohl WarningMsg
        echomsg "WARNING: Partial mode - references to files cannot be annotated"
        echohl None
    endif
endfunction
function! NB_GetRootPath(dir)
    return substitute( a:dir, s:nb_root, "$".s:nb_root_hook, "")
endfunction
function! NB_GetFullPath(dir)
    return substitute( a:dir,  "$".s:nb_root_hook, s:nb_root, "")
endfunction

call NB_FindRoot(expand(getcwd(),":p"))

function! NB_Listfiles(dir)
  if isdirectory(a:dir) == 0
    return
  endif
  let fnm = "*.nb"
  let files = filter(split(globpath(a:dir, fnm), '\n'), '!isdirectory(v:val)')
  if len(files) == 0
    return
  endif
  let list=[]
  let i = 1
  for fp in files
    call add(list, fnamemodify(l:fp,":t"))
    let i=i+1
  endfor 
  return list
endfunction
function! NB_InitMarks ()
  redraw!
  let l:title=input("Notebook Title? ")
  let l:note=input("Notebook Description? ")
  exec ":redir! > ".s:nb_file
  :echo "\nNote: ".l:title 
  :echo "\t: Category:  NOTEBOOK" 
  :echo "\t: Reference: text"
  :echo "\t\t; ".l:note
  :echo "\t\t; "
  :redir END
endfunction
function! NB_UpdateConfig()
  exec ":redir! > ".s:nb_config
  :echo "\" notebook.vim configuration file"
  :echo "\" "
  :echo "let g:nb_notebook = \"".g:nb_notebook."\""
  :echo "let g:nb_categories = ".string(g:nb_categories)
  :redir END
endfunction
function! NB_InitNotebook( notebook )
  let g:nb_notebook=a:notebook
  let s:nb_filename=g:nb_notebook.'.nb'
  let s:nb_file = s:nb_folder.'/'.s:nb_filename
  if filereadable(s:nb_file) == 0
    call NB_InitMarks()
  endif
endfunction
function! NB_GetIndexString( idx )
      let index = "".a:idx
      if len(index) < 2
        let index = "  ".index
      elseif len(index) < 3
        let index = " ".index
      endif
      return index
endfunction
function! NB_CreateDefaultNotebook()
  exec ":redir! > ".s:nb_folder."/default.nb"
  :echo "\nNote: default notebook"
  :echo "\t: Category:  NOTEBOOK" 
  :echo "\t: Reference: text"
  :echo "\t\t; "
  :echo "\t\t; "
  :redir END
endfunction
if isdirectory( s:nb_folder ) == 0 
  call mkdir( s:nb_folder, "p" ) 
  silent! call NB_CreateDefaultNotebook()
endif
if filereadable( s:nb_config ) == 0
  let g:nb_notebook = "default"
  let g:nb_categories = [
              \'API', 
              \'ARRAY',
              \'CHECK',
              \'CLASS',
              \'CODE',
              \'COMMENT',
              \'CONDITION',
              \'CONFIGURATION',
              \'CONSTANT',
              \'DEBUG',
              \'DEFINE',
              \'DEFINITION',
              \'DUMMY',
              \'ENUM',
              \'EXAMPLE',
              \'FILE',
              \'FIX',
              \'FUNCTION',
              \'HACK',
              \'INCLUDE',
              \'INFORMATION',
              \'INITIALIZATION',
              \'INTERESTING',
              \'ITEM',
              \'LOG',
              \'LOGGING',
              \'MEMORY',
              \'MESSAGE',
              \'METHOD',
              \'NONE',
              \'NOTE',
              \'STRUCT',
              \'STUDY',
              \'TEMPLATE',
              \'TEST',
              \'TODO',
              \'TYPE',
              \'VARIABLE',
              \'WORKAROUND']
  silent! call NB_UpdateConfig()
endif
if filereadable(s:nb_config)
  exec ":source ".s:nb_config
  if exists("g:nb_notebook")
    "echo "Notebook: ".g:nb_notebook
    call NB_InitNotebook(g:nb_notebook)
  else
    call NB_InitNotebook('default')
  endif
else
  call NB_InitNotebook('default')
endif
if has("autocmd")
    autocmd BufEnter               *.nb set filetype=vo_base
    autocmd WinLeave              *.nb :call NB_Window_Leave()
endif
function! NB_GetNotebooksList()
  let list=[]
  let files = NB_Listfiles(s:nb_folder)
  if len(files) == 0
    return list
  endif
  for file in files
    let notebook= fnamemodify(file,":t:r")
    let list=add(list,notebook)
  endfor
  return list
endfunction
function! NB_CreateMenu( header, list, hasNew )
  let menu = []
  if len(a:list) == 0 
    return menu
  endif
  let i = 0
  if a:hasNew == 1
    let i=i+1
    let menu = insert(menu,"  ".i."  NEW")
  endif
  if len(a:header) > 0 
    let menu = insert(menu, a:header)
  endif
  for item in a:list
    let i=i+1
    let index = "".i
    if len(index) == 1
      let index = "  ".index
    elseif len(index) == 2
      let index = " ".index
    endif
    if item == g:nb_notebook
      let menu=add(menu,index."> ".item)
    else
      let menu=add(menu,index."  ".item)
    endif
  endfor
  return menu
endfunction
function! NB_SelectNotebook()
  let files = NB_Listfiles(s:nb_folder)
  if len(files) == 0
    return
  endif
  let list=['Select Notebook:', '  1  NEW...', '  2  CLONE...']
  let added=3
  let i=added
  for file in files
    let notebook= fnamemodify(file,":t:r")
    let index = NB_GetIndexString(i)
    if notebook == g:nb_notebook
      let list=add(list,index."> ".notebook)
    else
      let list=add(list,index."  ".notebook)
    endif
    let i=i+1
  endfor
  let sel=inputlist(list)
  exec ":redraw!"
  if sel < 1 || sel > len(list)
    return
  endif
  if sel == 1 
    " create new notebook
    let sel_notebook = input("New Notebook? ")
    if sel_notebook ==? ''
      return
    endif
    " TODO: check it does not exist already
  elseif sel == 2
    " clone notebook
    let sel_notebook = input("Cloned Notebook? ")
    if sel_notebook ==? ''
      return
    endif
    let filename=sel_notebook.'.nb'
    let file = s:nb_folder.'/'.filename
    if filereadable(file) == 0
      " clone marks file
      let lines = readfile(s:nb_file)
      let res = writefile(lines,file)
    endif
  else
    let sel_notebook=fnamemodify(get(files,sel-added),":t:r")
    if sel_notebook == g:nb_notebook
      return
    endif
  endif
  " exec shutdown actions
  call NB_ExecActions(1)
  silent! exec ":bd ".s:nb_file
  call NB_InitNotebook(sel_notebook)
  "
  " update the nb_config file
  silent! call NB_UpdateConfig()
  " exec startup actions
  call NB_ExecActions(0)
  call NB_Window_Open()
endfunction
function! NB_OpenNotebook( notebook )
  "echomsg "Current Notebook: ".g:nb_notebook
  "echomsg "Switching to Notebook: ".a:notebook
  if g:nb_notebook == a:notebook
    return
  endif
  " exec shutdown actions
  call NB_ExecActions(1)
  silent! exec ":bd ".s:nb_file

  " create or open the specified notebook
  let g:nb_notebook=a:notebook
  let s:nb_filename=g:nb_notebook.'.nb'
  let s:nb_file = s:nb_folder.'/'.s:nb_filename
  if filereadable(s:nb_file) == 0
    " create new notebook
    let l:title="Notebook for: ".a:notebook
    let l:note=""
    let l:time=strftime("%y_%m_%d_%H_%M")
    exec ":redir! > ".s:nb_file
    :echo "\nNote: ".l:title 
    :echo "\t: Category:  NOTEBOOK" 
    :echo "\t: Reference: text"
    :echo "\t: Date:      ".l:time
    :echo "\t\t; ".l:note
    :echo "\t\t; "
    :redir END
  endif
  " update the nb_config file
  silent! call NB_UpdateConfig()
  " exec startup actions
  call NB_ExecActions(0)
  "call NB_Window_Open()
endfunction
function! NB_SelectCategory( canNew )
  if !exists('g:nb_categories')
      let g:nb_categories =['NONE'] 
    silent! call NB_UpdateConfig()
  endif
  if exists("g:nb_categories")
    let list = ['Item Category?']
    let i=1
    let added=1
    if a:canNew == 1
      let list = add(list, '  1 NEW')
      let i=i+1
      let added=2
    endif
    for cat in g:nb_categories
      let index = NB_GetIndexString(i)
      let list=add(list,"".index." ".cat)
      let i=i+1
    endfor
    echo "Notebook: ".g:nb_notebook
    let sel=inputlist(list)
    echon "" 
    if sel < 1 || sel > len(list)
      return ""
    endif
    if sel == 1 && a:canNew == 1 
      " create a new category
      let l:category=input("New Category: ")
      silent echo
      if l:category ==? '' 
        let l:category=get(g:nb_categories,0)
      else
        " TODO: remove white spaces
        let g:nb_categories = sort(add(g:nb_categories, l:category))
        " update the nb_config file
        silent! call NB_UpdateConfig()
      endif
    else
      let l:category=get(g:nb_categories,sel-added)
    endif
  else
    echom "Please, define the variable g:nb_categories"
    let l:category="NONE"
  endif
  silent echo
  return l:category
endfunction
function! NB_SelectItem()
  let menu_items = ['Select item?']
  let i = 1
  for item in s:nb_items
    let index = NB_GetIndexString(i)
    let menu_items = add( menu_items, index."  ".item )
    let i = i + 1
  endfor
  let sel = inputlist(menu_items)
  if sel < 1 || sel >= len(menu_items)
    return
  endif
  let item = strpart(menu_items[sel],5)
  return item
endfunction
function! NB_ClearMarks ()
  let l:answer=input("Are you sure to delete ALL items about notebook \"".g:nb_notebook."\"? {no/yes} ")
  if l:answer == "yes"
    silent! exec ":bd ".s:nb_file
    silent! call NB_InitMarks()
  endif
endfunction
function! NB_AddMarkLineRef( use_context )
  if s:nb_mode == 0
      echohl WarningMsg
      echomsg "WARNING: Partial mode - references to files cannot be annotated"
      echohl None
      return
  endif
  silent! exec ":bd ".s:nb_file
  if exists('g:loaded_taglist')
    let winnum = bufwinnr(g:TagList_title)
    if winnum == -1
      "exec ":TlistToggle"
    endif
  endif
  let l:id=NB_SelectCategory(1)
  if l:id == ""
    return
  endif
  let l:note=input("Item Note? ")
  let l:time=strftime("%y_%m_%d_%H_%M")
  let l:ref=NB_GetRootPath(expand("%:p"))
  exec ":redir >> ".s:nb_file
  :echo "\nText: ".l:note 
  :echo "\t: Category:  ".l:id 
  :echo "\t: Reference: ".l:ref.':'.line('.')
  :echo "\t: Date:      ".l:time
  if s:nb_context > 0 && a:use_context > 0 
    let nb_linenum = line('.')
    if a:use_context == 1
      let nb_start = line('.') - s:nb_context
      let nb_end = line('.') + s:nb_context
    elseif a:use_context == 2 
      let nb_start = line('.') 
      let nb_end = line('.') + s:nb_context * 2
    endif
    let nb_lines = getline(nb_start,nb_end)
    let l:nb_counter = nb_start
    for nb_line in nb_lines
      if l:nb_counter == nb_linenum
        :echo "\t\t;* ".nb_line 
      else
        :echo "\t\t;  ".nb_line 
      endif
      let l:nb_counter = l:nb_counter + 1
    endfor
  else
    :echo "\t\t;  ".getline (".")
  endif
  :redir END
endfunction                              
function! NB_AddMarkSelLineRef(quick)
  if s:nb_mode == 0
      echohl WarningMsg
      echomsg "WARNING: Partial mode - references to files cannot be annotated"
      echohl None
      return
  endif
  silent! exec ":bd ".s:nb_file
  if exists('g:loaded_taglist')
    let winnum = bufwinnr(g:TagList_title)
    if winnum == -1
      "exec ":TlistToggle"
    endif
  endif
  let sel_text = NB_GetVisual()
  let nb_lines = split(sel_text,"\\n")
  if len(nb_lines) == 0 
    return
  endif
  let l:id="BOOKMARK"
  let l:note=nb_lines[0]
  if a:quick == 0
    let l:id=NB_SelectCategory(1)
    if l:id == ""
      return
    endif
    let l:note=input("Item Note? ")
  endif
  let l:time=strftime("%y_%m_%d_%H_%M")
  let l:ref=NB_GetRootPath(expand("%:p"))
  exec ":redir >> ".s:nb_file
  :echo "\nText: ".l:note 
  :echo "\t: Category:  ".l:id 
  :echo "\t: Reference: ".l:ref.':'.line('.')
  :echo "\t: Date:      ".l:time
  if s:nb_context > 0 && strlen(sel_text) > 0 
    let l:nb_counter = 1
    let l:nb_linenum = 1
    for nb_line in nb_lines
      if l:nb_counter == nb_linenum
        :echo "\t\t; ".nb_line 
      else
        :echo "\t\t; ".nb_line 
      endif
      let l:nb_counter = l:nb_counter + 1
    endfor
  endif
  :redir END
endfunction


function! NB_AddNote()
  silent! exec ":bd ".s:nb_file
  let l:title=input("Note Title? ")
  let l:category='INFORMATION'
  let l:time=strftime("%y_%m_%d_%H_%M")
  " TODO: input multi-line note
  let l:note=input("Note? ")
  exec ":redir >> ".s:nb_file
  echo "\nNote: ".l:title
  :echo "\t: Category:  ".l:category 
  :echo "\t: Reference: text"
  :echo "\t: Date:      ".l:time
  :echo "\t\t; ".l:note 
  :redir END
  call NB_Window_Open()
  exec "normal! G?Note: ".l:title."\<cr>"
  exec "normal! 3j$"
endfunction                              
function! NB_AddImport()
  silent! exec ":bd ".s:nb_file
  let list = NB_GetNotebooksList()
  let default_idx = index(list,'default')
  call remove(list,default_idx)
  let menu = NB_CreateMenu( "Select Notebook to Reference for Import:", list, 0 )
  let sel = inputlist(menu)
  if sel < 1 || sel > len(menu)
    return
  endif
  let notebook = get(list, sel-1)
  let l:title=input("Import Title? [import ".notebook."]")
  if l:title == ""
    let l:title = "import ".notebook
  endif
  let l:category=NB_SelectCategory(1)
  exec ":redir >> ".s:nb_file
  echo "\nImport: ".l:title
  :echo "\t: Category:  ".l:category 
  :echo "\t: Reference: ".notebook.".nb"
  :redir END
  call NB_Window_Open()
endfunction                              
function! NB_AddCScopeQuery(str) 
  " TODO: consider Windows env
  if ! has("cscope") 
    " && filereadable("/usr/bin/cscope")
    echoerr "CScope not supported!!!"
    return
  endif
  silent! exec ":bd ".s:nb_file
  let l:ref=expand("%:p")
  let l:time=strftime("%y_%m_%d_%H_%M")
  :redir  @p
  exec ":cs find e ".a:str
  :redir END
  let l:title=":cs find e ".a:str
  let l:category='CSCOPE'
  let l:note=input("Note? ")
  let sel_text = @p
  exec ":redir >> ".s:nb_file
  echo "\nQuery: ".l:note
  :echo "\t: Category:  ".l:category 
  :echo "\t: Reference: ".l:title 
  :echo "\t: Date:      ".l:time
  if s:nb_context > 0 && strlen(sel_text) > 0 
    let nb_lines = split(sel_text,"\\n")
    let l:nb_counter = 1
    let l:nb_linenum = 1
    for nb_line in nb_lines
      if l:nb_counter > 1 && l:nb_counter < len(nb_lines) - 1
        :echo "\t\t; ".nb_line 
      endif
      let l:nb_counter = l:nb_counter + 1
    endfor
  endif
  :redir END
endfunction
function! NB_AddGlobalQuery(str)
  silent! exec ":bd ".s:nb_file
  let l:ref=expand("%:p")
  let l:time=strftime("%y_%m_%d_%H_%M")
  :redir  @p
  exec ":g/".a:str
  :redir END
  let l:title=":g/".a:str
  let l:category='GLOBAL'
  let l:note=input("Note? ")
  let sel_text = @p
  exec ":redir >> ".s:nb_file
  echo "\nQuery: ".l:note
  :echo "\t: Category:  ".l:category 
  :echo "\t: Reference: ".l:title 
  :echo "\t: Date:      ".l:time
  :echo "\t: Input:     ".l:ref
  if s:nb_context > 0 && strlen(sel_text) > 0 
    let nb_lines = split(sel_text,"\\n")
    let l:nb_counter = 0
    for nb_line in nb_lines
      if l:nb_counter >= 0 && l:nb_counter < len(nb_lines) 
        :echo "\t\t; ".nb_line 
      endif
      let l:nb_counter = l:nb_counter + 1
    endfor
  endif
  :redir END
endfunction
function! NB_AddSession ()
  silent! exec ":bd ".s:nb_file
  for t in range(1, tabpagenr('$'))
    for b in tabpagebuflist(t)
      let path = NB_GetRootPath(fnamemodify(bufname(b),":p"))
      echo path
    endfor
  endfor
  let ans=input("Create a session item for the following files? Write 'yes' to confirm.")
  if ans != "yes"
    return  
  endif
  let l:category=NB_SelectCategory(1)
  if l:category == ""
    return
  endif
  let l:note=input("Item Note? ")
  exec ":redir >> ".s:nb_file
  echo "\nSession: ".l:note
  :echo "\t: Category:  ".l:category 
  :echo "\t: Reference: files"
  for t in range(1, tabpagenr('$'))
    for b in tabpagebuflist(t)
      let path = NB_GetRootPath(fnamemodify(bufname(b),":p"))
      echo "\t\t; ".path
    endfor
  endfor
  redir END
endfunction
function! NB_AddFilePatch()
  silent! exec ":bd ".s:nb_file
  let l:cmd=":!svn diff ".expand("%:p")
  let l:ref=expand("%:p")
  let l:time=strftime("%y_%m_%d_%H_%M")
  :new
  exec ":%!svn diff ".l:ref
  exec ":1,$y p"
  exec ":q!"
  let l:category='PATCH'
  let l:note=input("Note? ")
  let sel_text = @p
  exec ":redir >> ".s:nb_file
  echo "\nPatch: ".l:note
  :echo "\t: Category:  ".l:category 
  :echo "\t: Reference: ".l:cmd 
  :echo "\t: Date:      ".l:time
  if s:nb_context > 0 && strlen(sel_text) > 0 
    let nb_lines = split(sel_text,"\\n")
    let l:nb_counter = 0
    for nb_line in nb_lines
      if l:nb_counter >= 0 && l:nb_counter < len(nb_lines) 
        :echo "\t\t; ".nb_line 
      endif
      let l:nb_counter = l:nb_counter + 1
    endfor
  endif
  :redir END
endfunction 
function! NB_AddPatch()
  silent! exec ":bd ".s:nb_file
  let l:cmd=":!svn diff"
  let l:ref=""
  let l:time=strftime("%y_%m_%d_%H_%M")
  :new
  exec ":%!svn diff"
  exec ":1,$y p"
  exec ":q!"
  let l:category='PATCH'
  let l:note=input("Note? ")
  let sel_text = @p
  exec ":redir >> ".s:nb_file
  echo "\nPatch: ".l:note
  :echo "\t: Category:  ".l:category 
  :echo "\t: Reference: ".l:cmd 
  :echo "\t: Date:      ".l:time
  if s:nb_context > 0 && strlen(sel_text) > 0 
    let nb_lines = split(sel_text,"\\n")
    let l:nb_counter = 0
    for nb_line in nb_lines
      if l:nb_counter >= 0 && l:nb_counter < len(nb_lines) 
        :echo "\t\t; ".nb_line 
      endif
      let l:nb_counter = l:nb_counter + 1
    endfor
  endif
  :redir END
endfunction 
function! NB_GoToQuery ()
  exec "normal! j"
  let line = getline (".")
  let cmd = match(line,'Category:  GLOBAL')
  if cmd >= 0 
    exec "normal! j"
    let line = getline (".")
    let query = strpart( line, match(line, "Reference: ")+len("Reference: ") ) 
    exec ":tabprev"
    redraw!
    let @/ = strpart(query,2)
    exec ":".query
    exec "normal! ggn"
  else
    let cmd = match(line,'Category:  CSCOPE')
    if cmd >= 0 
      exec "normal! j"
      let line = getline (".")
      let query = strpart( line, match(line, "Reference: ")+len("Reference: ") ) 
      exec ":tabprev"
      redraw!
      exec ":".query
    endif
  endif
endfunction
function! NB_GoToSession () 
  let session = getline('.')
  exec "normal! 2j"
  let line = getline (".")
  let cmd = match(line,'Reference: files')
  if cmd >= 0 
    exec "normal! j"
    let line = getline (".")
    let paths = []
    let lnum = line(".")
    while match(line,'^\W*;') >= 0
      let path = strpart( line, match( line, ";" )+2)
      let path = NB_GetFullPath( path )
      let paths = add( paths, path )
      exec "normal! j"
      if line(".") == lnum
        break
      endif
      let lnum = line(".")
      let line = getline (".")
    endwhile
    if len(paths) == 0
      echom "No paths specified for item: ".session
      return
    endif
    echo session
    let menu_session = [ 'Select Session Action:', '1  Switch Session', '2  Join Session' ]
    let l:answer = inputlist(menu_session)
    if l:answer >= 1 && l:answer <= 2
      if l:answer == 1 
        bufdo bwipeout
      endif
      let i = 0
      for path in paths
        if i == 0 
          exec ":e ".path
        else
          exec ":tabnew ".path
        endif
        let i = i + 1
      endfor
      tabnext
    endif
  endif
endfunction
function! NB_GoToMark ()
  let filename = fnamemodify(bufname('%'), ':t')
  let nb_file = fnamemodify(s:nb_file,':t')
  let bn = bufnr('%')
  "exec "normal! zO"
  let line = getline (".")
  " evaluate the current line
  let cmd = match(line,'^\w*:')
  if cmd == -1
    " not at root node, then move to the root node
    exec "normal! ?^\\w*:\<cr>"
    let line = getline (".")
  endif
  let cmd = match(line,'^Text:')
  if cmd == -1
    " found an item which is not Text
      if match(line,'^Query:') >= 0 
        call NB_GoToQuery()
      elseif match(line,'^Session:') >= 0
        call NB_GoToSession()
      elseif match(line,'^Action:') >= 0
        call NB_ExecAction(2)
      endif
    return
  else
    " Text root node, then jump to the referenced location
    " first move the cursor at the begin of the path
    exec "normal! \/Reference: \<cr>"
    exec "normal! ".len("Reference: ")."l"
    exec ":set filetype=c"
    ""exec ":set foldmethod=indent"
    let line = getline(".")
    let loc = strpart( line, match( line, "Reference: ") + len( "Reference: ") ) 
    let loc = substitute( loc, ":", "|", "" )
    let loc = NB_GetFullPath( loc )
    let file = strpart( loc, 0, match( loc, "|")) 
    if filereadable(file)
        exec ":e ".loc
    else
        echohl ErrorMsg 
        echomsg "File not found: ".file
        echomsg "Either the file is missing or"
        if s:nb_mode == 0 
            echomsg "you started vim from an incorrect folder: ".s:nb_root
        else
            echomsg "the notebook root folder may be incorrect: ".s:nb_root
            echomsg "Check if any of the notebook root folders is present in the wrong location"
        endif
        echohl None
        return
    endif
    "exec "normal! gFzz"
    exec ":bd ".bn
  endif
endfunction
function! NB_OpenAndSearch () 
  let l:word = expand("<cword>")
  call NB_Window_Open() 
  :let @/ = l:word
  exe "normal! ggn" |
endfunction
function! NB_ListContext(refresh)
  let nb_loc_filename=g:nb_notebook.'.loc'
  let nb_loc_file = s:nb_folder.'/'.nb_loc_filename
  if filereadable(nb_loc_file) != 0 && a:refresh == 0
      exec ":lfile ".nb_loc_file
      :lopen
      return
  endif
  let s:nb_filename=g:nb_notebook.'.nb'
  let s:nb_file = s:nb_folder.'/'.s:nb_filename
  if filereadable(s:nb_file) != 0
    let lines = readfile(s:nb_file)
    let i = 0
    let locs = []
    for line in lines
      if match(line,'^Text:') >= 0 
        let ref = lines[i+2]
        let loc = strpart( ref, match( ref, "Reference: ") + len( "Reference: ") ) 
        let loc = substitute( loc, ":", "|", "" )
        let cat = lines[i+1]
        let loc = loc."| ".strpart( cat, match(cat, "Category: ")+len("Category: ") ).": ".strpart(line, len("Text: "))  
        let locs = add(locs, loc )
      endif
      let i = i + 1
    endfor
    if len(locs) > 0 
      call writefile( locs, nb_loc_file)
      exec ":lfile ".nb_loc_file
      :lopen
    endif
  endif
endfunction
function! NB_List( str )
  let s:nb_filename=g:nb_notebook.'.nb'
  let s:nb_file = s:nb_folder.'/'.s:nb_filename
  if filereadable(s:nb_file) != 0
    exec "silent :lvimgrep /".a:str."/ ".s:nb_file
    :lopen
  endif
endfunction
function! NB_Grep( str )
  " TODO: cd into .notebook folder to avoid paths in location list
  let nb_files = s:nb_folder.'/*.nb'
  exec "silent :lvimgrep /".a:str."/ ".nb_files
  :lopen
endfunction
function! NB_GrepItems(item)
  " TODO: cd into .notebook folder to avoid paths in location list
  let item = a:item
  if item == ""
    " select item
    let item = NB_SelectItem()
    if item == ""
      return
    endif
  endif
  let nb_files = s:nb_folder.'/*.nb'
  exec "silent :lvimgrep /^".item.":/ ".nb_files
  :lopen
endfunction
function! NB_Global( str )
  call NB_Window_Open()
  :redraw!
  exec ":g/".a:str."/z#.3"
  let @/=a:str
  exec "normal! ggn"
endfunction
function! NB_GlobalCategory(category)
  call NB_Window_Open()
  if a:category == ""
    " select category
    let category = NB_SelectCategory(0)
    if category == ""
      return
    endif
  else
    let category = a:category
  endif
  exec ":g/Category: ".category."/z#.3"
  let @/="Category: ".category
  exec "normal! ggn"
endfunction
function! NB_GlobalItems(type)
  call NB_Window_Open()
  exec ":g/^".a:type.":/z#.3"
  let @/="^".a:type.":"
  exec "normal! ggn"
endfunction
function! NB_SelectQuery(type)
  let s:nb_filename=g:nb_notebook.'.nb'
  let s:nb_file = s:nb_folder.'/'.s:nb_filename
  if filereadable(s:nb_file) == 0 
    return
  endif
  let menu_items = ['Select query for notebook: '.g:nb_notebook]
  let i = 1
  let k = 1
  let lines = readfile(s:nb_file)
  " TODO: sort items
  for line in lines
    if match(line,'^Query:') >= 0 
      let note = strpart( line, len("Query: "))
      let index = NB_GetIndexString(i)
      let line = lines[k+1]
      let item = index." ".strpart(line, match(line, "Reference:")+len("Reference: ") )
      let menu_items = add( menu_items, item )
      let i = i + 1
    endif
    let k = k + 1
  endfor
  if len(menu_items) == 1 
    echom "No queries present in notebook: ".g:nb_notebook
    return
  endif
  let sel = inputlist( menu_items )
  if sel < 1 || sel > len(menu_items)
    return
  endif
  redraw!
  let query = strpart( get(menu_items, sel), 4)
  echo "Query: ".query." ..."
  let cmd = match(query,'^:g')
  if cmd >= 0 
    let @/ = strpart(query,3)
  endif
  exec query
  exec "normal! ggn"
endfunction
function! NB_SelectAction(type)
  let s:nb_filename=g:nb_notebook.'.nb'
  let s:nb_file = s:nb_folder.'/'.s:nb_filename
  if filereadable(s:nb_file) == 0 
    return
  endif
  let menu_items = ['Select action for notebook: '.g:nb_notebook]
  let i = 1
  let k = 1
  let lines = readfile(s:nb_file)
  " TODO: sort items
  for line in lines
    if match(line,'^Action:') >= 0 
      " TODO: skip startup/shutdown actions
      let note = strpart( line, len("Action: "))
      let index = NB_GetIndexString(i)
      " TODO: extract the query from the Reference field
      let line = lines[k+1]
      let item = index." ".strpart(line, match(line, "Reference:")+len("Reference: ") )
      " TODO: ref with command
      " TODO: ref with path to script
      " TODO: vim: desciption for following commands
      let menu_items = add( menu_items, item )
      let i = i + 1
    endif
    let k = k + 1
  endfor
  if len(menu_items) == 1 
    echom "No action present in notebook: ".g:nb_notebook
    return
  endif
  let sel = inputlist( menu_items )
  if sel < 1 || sel > len(menu_items)
    return
  endif
  redraw!
  let query = strpart( get(menu_items, sel), 4)
  echo "Action: ".query." ..."
  echoerr "Feature still under development!!!"
endfunction
function! NB_SelectSession(type)
  let s:nb_filename=g:nb_notebook.'.nb'
  let s:nb_file = s:nb_folder.'/'.s:nb_filename
  if filereadable(s:nb_file) == 0 
    return
  endif
  let menu_items = ['Select session for notebook: '.g:nb_notebook]
  let menu_items_line = [ -1 ]
  let i = 1
  let k = 1
  let lines = readfile(s:nb_file)
  " TODO: sort items
  for line in lines
    if match(line,'^Session:') >= 0 
      " TODO: skip startup/shutdown actions
      let note = strpart( line, len("Session: "))
      let index = NB_GetIndexString(i)
      " TODO: extract the query from the Reference field
      let item = index." ".strpart(line, len("Session: ") )
      let menu_items = add( menu_items, item )
      let menu_items_line = add( menu_items_line, k )
      let i = i + 1
    endif
    let k = k + 1
  endfor
  if len(menu_items) == 1 
    echom "No session present in notebook: ".g:nb_notebook
    return
  endif
  let sel = inputlist( menu_items )
  if sel < 1 || sel > len(menu_items)
    return
  endif
  redraw!
  let query = strpart( get(menu_items, sel), 4)
  echo "Selected Session: ".query
  let i = menu_items_line[sel]+1
  let line = lines[i]
  let cmd = match(line,'Reference: files')
  if cmd >= 0 
    let i = i + 1
    let line = lines[i]
    let paths = []
    while match(line,'^\W*;') >= 0
      let path = strpart( line, match( line, ";" )+2)
      let path = NB_GetRootPath( path )
      let paths = add( paths, path )
      let i = i + 1
      if i >= len(lines) 
        break
      endif
      let line = lines[i]
    endwhile
    if len(paths) == 0
      echom "No paths specified for item: ".session
      return
    endif
    let menu_session = [ 'Select Session Action:', '1  Switch Session', '2  Join Session' ]
    let l:answer = inputlist(menu_session)
    if l:answer >= 1 && l:answer <= 2
      echo "activating selected session..."
      if l:answer == 1 
        bufdo bwipeout
      endif
      let i = 0
      for path in paths
        if i == 0 
          exec "silent! :e ".path
        else
          exec "silent! :tabnew ".path
        endif
        let i = i + 1
      endfor
      tabnext
    endif
  endif
endfunction
function! NB_ImportNotebooks()
  let s:nb_filename=g:nb_notebook.'.nb'
  let s:nb_file = s:nb_folder.'/'.s:nb_filename
  let filename = fnamemodify(bufname('%'), ':t')
  let nb_file = fnamemodify(s:nb_file,':t')
  if filename != l:nb_file
    return
  endif
  call NB_Window_Open()
  exec "normal! gg"
  exec "silent normal! /^Import:\<cr>"
  let start = line(".")
  let line = getline(".")
  while match(line,'^Import:') == 0
    exec "normal! /Reference:\<cr>"
    let line = getline(".")
    let nb = strpart( line, match( line, ": Reference:" )+len(": Reference: "))
    "exec "normal! /^\\w\\+:\<cr>"
    "let end = line(".") - 1
    let end = line(".")
    let n = end - start + 1
    exec "normal! ".start."G".n."dd"
    let pos = line(".")
    if pos == start
      exec "normal! k"
    endif
    let nb_file = s:nb_folder.'/'.nb
    let lines = []
    if filereadable(nb_file) != 0
      let lines = readfile(nb_file)
      exec "silent! :r ".nb_file
    else
      echoerr "Missing Notebook: ".nb
    endif
    if pos < start
      break
    endif
    if len(lines) > 0 
      exec "normal! ".len(lines)."j"
    endif
    exec "silent! normal! /^Import:\<cr>"
    let start = line(".")
    let line = getline(".")
  endwhile
  set readonly
  set nomodified
  set nomodifiable
endfunction
" Window_Open
function! NB_Window_Open()
  call NB_Window_Open_Notebook(g:nb_notebook)
endfunction 
function! NB_Window_Open_Notebook(notebook)
  let filename=a:notebook.'.nb'
  let file = s:nb_folder.'/'.filename
  if filereadable(file) == 0
    echom "Cannot open notebook: ".a:notebook
    return
  endif
  "let p = expand("%:p:h")
  "let s:nb_root = NB_FindRoot(p)
  " If the window is open, jump to it
  let winnum = bufwinnr(file)
  " :exe "! echo winnum=".winnum
  if winnum != -1
    " Jump to the existing window
    if winnr() != winnum
      exe winnum . 'wincmd w'
    endif
    silent exec ":e"
    silent exec ":g/^ *$/d"
    if &modified == 1
      silent exec ":w"
    endif
    set modifiable
    exe ":nmap <buffer> <enter> :call NB_GoToMark ()<CR>"
    exe ":nmap <buffer> q :q<cr><CR>"
    return
  endif
  " Check whether the file is present in any of the tabs.
  " If the file is present in the current tab, then use the
  " current tab.
  let i = 1
  " TODO: check if the file is already in a buffer
  let bnum = bufnr(file)
  "exec "!echo ".bnum
  let file_present_in_tab = 0
  while i <= tabpagenr('$')
    if index(tabpagebuflist(i), bnum) != -1
      let file_present_in_tab = 1
      "exec "!echo ".i
      break
    endif
    let i += 1
  endwhile
  if file_present_in_tab
    " Goto the tab containing the file
    exe 'tabnext ' . i
    silent exec ":e"
    silent exec ":g/^ *$/d"
    if &modified == 1
      silent exec ":w"
    endif
    set modifiable
    exe ":nmap <buffer> <enter> :call NB_GoToMark ()<CR>"
    exe ":nmap <buffer> q :q<cr><CR>"
    return
  endif
  exec ":tabnew ".file
  set modifiable
  set filetype=c
  exec ":set nospell"
  ""exec ":set filetype=vo_base"
  redraw!
  silent exec ":g/^ *$/d"
  if &modified == 1
    silent exec ":w"
  endif
  exe ":nmap <buffer> <enter> :call NB_GoToMark ()<CR>"
    exe ":nmap <buffer> q :q<cr><CR>"
endfunction
function! NB_Window_Close ()
  " If the window is open, jump to it
  let winnum = bufwinnr(s:nb_file)
  if winnum != -1
    " Jump to the existing window
    if winnr() != winnum
      exe winnum . 'wincmd w'
    endif
    close
    exec ":bw ".s:nb_file
    return
  endif
endfunction
function! NB_Window_Leave()
  let s:nb_filename=g:nb_notebook.'.nb'
  let s:nb_file = s:nb_folder.'/'.s:nb_filename
  let filename = fnamemodify(bufname('%'), ':t')
  let nb_file = fnamemodify(s:nb_file,':t')
  if filename != l:nb_file
    return
  endif
  call NB_Window_Close()
endfunction
" TODO: fix the following function
function! NB_LocListMarks (all)
  echoerr "Feature still under development!!!"
  return
  if a:all == 1
    exec ":lfile ".s:nb_file
    exec ":lopen"
  else
    " fill the location list only with the entries with selected category
    call NB_Window_Open()
    let category = NB_SelectCategory(1) " NEW must not be a category
    if category == ""
      return
    endif
    let result = ''
    exec ":redir! > ".s:nb_file.".loc"
    exec ":g/Category: ".category."/z.3"
    :redir END
    exec ":lfile ".s:nb_file.".loc"
    :lopen
  endif
endfunction
function! NB_ViewNotebook ()
  let list = NB_GetNotebooksList()
  let menu = NB_CreateMenu( "Select Notebook to View:", list, 0 )
  let sel = inputlist(menu)
  if sel < 1 || sel > len(menu)
    return
  endif
  let notebook = get(list, sel-1)
  let notebook_file = s:nb_folder.'/'.l:notebook.'.nb'
  if filereadable(notebook_file) == 0
    return
  endif
  " TODO: solve issue causing the notebook
  " to not be displayed if the current
  " windows contains the active
  " notebook
  call NB_Window_Open_Notebook(notebook)
endfunction
function! NB_DeleteNotebook ()
  let list = NB_GetNotebooksList()
  let default_idx = index(list,'default')
  call remove(list,default_idx)
  let menu = NB_CreateMenu( "Select Notebook to Delete:", list, 0 )
  let sel = inputlist(menu)
  if sel < 1 || sel > len(menu)
    return
  endif
  let notebook = get(list, sel-1)
  let notebook_file = s:nb_folder.'/'.l:notebook.'.nb'
  if filereadable(notebook_file) == 0
    return
  endif
  " ask user confirmation
  let l:answer=input("Are you sure to delete the Notebook \"".notebook."\"? {no/yes} ")
  if l:answer == "yes"
    call delete(notebook_file)
    if notebook ==? g:nb_notebook
      call NB_InitNotebook('default')
    endif
  endif
endfunction
function! NB_ArchiveNotebook ()
  let list = NB_GetNotebooksList()
  let default_idx = index(list,'default')
  call remove(list,default_idx)
  let menu = NB_CreateMenu( "Select Notebook to Archive:", list, 0 )
  let sel = inputlist(menu)
  if sel < 1 || sel > len(menu)
    return
  endif
  let notebook = get(list, sel-1)
  let notebook_file = s:nb_folder.'/'.l:notebook.'.nb'
  if filereadable(notebook_file) == 0
    return
  endif
  " ask user confirmation
  let l:answer=input("Are you sure to archive the Notebook \"".notebook."\"? {no/yes} ")
  if l:answer == "yes"
    let notebook_archive = s:nb_folder.'/'.l:notebook.'.nba'
    call rename(notebook_file,notebook_archive)
    if notebook ==? g:nb_notebook
      call NB_InitNotebook('default')
    endif
  endif
endfunction
function! NB_RenameNotebook ()
  let list = NB_GetNotebooksList()
  let default_idx = index(list,'default')
  call remove(list,default_idx)
  let menu = NB_CreateMenu( "Select Notebook to Rename:", list, 0 )
  let sel = inputlist(menu)
  if sel < 1 || sel > len(menu)
    return
  endif
  let notebook = get(list, sel-1)
  let notebook_file = s:nb_folder.'/'.l:notebook.'.nb'
  if filereadable(notebook_file) == 0
    return
  endif
  " ask user confirmation
  let l:name=input("Rename \"".notebook."\" into? ")
  if l:name == ''
    return
  endif
  let l:answer=input("Are you sure to rename the Notebook \"".notebook."\" into \"".l:name."\"? {no/yes} ")
  if l:answer == "yes"
    let new_file=s:nb_folder."/".l:name.".nb"
    call rename(notebook_file,new_file)
    if notebook ==? g:nb_notebook
      call NB_InitNotebook(l:name)
    endif
  endif
endfunction
" Exec actions at ACTION_SCRIPT
function! NB_ExecAction( type )
    exec "normal! j"
    let line = getline (".")
    if match(line,"Category:.*SCRIPT") >= 0 && a:type == 2
        exec "normal! 2j"
        let cmds = []
        let lnum = line(".")
        let line = getline (".")
        while match(line,'^\W*;') >= 0
            let cmd = strpart( line, match( line, ";" )+2)
            let cmds = add( cmds, cmd )
            exec "normal! j"
            if line(".") == lnum
                break
            endif
            let lnum = line(".")
            let line = getline (".")
        endwhile
        if len(cmds) == 0
            echom "No commands to execute"
            return
        endif
        for cmd in cmds
            exec cmd
        endfor
    endif
endfunction
" Exec all actions at ACTION_STARTUP, ACTION_SHUTDOWN, ACTION_SCRIPT
function! NB_ExecActions( type )
  let s:nb_filename=g:nb_notebook.'.nb'
  let s:nb_file = s:nb_folder.'/'.s:nb_filename
  let lines = readfile(s:nb_file)
  let i = 0
  for line in lines
    if match(line,'^Action:') >= 0 
      let catline = lines[i+1]
      if match(catline,"Category:.*STARTUP") >= 0 && a:type == 0
        let j = i + 3
        if j >= len(lines)
          let i = i + 1
          continue
        endif
        let bodyline = lines[j]
        while match(bodyline, "^\\W*; ") >= 0 && j < len(lines)
          let action = strpart(bodyline,match(bodyline,";")+1)
          if len(action) > 0 
            exec action
          endif
          let j = j + 1
          if j < len(lines)
            let bodyline = lines[j]
          endif
        endwhile
      elseif match(catline,"Category:.*SHUTDOWN") >= 0 && a:type == 1
        let j = i + 3
        if j >= len(lines)
          let i = i + 1
          continue
        endif
        let bodyline = lines[j]
        while match(bodyline, "^\\W*; ") >= 0 && j < len(lines)
          let action = strpart(bodyline,match(bodyline,";")+1)
          if len(action) > 0 
            exec action
          endif
          let j = j + 1
          if j < len(lines)
            let bodyline = lines[j]
          endif
        endwhile
      elseif match(catline,"Category:.*SCRIPT") >= 0 && a:type == 2
        let j = i + 3
        if j >= len(lines)
          let i = i + 1
          continue
        endif
        let bodyline = lines[j]
        while match(bodyline, "^\\W*; ") >= 0 && j < len(lines)
          let action = strpart(bodyline,match(bodyline,";")+1)
          if len(action) > 0 
            exec action
          endif
          let j = j + 1
          if j < len(lines)
            let bodyline = lines[j]
          endif
        endwhile
      endif
    endif
    let i = i + 1
  endfor
endfunction
nmap <S-n>x :call NB_ExecActions(0)<cr>
nmap <S-n>X :call NB_ExecActions(1)<cr>
nmap <S-n>xx :call NB_ExecActions(2)<cr>
" Escape special characters in a string for exact matching.
" This is useful to copying strings from the file to the search tool
" Based on this - http://peterodding.com/code/vim/profile/autoload/xolox/escape.vim
function! NB_EscapeString (string)
  let string=a:string
  " Escape regex characters
  "let string = escape(string, '^$.*\/~[]')
  " Escape the line endings
  "let string = substitute(string, '\n', '\\n', 'g')
  return string
endfunction
" Get the current visual block for search and replaces
" This function passed the visual block through a string escape function
" Based on this - http://stackoverflow.com/questions/676600/vim-replace-selected-text/677918#677918
function! NB_GetVisual() range
  " Save the current register and clipboard
  let reg_save = getreg('"')
  let regtype_save = getregtype('"')
  let cb_save = &clipboard
  set clipboard&
  " Put the current visual selection in the " register
  normal! ""gvy
  let selection = getreg('"')
  " Put the saved registers and clipboards back
  call setreg('"', reg_save, regtype_save)
  let &clipboard = cb_save
  "Escape any special characters in the selection
  let escaped_selection = NB_EscapeString(selection)
  return escaped_selection
endfunction
nmap <S-n>l :call NB_AddMarkLineRef( 0 )<CR>
nmap <S-n>ll :call NB_AddMarkLineRef( 1 )<CR>
nmap <S-n>L :call NB_AddMarkLineRef( 2 )<CR>
vmap <S-n>l <esc>:call NB_AddMarkSelLineRef(0)<CR>
vmap <S-n>b <esc>:call NB_AddMarkSelLineRef(1)<CR>
nmap <S-n>e :call NB_AddCScopeQuery(expand('<cword>'))<cr>
vmap <S-n>e :call NB_AddCScopeQuery(NB_GetVisual())<cr>
nmap <S-n>u :call NB_AddGlobalQuery(expand('<cword>'))<cr>
nmap <S-n>u/ :call NB_AddGlobalQuery(@/)<cr>
vmap <S-n>u :call <esc>NB_AddGlobalQuery(NB_GetVisual())<cr>
nmap <S-n>p :call NB_AddFilePatch()<cr>
nmap <S-n>P :call NB_AddPatch()<cr>
nmap <S-n>s :call NB_AddSession()<cr>
nmap <S-n>sq :call NB_SelectSession(0)<cr>
nmap <S-n>o :call NB_Window_Open ()<cr>
nmap <S-n>O :call NB_ViewNotebook ()<cr>
nmap <S-n>+ :call NB_ImportNotebooks()<cr>
nmap <S-n>i :echom "Active Notebook: ".g:nb_notebook<cr>
" TODO: activate the following only for marks files
"nmap <Del> :call NB_Window_Close ()<cr>
"nmap <cr> :call NB_GoToMark ()<CR>
"nmap <S-n>c :call NB_Window_Close ()<cr>
nmap <S-n>g :call NB_GoToMark ()<CR>
nmap <S-n>d :call NB_ClearMarks ()<CR>
nmap <S-n>lw :call NB_List (expand('<cword>'))<cr>
vmap <S-n>lw :call <esc>NB_List (NB_GetVisual())<cr>
nmap <S-n>c :call NB_ListContext (0)<cr>
nmap <S-n>C :call NB_ListContext (1)<cr>
nmap <S-n>f :call NB_Global (expand('<cword>'))<cr>
vmap <S-n>f <esc>:call NB_Global (NB_GetVisual())<cr>
nmap <S-n>fc :call NB_GlobalCategory ("")<cr>
nmap <S-n>fq :call NB_GlobalItems ("Query")<cr>
nmap <S-n>F :call NB_Grep (expand('<cword>'))<cr>
vmap <S-n>F <esc>:call NB_Grep (NB_GetVisual())<cr>
nmap <S-n>Fi :call NB_GrepItems ("")<cr>
nmap <S-n>Fq :call NB_GrepItems ("Query")<cr>
nmap <S-n>q :call NB_SelectQuery ("")<cr>
nmap <S-n>n  :call NB_SelectNotebook ()<cr>
nmap <S-n>nd :call NB_DeleteNotebook ()<cr>
nmap <S-n>nr :call NB_RenameNotebook ()<cr>
nmap <S-n>na :call NB_ArchiveNotebook ()<cr>
nmap <S-n>ns :exec "normal! zMgg"<cr>
nmap <S-n>k :exec ":map <S-n>"<cr>
"nmap <S-n>n :call NB_LocListMarks(1)<cr>
"nmap <S-n>nc :call NB_LocListMarks(0)<cr>
nmap <S-n>an :call NB_AddNote()<cr>
nmap <S-n>ai :call NB_AddImport()<cr>
nmap <S-n>r  :call NB_PrintRoot()<cr>

command! -nargs=1 VimNotebookOpen call NB_OpenNotebook(<q-args>)
