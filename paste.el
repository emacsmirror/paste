;;; past.el --- paste server with elnode

;; Copyright (C) 2012  Nic Ferrier

;; Author: Nic Ferrier <nferrier@ferrier.me.uk>
;; Keywords: hypermedia

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; A pastebin with Elnode.

;;; Code:

(elnode-app pasteel/dir elnode esxml creole uuid)

(defun pasteel-bin (httpcon)
  (elnode-method httpcon
    (GET
     (elnode-send-file httpcon (concat pasteel/dir "pasteel.html")))
    (POST
     (let* ((params (elnode-http-params httpcon "text" "type"))
            (text (aget params "text"))
            (type (aget params "type"))
            (uuid (uuid-string))
            (creole-text
             (format
              "= Your paste =\n\n{{{\n##! %s\n%s\n}}}\n"
              type
              text)))
       (elnode-http-start httpcon 200 `("Content-type" . "text/html"))
       (with-stdout-to-elnode httpcon
           (creole-wiki
            creole-text
            :destination t
            :css (concat pasteel/dir "pasteel.css")))))))

(defun pasteel-handler (httpcon)
  (elnode-hostpath-dispatcher
   httpcon
   `(("^[^/]*//pasteel.css$"
      . ,(elnode-make-send-file (concat pasteel/dir "pasteel.css")))
     ("^[^/]*/.*" . pasteel-bin))))

(provide 'pasteel)

;;; past.el ends here
