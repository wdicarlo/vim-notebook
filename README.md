vim-notebook
===========

Vim plugin to annotate text, source code, etc.

This plugin has been created to annotate and aggregate key aspects, such as source code, documentation, notes etc, relative to tasks to be done.

Annotations with referenced resources are stored into text files called notebooks under the folder $HOME/.notebook. 

Changes
-------
2013-08-18
 * added support for relative files references (.git or .notebook_root folder used as hook to find the root folder)
        
Description
-----------

While working on a task, like to solve a bug, in many cases it is necessary to explore a big source code base, lot of logs and documentation. This plugin allows to aggregate into one text file references to key code, documentation, logs and notes. The following are some reasons to use this plugin in such cases:

 * it create an outline of the most important aspects of the item under investigation
 * it is easy to explore most important aspects related to a task
 * it is much easy to switch between tasks
 * it is reduced the information overload
 * notebooks can be shared with other to speed knowledge transfer

A typical usage scenario is:
 
 1. create a new notebook called issue_missing_refresh_of referenced_line
 2. open the text file containing key information
 3. select text of interest
 4. annotate selecting proper category and description
 5. repeat annotation for other interesting text
 6. open the notebook to have an overview of interesting information
 7. go to an entry of interest
 8. jump to the referenced text file
 9. repeat the exploration with other entries

Several different types of annotations are supported:

 * Text    - annotation of referenced text files
 * Note    - annotation of a note
 * Action  - annotation of commands to be executed
 * Import  - annotation of reference to another notebook
 * Query   - annotation of queries (:global and :cscope)
 * Session - annotation of open windows

Each entry is stored in the text file with the following syntax:

    <Text|Note|Action|Query|Session>: <title>
       : Category:  <category>
       : Reference: <reference>
       : Date:      <date_time>
          ; <body>
          ; <body>
where, in most cases, title and category are requested to the user.

Here is an example of an annotation file named hello_world.nb

    Text: hello world                                          <-- initial entry
      : Category:  NOTEBOOK
      : Reference: text
      : Date:      12_08_07_21_24
        ; an example of vim notebook annotation file
        ; 
    Import: import info_common_notes
      : Category:  INFORMATION
      : Reference: info_common_notes.nb
    Action: hello world
      : Category:  STARTUP                                     <-- action entry executed
      : Reference: vim                                             at the activation of
      : Date:      12_08_07_21_34                                  the notebook
        ; :lcd /home/usera/.vim/plugin                         <-- commands to execute
        ; :tabnew notebook.vim                                 
        ; :tabnew /home/usera/.notebook/plugin_notebook.nb     
        ; :tabnew /home/usera/.notebook/notebook.rc            
    Action: bye bye world
      : Category:  SHUTDOWN                                    <-- action entry executed
      : Reference: vim                                             at the deactivation
      : Date:      12_08_07_21_44                                  of the notebook
        ; :bw notebook.vim
        ; :bw /home/usera/.notebook/plugin_notebook.nb
        ; :bw /home/usera/.notebook/notebook.rc
    Session: most important windows to use with this notebook
      : Category:  INTERESTING
      : Reference: files
        ; /home/usera/git/vim-notebook/README.md
        ; /home/usera/.vim/plugin/notebook.vim
    Action: search category 
      : Category:  SCRIPT
      : Reference: vim
      : Date:      12_08_07_22_24
        ; :let cat = NB_SelectCategory(1)
        ; :exec ":g/".cat
    Query: search actions
      : Category: DEBUG
      : Reference: :g/^Action:                                 <-- command to execute the
      : Date:      12_08_07_22_34                                  query
    Text: most important key map to annotate
      : Category:  INFORMATION
      : Reference: /home/usera/.vim/plugin/notebook.vim:1482
      : Date:      12_08_09_09_17
        ; nmap <S-n>l :call NB_AddMarkLineRef( 0 )<CR>
        ; nmap <S-n>ll :call NB_AddMarkLineRef( 1 )<CR>
        ; nmap <S-n>L :call NB_AddMarkLineRef( 2 )<CR>
        ; vmap <S-n>l <esc>:call NB_AddMarkSelLineRef(0)<CR>
        ; vmap <S-n>b <esc>:call NB_AddMarkSelLineRef(1)<CR>
        ; nmap <S-n>e :call NB_AddCScopeQuery(expand('<cword>'))<cr>
        ; vmap <S-n>e :call NB_AddCScopeQuery(NB_GetVisual())<cr>
        ; nmap <S-n>u :call NB_AddGlobalQuery(expand('<cword>'))<cr>
        ; nmap <S-n>u/ :call NB_AddGlobalQuery(@/)<cr>
        ; vmap <S-n>u :call <esc>NB_AddGlobalQuery(NB_GetVisual())<cr>
        ; nmap <S-n>p :call NB_AddFilePatch()<cr>
    Text: multi-line input is needed to create more interesting notes
      : Category:  TODO
      : Reference: /home/usera/.vim/plugin/notebook.vim:552
      : Date:      12_08_09_09_18
        ;   " TODO: input multi-line note
        ;   let l:note=input("Note? ")
    Text: note templetes should be available to simplify note taking
      : Category:  TODO
      : Reference: /home/usera/.vim/plugin/notebook.vim:682
      : Date:      12_08_09_09_20
        ; " TODO: complete
        ; function! NB_AddNoteTemplate()
        ; endfunction

