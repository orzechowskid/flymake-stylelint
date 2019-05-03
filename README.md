# flymake-stylelint
Flymake backend for CSS and friends using eslint

## Installation

0. Make sure `stylelint` is installed and present on your emacs `exec-path`.  For Linux systems `exec-path` usually equals your `$PATH` environment variable; for other systems, you're on your own.
1. Install: download and place inside `~/.emacs.d/lisp`.  then edit `~/.emacs` or equivalent:
  ```lisp
  (add-to-list 'load-path "~/.emacs.d/lisp")
  (require "flymake-stylelint.el")
  ```
2. Enable:
```lisp
(add-hook 'scss-mode-hook ; or whatever the mode-hook is for your mode of choice
  (lambda ()
    (flymake-stylelint-enable)))
```
## Customization

useful variables are members of the `flymake-stylelint` group and can be viewed and modified with the command `M-x customize-group [RET] flymake-stylelint [RET]`.

```lisp
(defcustom flymake-stylelint-executable-name "stylelint"
  "Name of executable to run when checker is called.  Must be present in variable `exec-path'."
  :type 'string
  :group 'flymake-stylelint)

(defcustom flymake-stylelint-executable-args nil
  "Extra arguments to pass to stylelint."
  :type 'string
  :group 'flymake-stylelint)

(defcustom flymake-stylelint-show-rule-name t
  "Set to t to append rule name to end of warning or error message, nil otherwise."
  :type 'boolean
  :group 'flymake-stylelint)
```

## See Also

[flymake-eslint](https://github.com/orzechowskid/flymake-eslint)

## License

MIT
