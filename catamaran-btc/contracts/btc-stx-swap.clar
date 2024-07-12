(define-constant ERR-OUT-OF-BOUNDS u1)
(define-constant ERR_VERIFICATION_FAILED (err u1))
(define-constant ERR_FAILED_TO_PARSE_TX (err u2))
(define-constant ERR_INVALID_ID (err u3))
(define-constant ERR_FORBIDDEN (err u4))
(define-constant ERR_TX_VALUE_TOO_SMALL (err u5))
(define-constant ERR_TX_NOT_FOR_RECEIVER (err u6))
(define-constant ERR_ALREADY_DONE (err u7))
(define-constant ERR_NO_STX_RECEIVER (err u8))
(define-constant ERR_BTC_TX_ALREADY_USED (err u9))
(define-constant ERR_IN_COOLDOWN (err u10))
(define-constant ERR_ALREADY_RESERVED (err u11))
(define-constant ERR_REPRICE_ALLOWED (err u12))
(define-constant ERR_NOT_ALLOWED_TO_REPRICE (err u13))
(define-constant ERR_NATIVE_FAILURE (err u99))

(define-constant expiry u100)
(define-constant cooldown u6)
(define-map swaps uint {sats: uint, btc-receiver: (buff 40), ustx: uint, stx-receiver: (optional principal), stx-sender: principal, when: uint, done: bool, premium: uint, allow-reprice: bool})
(define-data-var next-id uint u0)
;; map between accepted btc txs and swap id
(define-map submitted-btc-txs (buff 128) uint)

(define-read-only (read-uint32 (ctx { txbuff: (buff 4096), index: uint}))
		(let ((data (get txbuff ctx))
					(base (get index ctx)))
				(ok {uint32: (buff-to-uint-le (unwrap-panic (as-max-len? (unwrap! (slice? data base (+ base u4)) (err ERR-OUT-OF-BOUNDS)) u4))),
						 ctx: { txbuff: data, index: (+ u4 base)}})))

(define-private (find-out (entry {scriptPubKey: (buff 128), value: (buff 8)}) (result {pubscriptkey: (buff 40), out: (optional {scriptPubKey: (buff 128), value: uint})}))
  (if (is-eq (get scriptPubKey entry) (get pubscriptkey result))
    (merge result {out: (some {scriptPubKey: (get scriptPubKey entry), value: (get uint32 (unwrap-panic (read-uint32 {txbuff: (get value entry), index: u0})))})})
    result))


(define-public (get-out-value (tx {
    version: (buff 4),
    ins: (list 8
      {outpoint: {hash: (buff 32), index: (buff 4)}, scriptSig: (buff 256), sequence: (buff 4)}),
    outs: (list 8
      {value: (buff 8), scriptPubKey: (buff 128)}),
    locktime: (buff 4)}) (pubscriptkey (buff 40)))
    (ok (fold find-out (get outs tx) {pubscriptkey: pubscriptkey, out: none})))

;; create a swap between btc and stx
(define-public (offer-swap (sats uint) (btc-receiver (buff 40)) (ustx uint) (stx-receiver (optional principal)) (premium uint))
  (let ((id (var-get next-id)))
    (asserts! (map-insert swaps id
      {sats: sats, btc-receiver: btc-receiver, ustx: ustx, stx-receiver: stx-receiver,
        stx-sender: tx-sender, when: burn-block-height, done: false, premium: premium, allow-reprice: false}) ERR_INVALID_ID)
    (var-set next-id (+ id u1))
    (match (stx-transfer? ustx tx-sender (as-contract tx-sender))
      success (ok id)
      error (err (* error u1000)))))

;; Stx-sender can Toggle allow-reprice to true if the swap is not reserved
(define-public (allow-reprice-to-true (id uint))
  (let ((swap (unwrap! (map-get? swaps id) ERR_INVALID_ID)))
    (asserts! (is-eq tx-sender (get stx-sender swap)) ERR_FORBIDDEN)
    (asserts! (not (get done swap)) ERR_ALREADY_DONE)
    (asserts! (is-none (get stx-receiver swap)) ERR_ALREADY_RESERVED)
    (ok (map-set swaps id (merge swap {allow-reprice: true})))))

;; Repricing during search (of an stx-receiver) is allowed - as long as the swap is not done and the stx-receiver is none
;; after 6 blocks and until someone reserves swap (a long time can pass), stx-sender may want to re-price, and they don't need to re-escrow the STX and re-create a swap, they can re-price
;; Reprice-swap and Reserve-swap cannot happen in the same block someone reserves the swap?
(define-public (reprice-swap (id uint) (sats uint) (btc-receiver (buff 40)) (premium uint))
  (let ((swap (unwrap! (map-get? swaps id) ERR_INVALID_ID)))
    (asserts! (is-eq tx-sender (get stx-sender swap)) ERR_FORBIDDEN)
    (asserts! (not (get done swap)) ERR_ALREADY_DONE)
    (asserts! (is-none (get stx-receiver swap)) ERR_ALREADY_RESERVED)
    (asserts! (get allow-reprice swap) ERR_NOT_ALLOWED_TO_REPRICE)
    (ok (map-set swaps id (merge swap {sats: sats, btc-receiver: btc-receiver, premium: premium, allow-reprice: false})))))

