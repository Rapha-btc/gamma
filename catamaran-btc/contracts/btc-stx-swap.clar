(use-trait fees-trait .fees-trait.fees-trait) ;; the fee structure is defined by the calling client

(define-constant ERR-OUT-OF-BOUNDS u4) ;; (err u1) -- sender does not have enough balance to transfer (err u2) -- sender and recipient are the same principal (err u3) -- amount to send is non-positive
(define-constant ERR_TX_VALUE_TOO_SMALL (err u5))
(define-constant ERR_TX_NOT_FOR_RECEIVER (err u6))
(define-constant ERR_ALREADY_DONE (err u7))
(define-constant ERR_NO_STX_RECEIVER (err u8))
(define-constant ERR_BTC_TX_ALREADY_USED (err u9)) ;; this needs to be used to prevent double claiming?
(define-constant ERR_IN_COOLDOWN (err u10))
(define-constant ERR_ALREADY_RESERVED (err u11))
(define-constant ERR_ONLY_STX_SENDER (err u12))
(define-constant ERR_INVALID_ID (err u13))
(define-constant ERR_FORBIDDEN (err u14))
(define-constant ERR_NOT_PRICED (err u15))
(define-constant ERR_NO_BTC_RECEIVER (err u16)) ;; this
(define-constant ERR_NO_SUCH_OFFER (err u17))
(define-constant ERR_WRONG_SATS (err u18))
(define-constant ERR_PREMIUM (err u19))
(define-constant ERR_INVALID_FEES_TRAIT (err u20))
(define-constant ERR_INVALID_STX_RECEIVER (err u21))
(define-constant ERR_OFFER_ALREADY_EXISTS (err u22)) ;; one offer at a time
(define-constant ERR_NATIVE_FAILURE (err u99)) ;; this is not necessary?
(define-constant nexus (as-contract tx-sender))
(define-constant expiry u100)
(define-constant cooldown u6)

(define-map swaps uint {sats: (optional uint), btc-receiver: (optional (buff 40)), ustx: uint, stx-receiver: (optional principal), stx-sender: principal, when: uint, done: bool, premium: (optional uint), priced: bool, fees: principal})
(define-map swap-offers {swap-id: uint, stx-receiver: principal} 
  {sats: uint, premium: uint})
(define-map submitted-btc-txs (buff 128) uint) ;; map between accepted btc txs and swap ids

(define-data-var next-id uint u0)

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

(define-public (collateralize-swap (ustx uint) (btc-receiver (optional (buff 40))) (stx-receiver (optional principal)) (fees <fees-trait>))
  (let ((id (var-get next-id)))
    (asserts! (map-insert swaps id
      {sats: none, btc-receiver: none, ustx: ustx, stx-receiver: none,
        stx-sender: tx-sender, when: burn-block-height, done: false, premium: none, priced: false, fees: (contract-of fees)}) ERR_INVALID_ID)
    (var-set next-id (+ id u1))
    (try! (contract-call? fees hold-fees ustx)) ;; memo?
    (match (stx-transfer? ustx tx-sender (as-contract tx-sender)) ;; memo?
      success (ok id)
      error (err (* error u1000)))))

(define-public (set-swap-price (id uint) (sats uint) (btc-receiver (buff 40)) (stx-receiver (optional principal)) (premium uint))
  (let ((swap (unwrap! (map-get? swaps id) ERR_INVALID_ID)))
    (asserts! (is-eq tx-sender (get stx-sender swap)) ERR_INVALID_STX_RECEIVER)
    (asserts! (not (get done swap)) ERR_ALREADY_DONE)
    (asserts! (is-none (get stx-receiver swap)) ERR_ALREADY_RESERVED)
    (asserts! (> burn-block-height (+ (get when swap) cooldown)) ERR_IN_COOLDOWN)
    (ok (map-set swaps id (merge swap {
      sats: (some sats), 
      btc-receiver: (some btc-receiver), 
      stx-receiver: stx-receiver,
      premium: (some premium), 
      priced: true})))))

