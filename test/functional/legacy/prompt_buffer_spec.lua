local helpers = require('test.functional.helpers')(after_each)
local Screen = require('test.functional.ui.screen')
local feed= helpers.feed
local source = helpers.source
local clear = helpers.clear
local feed_command = helpers.feed_command

describe('prompt buffer', function()
  local screen

  before_each(function()
    clear()
    screen = Screen.new(25, 10)
    screen:attach()
    source([[
      func TextEntered(text)
        if a:text == "exit"
          stopinsert
          close
        else
          call append(line("$") - 1, 'Command: "' . a:text . '"')
          set nomodfied
          call timer_start(20, {id -> TimerFunc(a:text)})
        endif
      endfunc

      func TimerFunc(text)
        call append(line("$") - 1, 'Result: "' . a:text .'"')
      endfunc
    ]])
  end)

  after_each(function()
    screen:detach()
  end)

  it('works', function()
    feed_command("set noshowmode | set laststatus=0")
    feed_command("call setline(1, 'other buffer')")
    feed_command("new")
    feed_command("set buftype=prompt")
    feed_command("call prompt_setcallback(bufnr(''), function('TextEntered'))")
    screen:expect([[
      ^                         |
      ~                        |
      ~                        |
      ~                        |
      [Scratch]                |
      other buffer             |
      ~                        |
      ~                        |
      ~                        |
                               |
    ]])
    feed_command("startinsert")
    feed("hello\n")
    screen:expect([[
      % hello                  |
      Command: "hello"         |
      Result: "hello"          |
      % ^                       |
      [Scratch]                |
      other buffer             |
      ~                        |
      ~                        |
      ~                        |
                               |
    ]])
    feed("exit\n")
    screen:expect([[
      ^other buffer             |
      ~                        |
      ~                        |
      ~                        |
      ~                        |
      ~                        |
      ~                        |
      ~                        |
      ~                        |
                               |
    ]])
  end)

end)
