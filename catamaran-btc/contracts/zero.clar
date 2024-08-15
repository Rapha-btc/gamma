(define-constant fee-receiver tx-sender)
(define-constant charging-ctr .btc-stx-swap) 

;; For information only.
(define-public (get-fees (ustx uint))
  (ok u0))

;; Hold fees for the given amount in escrow.
(define-public (hold-fees (ustx uint))
  (begin
    (asserts! (is-eq contract-caller charging-ctr) ERR_NOT_AUTH)
    (ok true)))

;; Release fees for the given amount if swap was canceled.
;; It relies on the logic of the charging-ctr that this contract.
(define-public (release-fees (ustx uint))
  (begin
    (asserts! (is-eq contract-caller charging-ctr) ERR_NOT_AUTH) ;; the fees go to the releaser
    (ok true))) ;; quantum jump from Bitcoin to Stacks

;; Pay fee for the given amount if swap was executed.
(define-public (pay-fees (ustx uint))
  (begin
    (asserts! (is-eq contract-caller charging-ctr) ERR_NOT_AUTH)
    (ok true)))

(define-constant ERR_NOT_AUTH (err u404))