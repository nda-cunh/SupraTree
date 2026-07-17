# 🌳 SupraTree.vim

**SupraTree** is a "staging-first" file explorer for Vim 9.
Positioned between **Neo-tree** for its interface and **Oil.nvim** for its editing capabilities, it allows you to manipulate your file system like a simple text buffer.

<img width="755" height="750" alt="image" src="https://github.com/user-attachments/assets/7d73090c-b25c-4a4c-ae74-43ffd9b801e3" />


<img width="949" height="901" alt="supratree" src="https://github.com/user-attachments/assets/3d1aa347-4f21-4c64-bf3d-082662a9595c" />


## ✨ The "Supra" Concept

Unlike traditional explorers that apply every change immediately, SupraTree works through **intentions**:
1. You modify the tree (rename, create, delete).
2. Changes are visually highlighted.
3. You commit all operations at once using `:w` or `<C-s>`.

## 🚀 Features

* **Direct Editing**: Rename (`i`), create (`o` or `O`), or delete (`dd`) files just like text.
* **Integrated VCS**: Asynchronous support for **Git** and **SVN**.
* **Smart Clipboard**: Yank/Paste (`y`/`p`) supporting visual selections for bulk operations.
* **Modern UI**: Automatic sidebar dimming (`DarkenColor`) and full icon font support.

## 📦 Installation

### 🧩 Dependencies

- **Vim 9.1.1110+**
- **VCS**: `git` or `svn`
- **Icons**: Use a compatible icon extension (e.g., `nda-cunh/SupraIcons`) for the best experience.
- **Palette**: Use a compatible palette extension (e.g., `nda-cunh/SupraIcons.vim` or `lambdalisue/vim-glyph-palette`) for perfect theme integration.

`vim
Plug 'nda-cunh/SupraTree.vim'
`

## 💻 Basic Commands

`:SupraTreeOpen`      # Opens the tree in a new window
`:SupraTreeClose`     # Closes the tree window
`:SupraTreeToggle`    # Opens or closes the tree depending on its state
`:SupraTreeRefresh`   # Syncs the tree with the file system
`:SupraTreeChangeDir` # Changes Vim's current working directory to the tree's root
`:SupraTreeCD`        # alias for SupraTreeChangeDir


## ⌨️ Tree Buffer Mappings

### Navigation
| Key | Action |
| :--- | :--- |
| `<CR>` | Open file / Expand folder |
| `t` / `<C-t>` | Open in a new **Tab** |
| `s` / `<C-h>` | Open in a horizontal **Split** |
| `v` / `<C-v>` | Open in a vertical **VSplit** |
| `-` / `<BS>` | Move up to parent directory |
| `P` | Jump to parent folder |
| `{` / `}` | Jump to previous / next sibling |
| `J` / `K` | Fast jump to first / last child |

### CRUD Operations (Editing)
| Key | Action |
| :--- | :--- |
| `i` | **Rename**: Modify the name of the node under the cursor |
| `o` / `O` | **New File**: Create a file (add `/` for a folder) |
| `dd` | **Delete**: Mark the file for deletion |
| `y` / `yy` | **Yank**: Add to the SupraTree clipboard |
| `p` | **Paste**: Paste copied files into the selected folder |
| `<C-s>` / `:w` | **Save**: Actually apply changes to the disk |
| `r` | **Refresh**: Sync the tree with the disk and VCS |

Inside the rename / new file popup, `<Enter>` confirms the name and `<C-s>` confirms it **and** saves to the disk right away. When that name is the only pending change, it is applied without asking; if other changes are still pending, the usual confirmation popup lists them all.

> Since `v` now opens a vertical split, enter Visual mode with `V` (linewise) to select several rows for `d` / `y`.

# ⚙️ Global Configuration

## ⌨️ Custom Mappings
By default, SupraTree is mapped to <C-g>. You can easily remap it to your preferred key (e.g., <F2>) in your .vimrc:
Add these variables to your `.vimrc` to customize your experience:

```vim
# Change the toggle shortcut to F2 for Normal and Insert modes
nmap <F2> <Plug>(SupraTreeToggle)
imap <F2> <Plug>(SupraTreeToggle)
```

| Key | default | Action |
| :--- | :--- | :--- |
| `<Plug>(SupraTreeToggle)` | <c-g> | Toggle the SupraTree window |

### Rebinding tree-buffer keys

The in-tree keys are configurable through `g:supratree_mappings`. Each action
takes **either a single key or a list of keys**, so you can bind several keys to
the same action. An empty string (or empty list) disables an action.

```vim
g:supratree_mappings = {
    'open_split':  ['s', "\<C-h>"],   # multiple keys at once
    'open_vsplit': ['v', "\<C-v>"],
    'open_tab':    ['t', "\<C-t>"],
    'refresh':     'R',                # a single key
    'yank':        '',                 # disable an action
}
```

Only the actions you list are overridden; every other key keeps its default.

| Action | Default keys | Description |
| :--- | :--- | :--- |
| `open_edit` | `<CR>` | Open file / expand folder |
| `open_tab` | `t`, `<C-t>` | Open in a new tab |
| `open_split` | `s`, `<C-h>` | Open in a horizontal split |
| `open_vsplit` | `v`, `<C-v>` | Open in a vertical split |
| `close_all` | `W` | Close all open directories |
| `back` | `-`, `<BS>` | Move up to parent directory |
| `jump_parent` | `P` | Jump to the parent folder |
| `next_sibling` | `>`, `}` | Jump to the next sibling |
| `prev_sibling` | `<`, `{` | Jump to the previous sibling |
| `rename` | `i` | Rename the node under the cursor |
| `new_file` | `o` | New file below (add `/` for a folder) |
| `new_file_above` | `O` | New file above |
| `remove` | `dd` | Mark the node for deletion |
| `yank` | `yy` | Add to the SupraTree clipboard |
| `paste` | `p` | Paste copied files into the folder |
| `save` | `<C-s>` | Apply pending changes to the disk |
| `refresh` | `r` | Sync the tree with disk and VCS |

## 🔧 Settings

### Behavior & Layout
- `g:supratree_open_on_startup` (Default: `false`): Automatically opens the tree on Vim launch.
- `g:supratree_focus_on_open` (Default: `true`): Focus the tree window when opened.
- `g:supratree_position` (Default: `'left'`): Window position (`'left'` or `'right'`).
- `g:supratree_width` (Default: `26`): Tree window width.
- `g:supratree_sortascending` (Default: `true`): Sorts files alphabetically.
- `g:supratree_sync_with_cd` (Default: `true`): Automatically syncs the tree with Vim's current working directory.

### Filtering & Visibility
- `g:supratree_filter_files` (Default: `['*.o', '*.class', ...]`): List of file patterns to hide.
- `g:supratree_show_hidden` (Default: `true`): Show or hide hidden files (starting with `.`).

### Icons & Palette
- `g:supratree_icons_glyph_func`: Function to fetch the icon glyph (e.g., `WebDevIconsGetFileTypeSymbol`).
- `g:supratree_icons_glyph_palette_func`: Function to apply colors to icons (e.g., `SupraIcons#Palette#Apply`).


## 🎨 Design & Colors

- `g:supratree_darken_amount` (Default: `22`): Intensity of the tree column dimming (0-255).
- `g:supratree_force_color` (Default: `''`): Force a specific background color if defined.


### Why use SupraTree?
Because manipulating files shouldn't be any different from manipulating text. Stage your project structure, double-check the colors to avoid mistakes, and `:w`. That's it.