(define-public (reserve-swap (id uint))
  (let ((swap (unwrap! (map-get? swaps id) ERR_INVALID_ID))
    (premium (get premium swap)))
    (asserts! (> burn-block-height (+ (get when swap) cooldown)) ERR_IN_COOLDOWN)
    (asserts! (is-none (get stx-receiver swap)) ERR_ALREADY_RESERVED)
    (asserts! (not (get done swap)) ERR_ALREADY_DONE)
    (asserts! (not (get allow-reprice swap)) ERR_REPRICE_ALLOWED)
    (and (> premium u0))
      (try! (stx-transfer? premium tx-sender (get stx-sender swap)))
    (ok (map-set swaps id (merge swap {stx-receiver: (some tx-sender), when: burn-block-height})))))

;; note that if the swap is not reserved, only the stx-sender can cancel
(define-public (cancel-swap (id uint))
  (let ((swap (unwrap! (map-get? swaps id) ERR_INVALID_ID)))
    (asserts!
      (or
        (and (is-none (get stx-receiver swap)) (is-eq tx-sender (get stx-sender swap))) ;; stx-sender can cancel anytime if swap is not reserved
        (and (is-some (get stx-receiver swap)) (> burn-block-height (+ (get when swap) expiry))) ;; any user can cancel after the expiry period if swap was reserved
      ) 
        ERR_FORBIDDEN) 
    (asserts! (not (get done swap)) ERR_ALREADY_DONE)
    (map-set swaps id (merge swap {done: true}))
    (as-contract (stx-transfer? (get ustx swap) tx-sender (get stx-sender swap)))))

;; any user can submit a tx that contains the swap
(define-public (submit-swap
    (id uint)
    (height uint)
    (blockheader (buff 32))
    (tx {version: (buff 4),
      ins: (list 8
        {outpoint: {hash: (buff 32), index: (buff 4)}, scriptSig: (buff 256), sequence: (buff 4)}),
      outs: (list 8
        {value: (buff 8), scriptPubKey: (buff 128)}),
      locktime: (buff 4)})
    (proof { tx-index: uint, hashes: (list 12 (buff 32)), tree-depth: uint }))
  (let ((swap (unwrap! (map-get? swaps id) ERR_INVALID_ID))
        (tx-buff (contract-call? 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.clarity-bitcoin-helper concat-tx tx))
        (stx-receiver (unwrap! (get stx-receiver swap) ERR_NO_STX_RECEIVER)))
      (asserts! (is-eq tx-sender stx-receiver) ERR_FORBIDDEN)
      (match (contract-call? 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.clarity-bitcoin-lib-v5 was-tx-mined-compact
                height tx-buff blockheader proof )
        result
          (begin
            (asserts! (is-none (map-get? submitted-btc-txs result)) ERR_BTC_TX_ALREADY_USED)
            (asserts! (not (get done swap)) ERR_ALREADY_DONE)
            (match (get out (unwrap! (get-out-value tx (get btc-receiver swap)) ERR_NATIVE_FAILURE))
              out (if (>= (get value out) (get sats swap))
                (begin
                      (map-set swaps id (merge swap {done: true}))
                      (map-set submitted-btc-txs result id)
                      (as-contract (stx-transfer? (get ustx swap) tx-sender (unwrap! (get stx-receiver swap) ERR_NO_STX_RECEIVER))))
                ERR_TX_VALUE_TOO_SMALL)
            ERR_TX_NOT_FOR_RECEIVER))
        error (err (* error u1000)))))


(define-public (submit-swap-segwit
    (id uint)
    (height uint)
    (wtx {version: (buff 4),
      ins: (list 8
        {outpoint: {hash: (buff 32), index: (buff 4)}, scriptSig: (buff 256), sequence: (buff 4)}),
      outs: (list 8
        {value: (buff 8), scriptPubKey: (buff 128)}),
      locktime: (buff 4)})
    (witness-data (buff 1650))
    (header (buff 80))
    (tx-index uint)
    (tree-depth uint)
    (wproof (list 14 (buff 32)))
    (witness-merkle-root (buff 32))
    (witness-reserved-value (buff 32))
    (ctx (buff 1024))
    (cproof (list 14 (buff 32))))
  (let ((swap (unwrap! (map-get? swaps id) ERR_INVALID_ID))
        (tx-buff (contract-call? .clarity-bitcoin-helper-wtx concat-wtx wtx witness-data)))
      (match (contract-call? 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.clarity-bitcoin-lib-v5 was-segwit-tx-mined-compact
                height tx-buff header tx-index tree-depth wproof witness-merkle-root witness-reserved-value ctx cproof )
        result
          (begin
            (asserts! (is-none (map-get? submitted-btc-txs result)) ERR_BTC_TX_ALREADY_USED)
            (asserts! (not (get done swap)) ERR_ALREADY_DONE)
            (match (get out (unwrap! (get-out-value wtx (get btc-receiver swap)) ERR_NATIVE_FAILURE))
              out (if (>= (get value out) (get sats swap))
                (begin
                      (map-set swaps id (merge swap {done: true}))
                      (map-set submitted-btc-txs result id)
                      (as-contract (stx-transfer? (get ustx swap) tx-sender (unwrap! (get stx-receiver swap) ERR_NO_STX_RECEIVER))))
                ERR_TX_VALUE_TOO_SMALL)
            ERR_TX_NOT_FOR_RECEIVER))
        error (err (* error u1000)))))