Configuration variables are stored in the file ~/.notebook/notebook.rc

    " notebook.vim configuration file
    " 
    let g:nb_notebook = "hello_world"
    let g:nb_categories = ['CHECK', 'CLASS', 'CODE', 'CONDITION', 'DEBUG', 'DEFINE', 'DEFINITION', 'DUMMY', 'ENUM', 'FIX', 'FUNCTION', 'HACK', 'INCLUDE', 'INFORMATION', 'INITIALIZATION', 'INTERESTING', 'LOG', 'LOGGING', 'MEMORY', 'MESSAGE', 'METHOD', 'NONE', 'NOTE', 'STRUCT', 'STUDY', 'TEMPLATE', 'TEST', 'TODO', 'TYPE', 'VARIABLE', 'WORKAROUND']

Features
--------

 * Management of notebooks of annotations (new, activate, rename, delete, archive)
 * Only one notebook can be active 
 * Last used notebook is remembered through vim sessions
 * Notebook files are text files with extension .nb
 * Archived notebook files are text files with extension .nba
 * Can visualize active and/or any one of the other notebooks
 * Can clone a notebook while creating a new one
 * Support annotations for Text,Note,Action,Import,Query,and Session types
 * User can re-open/repeat the referenced file/action/query/session
 * Annotate text files with or without user input of details
 * Annotate text files with context of current line or selected lines
 * Support Import annotation to import entries from other notebooks
 * Support global and cscope Query entries
 * Support execution of commands at de/activation of notebooks
 * Support save/load of list of windows in Session annotation
 * Can generate location list for easy navigation
 * Allows to select from available list of queries,actions and sessions
 * Store configuration variables in the file ~/.notebook/notebook.rc
 * Partial support for Patch annotation
 * Query entry's body is the text obtained by applying the query
 * User created categories are stored in the config. file called notebook.rc
 * Uses relative file references


Installation
------------

Prerequisites:

 * VimOutliner (optional) - used to fold entries

Copy the notebook.vim file under the plugin folder or use the Vundle reference wdicarlo/vim-notebook

Suggestions
-----------

Notebooks can be created using a name convention like using one of the following string at the begin of the name:

 * info  - for notebooks documenting an aspect
 * issue - for notebooks used to solve an issue
 * task  - for notebooks to document tasks to be done
 * notes - for notebooks containing generic notes

Limitations
-----------

The following limitation are available:
 
 * Imported notebooks are only available after explicit expansion by user action

TODOs
-----
 
 * Improve code quality
 * Add user started plugin loading
 * Add help  
 * Add workspace management
 * Improve concurrency
 * Complete Patch annotation (svn, git, etc)
 * Add List annotation (todo, enums, etc)
 * Improve Session annotation using Vim sessions
 * Add Resource annotation (URI, URL, etc)
 * Add Attributes: property (S=Star, P=Priority, I=Impact)
 * Add reference to the file used to create the Query entry
 * Add C/C++/Java mode to annotate code context 
 * Add support for CCTree queries
 * Improve notebook import functionality
 * Enforce category name in uppercase
 * Enforce notebook names without spaces

Nice to Have
------------
 
 * Auto update referenced text lines
 * Fuzzy search of changed referenced text lines
 * Auto creation/update of context tree
 * eMail annotation
 * Replace categories with tags
 * Sidebar
 * Powerline entry with active notebook
 * Integration with Trac
