# flymake-stylelint
Flymake backend for CSS and friends using stylelint

![](https://repository-images.githubusercontent.com/184793765/d553dff2-043b-4041-90f4-98940a982c7d)

## Installation

### Prerequisites

Make sure `stylelint` is installed, either:
- globally, meaning it's present on your emacs `exec-path`.  For Linux systems `exec-path` usually equals your `$PATH` environment variable; for other systems, you're on your own
- locally, meaning you have run `npm install stylelint` in a project and `stylelint` is present in your package.json file.  this will require you to `(setq flymake-stylelint-use-global nil)` somewhere

### Automatic install with straight, use-package, etc.

the git recipe is:

```lisp
'(flymake-stylelint :type git :host github :repo "orzechowskid/flymake-stylelint" :branch "master")
```

### Manual install

download and place inside a directory on your `load-path`, then:
```lisp
(require "flymake-stylelint.el")
(add-hook 'my-css-mode-hook
  #'flymake-eslint-enable)
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
  :type '(choice string (repeat string))
  :group 'flymake-stylelint)

(defcustom flymake-stylelint-show-rule-name t
  "Set to t to append rule name to end of warning or error message, nil otherwise."
  :type 'boolean
  :group 'flymake-stylelint)

(defcustom flymake-stylelint-defer-binary-check nil
  "Set to t to bypass the initial check which ensures stylelint is present.

Useful when the value of variable `exec-path' is set dynamically and the location of stylelint might not be known ahead of time."
  :type 'boolean
  :group 'flymake-stylelint)

(defcustom flymake-stylelint-use-global t
	"Whether to use a globally-installed (i.e. `npm i -g`) stylelint or a locally-installed (i.e. `npx stylelint`) one."
	:type 'boolean
	:group 'flymake-stylelint)
```

## See Also

[flymake-eslint](https://github.com/orzechowskid/flymake-eslint)

## License

MIT
