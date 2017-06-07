comma-mode
==========

A modal editing minor-mode designed with Emacs in mind.

Overview
--------

Comma-mode is minor mode for Emacs that defines a single key map to
facilitate fast modal editing.  Most of the modal commands our derived
from key bindings that come with a standard Emacs installation.  For
example, `C-f` is bound to `f` in the comma-mode key map to forward a
character.  This allows to use the same mnemonics that one has learned
from vanilla Emacs and to navigate a buffer while comma-mode is
active.

Comma-mode also defines motions with the `h`, `j`, `k`, and `l` keys.
However, unlike VIM these keys move forward and backward words and
paragraphs.  The reasoning behind this is that the most common motions
used while navigating a buffer should be quickly accessible.  It is
much more common to move over medium and large chunks of text as
opposed to single characters or lines, which for those motions
you have the `f`, `b`, `n`, and `p` bindings.

One neat feature provided by comma-mode is quick jumping to
punctuation characters.  When comma-mode is active and any of the
`!@#$%^&*()-_+={}[]\|;:'"<>,.?/` keys are pressed, comma-mode will
advance to the next occurrence of that character.  So imagine you have
the following piece of code:

```
// The Emacs point is right here -> | <- in the buffer.

void demo(int arg1, int arg2, int arg3)
{
    // do something
}
```

And with comma-mode active you hit the `,` key which will move the
point from the `|` in the first comment to the comma right after `int
arg1` parameter in the function definition.  If you hit the `,` second
time then the point will be placed at the next comma after `int
arg2`.

Of course, these quick motions work in reverse by holding the Meta key
for the binding.  So from our previous example if the point is at the
second comma after `int arg2` then by hitting `M-,` will move
backwards to the previous comma after `int arg1`.  The idea about
jumping directly to punctuation is that many programming languages use
alot of punctuation for various purposes within its syntax so it makes
sense to facilate easy keybindings to quickly navigate through such code.

One can also move forward to the next occurrence of any character with
the `s` key binding in the comma-mode key map.  For example, hitting
the `s` key followed by `j` will search forward to the next 'j'
occurrence in the buffer.  Likewise, hitting a capital `S` followed by
another character will search backward for that character.

Finally, there is the *moar motion* command that is bound to the `m`
key in the comma-mode map.  This will repeat the last search motion
either from direct punctuation character or form the `s` search
command.  Note that direction searched is preserved on repeated
presses of the `m` key.  For example, if one types `M-(` to move
backward to the last left parenthesis then hitting `m` will continue
to the next left parenthesis.  Furthermore, hitting `M` will reverse
the direction of the search.  So `M-(` then `m`, `m`, and then `M`
will search backwards for the last three left parentheses and the
final `M` will move forward to the last second left parenthesis that
was passed over.  This can be pretty useful if one finds themself
overshooting the character they were moving to.
