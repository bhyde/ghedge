;; -*- lisp -*-

(in-package "GHEDGE")

(defvar *google-authentication-headers* '())

(defmacro google-api-authentication-header-value (service-keyword)
  `(getf *google-authentication-headers* ,service-keyword))

(defun google-client-login (user-email password service)
  (let ((service-mnemonic (getf '(:spreadsheets "wise"
                                  :docs "writely"
                                  :calendare "ci")
                                service)))
    (unless service-mnemonic
      (error "Unknown service keyword - ~S" service))
    (multiple-value-bind (doc status headers puri stream flag msg)
        (drakma:http-request "https://www.google.com/accounts/ClientLogin"
                             :parameters `(("accountType" . "")
                                           ("Email" . ,user-email)
                                           ("Passwd" . ,password)
                                           ("service" . ,service-mnemonic)
                                           ("source" . "ScienceComons-Gleaner-1.0")
                                        ;                         ("logintoken" . ,logintoken)
                                        ;                         ("logincaptcha" . ,capchaRespons)
                                           )
                             :method :post)
      (cond
        ((= 200 status)
         (multiple-value-bind (line creds)
             (cl-ppcre:scan-to-strings "SID=([\\w-]+)\\s+LSID=([\\w-]+)\\s+Auth=([\\w-]+)\\s+" doc)
           (unless (string= line doc)
             (error "Failed to match entire result"))
           (setf (google-api-authentication-header-value service)
                 (format nil "GoogleLogin auth=~A" (svref creds 2)))
           #+nil
           (list :sid (svref creds 0)
                 :lsid (svref creds 1)
                 :auth (svref creds 2))))
        (t
         (values doc status headers puri stream flag msg))))))

(defun google-api-request (service url &rest args)
  (multiple-value-bind (doc status-code headers puri stream flag status-msg)
      (apply #'drakma:http-request url :additional-headers `(("GData-Version" . "2.0")
                                                         ("Authorization" . ,(google-api-authentication-header-value service)))
         args)
    (unless (eq 200 status-code)
      (error "Bad result for api request ~S ~S ~S ~S ~S ~S ~S"
             doc status-code headers puri stream flag status-msg))))

(defun google-docs-full ()
  (cxml:parse 
   (google-api-request :docs "http://docs.google.com/feeds/default/private/full")
   (cxml-xmls:make-xmls-builder)))

(defun google-fetch-csv (doc-id)
  (google-api-request
   :spreadsheets
   "http://spreadsheets.google.com/feeds/download/spreadsheets/Export"
   :parameters `(("key" . ,doc-id )
                 ("exportFormat" . "csv"))))

#+nil ;; there are apparently bugs a plenty in PUT of a text/cvs ... so damn.
(defun google-put-csv (doc-id csv)
  (google-api-request
   :spreadsheets
   (format nil "http://spreadsheets.google.com/feeds/media/private/full/spreadsheet%3A~A"
           (subseq doc-id 12))
   :content-type "text/csv"
   :content csv))