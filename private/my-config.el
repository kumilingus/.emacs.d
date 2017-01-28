;;; my-config.el --- description

;;; Add path to node
;;; http://stackoverflow.com/questions/18102833/could-not-start-tern-server-in-emacs
(setenv "PATH" (concat "/usr/local/bin:" (getenv "PATH")))

;;; Tab for autocompletion
;;; https://github.com/company-mode/company-mode/issues/94
(with-eval-after-load 'company

  (define-key company-mode-map [remap indent-for-tab-command]
    'company-indent-for-tab-command)

  (setq tab-always-indent 'complete)

  (defvar completion-at-point-functions-saved nil)

  (defun company-indent-for-tab-command (&optional arg)
    (interactive "P")
    (let ((completion-at-point-functions-saved completion-at-point-functions)
          (completion-at-point-functions '(company-complete-common-wrapper)))
      (indent-for-tab-command arg)))

  (defun company-complete-common-wrapper ()
    (let ((completion-at-point-functions completion-at-point-functions-saved))
      (company-complete-common)))
)

(provide 'my-config)
;;; my-config.el ends here
