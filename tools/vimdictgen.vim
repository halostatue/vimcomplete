vim9script

# Run this shell command while in the `tools/` directory:
#    $ vim -Nu NONE -S vimdictgen.vim

const VIM_DICT: string = expand('<sfile>:p:h:h') .. '/data/vim9.dict'
var header: list<string> =<< trim eval END
    -- DO NOT EDIT THIS FILE DIRECTLY.
    -- It is meant to be generated by ./tools/{expand('<sfile>:p:t')}
END

header->writefile(VIM_DICT)

const builtin_func: list<string> = getcompletion('', 'function')
    # builtin functions only
    ->filter((_, v: string): bool => v[0] =~ '[a-z]' && v !~ '#')
    # remove trailing parens
    # ->map((_, v: string) => v->substitute('()\=$', '', ''))

const cmds: list<string> = getcompletion('', 'command')
    ->filter((_, v: string): bool => v =~ '^[a-z]')

const collation_class: list<string> =
    getcompletion('[:', 'help')
        ->filter((_, v: string): bool => v =~ '^\[:')
        ->map((_, v: string) => v->trim('[]:'))

const command_address_type: list<string> = getcompletion('command -addr=', 'cmdline')

const command_complete_type: list<string> = getcompletion('command -complete=', 'cmdline')

def DefaultHighlightingGroup(): list<string>
    var completions: list<string> = getcompletion('hl-', 'help')
        ->map((_, v: string) => v->substitute('^hl-', '', ''))
    for name: string in ['Ignore', 'Conceal', 'User1..9']
        var i: number = completions->index(name)
        completions->remove(i)
    endfor
    completions += range(2, 8)->map((_, v: number): string => 'User' .. v)
    return completions->sort()
enddef

const default_highlighting_group: list<string> = DefaultHighlightingGroup()

const event: list<string> = getcompletion('', 'event')

# `:help cmdline-special`
const ex_special_characters: list<string> =
    getcompletion(':<', 'help')[1 :]
        ->map((_, v: string) => v->trim(':<>'))

def KeyName(): list<string>
    var completions: list<string> = getcompletion('set <', 'cmdline')
        ->map((_, v: string) => v->trim('<>'))
        ->filter((_, v: string): bool => v !~ '^t_' && v !~ '^F\d\+$')
    # `Nop` and `SID` are missing
    completions->add('Nop')->add('SID')
    return completions
enddef

const key_name: list<string> = KeyName()

def Option(): list<string>
    var helptags: list<string>
    readfile($VIMRUNTIME .. '/doc/options.txt')
        ->join()
        ->substitute('\*''[a-z]\{2,\}''\*',
            (m: list<string>): string => !!helptags->add(m[0]) ? '' : '', 'g')

    var deprecated: list<string> =<< trim END
        *'biosk'*
        *'bioskey'*
        *'consk'*
        *'conskey'*
        *'fe'*
        *'nobiosk'*
        *'nobioskey'*
        *'noconsk'*
        *'noconskey'*
    END

    for opt: string in deprecated
        var i: number = helptags->index(opt)
        if i == -1
            continue
        endif
        helptags->remove(i)
    endfor

    return helptags
        ->map((_, v: string) => v->trim("*'"))
enddef

const option: list<string> = Option()

# terminal options with only word characters
const option_terminal: list<string> =
    # getting all terminal options is trickier than it seems;
    # let's use 2 sources to cover as much ground as possible
    (getcompletion('t_', 'option') + getcompletion('t_', 'help'))
        ->filter((_, v: string): bool => v =~ '^t_\w\w$')

# terminal options with at least 1 non-word character
const option_terminal_special: list<string> =
    (getcompletion('t_', 'option') + getcompletion('t_', 'help'))
        ->map((_, v: string) => v->trim("'"))
        ->filter((_, v: string): bool => v =~ '\W')

const misc: list<string> =
    getcompletion('null_', 'help') + getcompletion('v:', 'help')
        ->filter((_, v: string): bool => v != 'v:')

##
var items = builtin_func
    + cmds
    + collation_class
    + command_address_type
    + command_complete_type
    + default_highlighting_group
    + event
    + ex_special_characters
    + key_name
    + option
    + option_terminal
    + option_terminal_special
    + misc

def CompareWithoutTrailingParen(i1: string, i2: string): number
    var lhs = i1->substitute('($', '', '')->substitute('()$', '', '')
    var rhs = i2->substitute('($', '', '')->substitute('()$', '', '')
    return lhs == rhs ? 0 : lhs > rhs ? 1 : -1
enddef

items->sort(CompareWithoutTrailingParen)
    ->uniq(CompareWithoutTrailingParen)
    ->filter((_, v) => v->len() > 1)
    ->writefile(VIM_DICT, 'a')

# Reference: https://github.com/lacygoill/vim9-syntax