(define-public (reserve-priced-swap (id uint)) ;; BTC sender accepts the initial offer of STX sender
  (let ((swap (unwrap! (map-get? swaps id) ERR_INVALID_ID))
    (premium (unwrap! (get premium swap) ERR_PREMIUM)))
    (asserts! (get priced swap) ERR_NOT_PRICED)
    (asserts! (> burn-block-height (+ (get when swap) cooldown)) ERR_IN_COOLDOWN) ;; redundant
    (asserts! (is-none (get stx-receiver swap)) ERR_ALREADY_RESERVED)
    (asserts! (not (get done swap)) ERR_ALREADY_DONE)
    (and (> premium u0) (try! (contract-call? .usda-token transfer premium tx-sender (get stx-sender swap) (some 0x707265746D69756D))))
    (ok (map-set swaps id (merge swap {stx-receiver: (some tx-sender), when: burn-block-height}))))) ;; expiration kicks in

(define-public (make-swap-offer (id uint) (sats uint) (premium uint)) ;; BTC sender makes an offer
  (let ((swap (unwrap! (map-get? swaps id) ERR_INVALID_ID)))
    (asserts! (is-none (get-swap-offer id tx-sender)) ERR_OFFER_ALREADY_EXISTS)
    (asserts! (is-none (get stx-receiver swap)) ERR_ALREADY_RESERVED)
    (asserts! (not (get done swap)) ERR_ALREADY_DONE)
    (asserts! (> burn-block-height (+ (get when swap) cooldown)) ERR_IN_COOLDOWN)
    (and (> premium u0) (try! (contract-call? .usda-token transfer premium tx-sender nexus (some 0x707265746D69756D))))
    (ok (map-set swap-offers {swap-id: id, stx-receiver: tx-sender} 
                 {sats: sats, premium: premium}))))

(define-public (accept-swap-offer (id uint) (sats uint) (premium uint) (stx-receiver principal))
  (let ((swap (unwrap! (map-get? swaps id) ERR_INVALID_ID))
        (offer (unwrap! (get-swap-offer id stx-receiver) ERR_NO_SUCH_OFFER)))
    (asserts! (is-eq sats (get sats offer)) ERR_WRONG_SATS)
    (asserts! (is-eq premium (get premium offer)) ERR_PREMIUM)
    (asserts! (is-eq tx-sender (get stx-sender swap)) ERR_ONLY_STX_SENDER)
    (asserts! (not (get done swap)) ERR_ALREADY_DONE)
    (asserts! (> burn-block-height (+ (get when swap) cooldown)) ERR_IN_COOLDOWN)
    (asserts! (is-none (get stx-receiver swap)) ERR_ALREADY_RESERVED)
    (and (> premium u0) (try! (as-contract (contract-call? .usda-token transfer premium tx-sender (get stx-sender swap) (some 0x707265746D69756D))))) ;; nexus releases premium
    (map-delete swap-offers {swap-id: id, stx-receiver: stx-receiver})
    (ok (map-set swaps id (merge swap {
      sats: (some sats), 
      premium: (some premium), 
      stx-receiver: (some stx-receiver),
      when: burn-block-height ;; expiration kicks in
    }))))) ;; do we need to delete all the offers in the map?

(define-public (cancel-offer (id uint))
  (let ((swap (unwrap! (map-get? swaps id) ERR_INVALID_ID))
        (offer (unwrap! (get-swap-offer id tx-sender) ERR_NO_SUCH_OFFER))
        (premium (get premium offer))
        (offerer tx-sender))
    (and (> premium u0) (as-contract (try! (contract-call? .usda-token transfer premium tx-sender offerer (some 0x707265746D69756D)))))
    (map-delete swap-offers {swap-id: id, stx-receiver: tx-sender})
    (ok true)))
    
