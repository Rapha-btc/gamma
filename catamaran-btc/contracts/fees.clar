(define-constant fee-receiver tx-sender)
(define-constant charging-ctr .btc-stx-swap) 

;; For information only.
(define-public (get-fees (ustx uint))
  (ok (jump-fee ustx)))

(define-private (jump-fee (ustx uint))
  (if (> ustx u37500000000) ;; $75k+ (Whales)
    (/ ustx u200)           ;; 0.5% fee
    (if (> ustx u12500000000) ;; $25k-$75k
      (/ ustx u133)            ;; 0.75% fee
      (/ ustx u100))))         ;; $0-$25k: 1% fee

;; Hold fees for the given amount in escrow.
(define-public (hold-fees (ustx uint))
  (begin
    (asserts! (is-eq contract-caller charging-ctr) ERR_NOT_AUTH)
    (stx-transfer? (jump-fee ustx) tx-sender (as-contract tx-sender))))

;; Release fees for the given amount if swap was canceled.
;; It relies on the logic of the charging-ctr that this contract.
(define-public (release-fees (ustx uint))
  (let ((user tx-sender))
    (asserts! (is-eq contract-caller charging-ctr) ERR_NOT_AUTH) ;; the fees go to the releaser
    (as-contract (stx-transfer? (jump-fee ustx) tx-sender user)))) ;; quantum jump from Bitcoin to Stacks

;; Pay fee for the given amount if swap was executed.
(define-public (pay-fees (ustx uint))
  (let ((fee (jump-fee ustx)))
    (asserts! (is-eq contract-caller charging-ctr) ERR_NOT_AUTH)
    (if (> fee u0)
      (as-contract (stx-transfer? fee tx-sender fee-receiver))
      (ok true))))

(define-constant ERR_NOT_AUTH (err u404))