;;; flymake-stylelint.el --- A Flymake backend for CSS and friends using stylelint -*- lexical-binding: t; -*-

;;; Version: 1.2.0

;;; Author: Dan Orzechowski

;;; URL: https://github.com/orzechowskid/flymake-stylelint

;;; Package-Requires: ((emacs "26.0"))

;;; Commentary:
;; A backend for Flymake which uses stylelint.  Enable it with `M-x flymake-stylelint-enable [RET]'.
;; Alternately, configure a mode-hook for your CSS major mode of choice:
;;
;; (add-hook 'some-css-major-mode-hook
;;   (lambda () (flymake-stylelint-enable))
;;
;; A handful of configurable options can be found in the `flymake-stylelint' customization group: view and modify them with the command `M-x customize-group [RET] flymake-stylelint [RET]'.

;;; License: MIT

;;; Code:


;; our own customization group


(defgroup flymake-stylelint nil
  "Flymake backend for CSS and friends using stylelint"
  :group 'programming
  :prefix "flymake-stylelint-")


;; useful variables


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
	"Whether to use a globally-installed (i.e. `npm i -g`) stylelint or a locally-
installed (i.e. `npx stylelint`) one."
	:type 'boolean
	:group 'flymake-stylelint)


;; internal variables


(defvar flymake-stylelint--message-regex "^\\(.+\\):\\([0-9]+\\):\\([0-9]+\\):[[:space:]]\\(.+\\)[[:space:]](\\(.+\\))[[:space:]]\\[\\([[:alpha:]]+\\)]$"
  "Internal variable.
Regular expression definition to match stylelint messages.")

(defvar-local flymake-stylelint--process nil
  "Internal variable.
Handle to the linter process for the current buffer.")


;; internal functions


(defun flymake-stylelint--ensure-binary-exists ()
  "Internal function.
Throw an error and tell Flymake to disable itself if `flymake-stylelint-executable-name' can't be found on variable `exec-path'"
  (unless (executable-find flymake-stylelint-executable-name)
    (error (message "can't find '%s' in exec-path - try M-x set-variable flymake-stylelint-executable-name maybe?" flymake-stylelint-executable-name))))

(defun flymake-stylelint--report (stylelint-stdout-buffer source-buffer)
  "Internal function.
Create Flymake diag messages from contents of STYLELINT-STDOUT-BUFFER, to be reported against SOURCE-BUFFER.  Returns a list of results"
  (with-current-buffer stylelint-stdout-buffer
    ;; start at the top and check each line for an stylelint message
    (goto-char (point-min))
    (if (looking-at-p "Error:")
        (let ((diag (flymake-make-diagnostic source-buffer (point-min) (point-max) :error (thing-at-point 'line t))))
          ;; ehhhhh point-min and point-max here are of the stylelint output buffer
          ;; containing the error message, not source-buffer
          (list diag))
      (let ((results '()))
        (while (not (eobp))
          (when (looking-at flymake-stylelint--message-regex)
            (let* ((row (string-to-number (match-string 2)))
                   (column (string-to-number (match-string 3)))
                   (msg (match-string 4))
                   (lint-rule (match-string 5))
                   (type-str (match-string 6))
                   (msg-text (if flymake-stylelint-show-rule-name
                               (format "%s: %s [%s]" type-str msg lint-rule)
                               (format "%s: %s" type-str msg)))
                   (type-symbol (if (string-equal "warning" type-str) :warning :error))
                   (src-pos (flymake-diag-region source-buffer row column)))
              ;; new Flymake diag message
              (push (flymake-make-diagnostic source-buffer (car src-pos) (cdr src-pos) type-symbol msg-text) results)))
          (forward-line 1))
        results))))

(defun flymake-stylelint--executable-name ()
	"Internal function.  Get the stylelint binary to invoke."
	(if flymake-stylelint-use-global
			(list flymake-stylelint-executable-name)
		(list "npx"
					flymake-stylelint-executable-name)))

(defun flymake-stylelint--executable-args ()
	"Internal function.  Get a list of additional arguments to pass to the
stylelint process."
	(if (listp flymake-eslint-executable-args)
			flymake-eslint-executable-args
		(list flymake-eslint-executable-args)))

;; heavily based on the example found at
;; https://www.gnu.org/software/emacs/manual/html_node/flymake/An-annotated-example-backend.html
(defun flymake-stylelint--create-process (source-buffer callback)
  "Internal function.
Create linter process for SOURCE-BUFFER which invokes CALLBACK once linter is finished.  CALLBACK is passed one argument, which is a buffer containing stdout from linter."
	(when (process-live-p flymake-stylelint--process)
    (kill-process flymake-stylelint--process))
	(let ((cmd `(,@(flymake-stylelint--executable-name)
							 "--formatter=unix"
							 "--no-color"
							 "--stdin-filename"
							 ,(or (buffer-file-name source-buffer)
										(buffer-name source-buffer))
							 ;; splice in a (possibly empty) list of executable args
							 ,@(flymake-stylelint--executable-args))))
		(setq flymake-stylelint--process
					(make-process
					 :name "flymake-stylelint"
					 :connection-type 'pipe
					 :noquery t
					 :buffer (generate-new-buffer " *flymake-stylelint*")
					 :command cmd
					 :sentinel (lambda (proc &rest ignored)
											 ;; do stuff upon child process termination
											 (when (and (eq 'exit (process-status proc))
																	;; make sure we're not using a deleted buffer
																	(buffer-live-p source-buffer)
																	;; make sure we're using the latest lint process
																	(with-current-buffer source-buffer (eq proc flymake-stylelint--process)))
												 ;; read from stylelint output then destroy temp buffer when done
												 (let ((proc-buffer (process-buffer proc)))
													 (funcall callback proc-buffer)
													 (kill-buffer proc-buffer))))))))

(defun flymake-stylelint--check-and-report (source-buffer flymake-report-fn)
  "Internal function.
Run stylelint against SOURCE-BUFFER and use FLYMAKE-REPORT-FN to report results."
  (if flymake-stylelint-defer-binary-check
      (flymake-stylelint--ensure-binary-exists))
	(flymake-stylelint--create-process
	 source-buffer
	 (lambda (stylelint-stdout)
		 (funcall flymake-report-fn (flymake-stylelint--report stylelint-stdout source-buffer))))
  (with-current-buffer source-buffer
    (process-send-string flymake-stylelint--process (buffer-string))
    (process-send-eof flymake-stylelint--process)))

(defun flymake-stylelint--checker (flymake-report-fn &rest ignored)
  "Internal function.
Run stylelint on the current buffer, and report results using FLYMAKE-REPORT-FN.  All other parameters are currently IGNORED."
  (flymake-stylelint--check-and-report (current-buffer) flymake-report-fn))


;; module entry point


;;;###autoload
(defun flymake-stylelint-enable ()
  "Enable Flymake and add flymake-stylelint as a buffer-local Flymake backend."
  (interactive)
  (if (not flymake-stylelint-defer-binary-check)
      (flymake-stylelint--ensure-binary-exists))
  (flymake-mode t)
  (add-hook 'flymake-diagnostic-functions 'flymake-stylelint--checker nil t))


(provide 'flymake-stylelint)


;;; flymake-stylelint.el ends here