(define-public (cancel-swap (id uint) (fees <fees-trait>)) ;; note that if the swap is not reserved, only the stx-sender can cancel
  (let ((swap (unwrap! (map-get? swaps id) ERR_INVALID_ID)))
    (asserts!
      (or
        (and (is-none (get stx-receiver swap)) (is-eq tx-sender (get stx-sender swap))) ;; stx-sender can cancel anytime if swap is not reserved
        (and (is-some (get stx-receiver swap)) (> burn-block-height (+ (get when swap) expiry))) ;; any user can cancel after the expiry period if swap was reserved
      ) 
        ERR_FORBIDDEN)
    (asserts! (is-eq (contract-of fees) (get fees swap)) ERR_INVALID_FEES_TRAIT) 
    (asserts! (not (get done swap)) ERR_ALREADY_DONE)
    (map-set swaps id (merge swap {done: true}))
    (try! (contract-call? fees release-fees (get ustx swap)))
    (as-contract (stx-transfer? (get ustx swap) tx-sender (get stx-sender swap)))))

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
    (proof { tx-index: uint, hashes: (list 12 (buff 32)), tree-depth: uint })
    (fees <fees-trait>)) ;; any user can submit a tx that contains the swap
  (let ((swap (unwrap! (map-get? swaps id) ERR_INVALID_ID))
        (tx-buff (contract-call? 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.clarity-bitcoin-helper concat-tx tx))
        (stx-receiver (unwrap! (get stx-receiver swap) ERR_NO_STX_RECEIVER))
        (btc-receiver (unwrap! (get btc-receiver swap) ERR_NO_BTC_RECEIVER)))
      (asserts! (is-eq tx-sender stx-receiver) ERR_INVALID_STX_RECEIVER)
      (asserts! (is-eq (contract-of fees) (get fees swap)) ERR_INVALID_FEES_TRAIT)
      (asserts! (not (get done swap)) ERR_ALREADY_DONE)
      (try! (contract-call? fees pay-fees (get ustx swap)))
      (match (contract-call? 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.clarity-bitcoin-lib-v5 was-tx-mined-compact
                height tx-buff blockheader proof )
        result
          (let
            ((sats (unwrap! (get sats swap) ERR_NOT_PRICED)))
            (asserts! (is-none (map-get? submitted-btc-txs result)) ERR_BTC_TX_ALREADY_USED)
            (match (get out (unwrap! (get-out-value tx btc-receiver) ERR_NATIVE_FAILURE))
              out (if (>= (get value out) sats)
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
    (cproof (list 14 (buff 32)))
    (fees <fees-trait>))
  (let ((swap (unwrap! (map-get? swaps id) ERR_INVALID_ID))
        (stx-receiver (unwrap! (get stx-receiver swap) ERR_NO_STX_RECEIVER))
        (btc-receiver (unwrap! (get btc-receiver swap) ERR_NO_BTC_RECEIVER))
        (sats (unwrap! (get sats swap) ERR_NOT_PRICED))
        (tx-buff (contract-call? .clarity-bitcoin-helper-wtx concat-wtx wtx witness-data)))
      (asserts! (is-eq tx-sender stx-receiver) ERR_INVALID_STX_RECEIVER)
      (asserts! (not (get done swap)) ERR_ALREADY_DONE)
      (asserts! (is-eq (contract-of fees) (get fees swap)) ERR_INVALID_FEES_TRAIT)
      (try! (contract-call? fees pay-fees (get ustx swap)))
      (match (contract-call? 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.clarity-bitcoin-lib-v5 was-segwit-tx-mined-compact
                height tx-buff header tx-index tree-depth wproof witness-merkle-root witness-reserved-value ctx cproof )
        result
          (begin
            (asserts! (is-none (map-get? submitted-btc-txs result)) ERR_BTC_TX_ALREADY_USED)
            (match (get out (unwrap! (get-out-value wtx btc-receiver) ERR_NATIVE_FAILURE))
              out (if (>= (get value out) sats)
                (begin
                      (map-set swaps id (merge swap {done: true}))
                      (map-set submitted-btc-txs result id)
                      (as-contract (stx-transfer? (get ustx swap) tx-sender (unwrap! (get stx-receiver swap) ERR_NO_STX_RECEIVER))))
                ERR_TX_VALUE_TOO_SMALL)
            ERR_TX_NOT_FOR_RECEIVER))
        error (err (* error u1000)))))

(define-read-only (get-swap (id uint)) ;; read-only function to get swap details by id
  (match (map-get? swaps id)
    swap (ok swap)
    (err ERR_INVALID_ID)))

(define-read-only (get-swap-offer (id uint) (stx-receiver principal))
  (map-get? swap-offers {swap-id: id, stx-receiver: stx-receiver}))