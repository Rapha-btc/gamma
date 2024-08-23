;; happy path, collat and make ask, take ask and simulate swap: good
;; attempting to simulate swap on expired height erroring 22 correctly
;; taking ask twice in a expired swap and happy path: good
;; tested re-updated when at take-ask
;; can't swap in coolddown: good
;; can't swap done swap: good
;; claim penalty of done swap after expiration, error u7: good
;; claim penatlty of done prior to expiration, error u11, reserved: good
;; take-ask stx sender and receiver the same: good u28
;; take swap of done swap, error u7: good
;; happy path designated receiver takes-ask: ok true
;; taking ask of already reserved u11: good
;; swapping already reserved swap u22: good
;; claiming penalty of reserved swap u11: good
;; swapping without the money (simulated) u1000: good
;; taking bid from wrong stx-receiver, no such offer u17: good
;; designated epxired swap takes bid: allowed: correctly reset expired height, correctly reset when/stx-receiver (cooldown after that correct)
;; taking bid that was taken thus deleted u17: good
;; claiming penalty before swapping: already reserved
;; taking bid with swap that is not private (none) happy path
;; claiming penalty of swap without penalty 21: good
;; claiming penalty of bid but bid not taken, trying to take from swap, no penalty 21: good
;; take bid made on my particular swap id ok true: good
;; take bid made on general (no swap id) that matches conditions ok true: good / and then immediately claiming penalty u11 reserved good
;; claiming penalty on behalf of stx-sender of the swap after expiration: penalty correctly transferred collateral intact ok true
;; taking bid from swap with no designated stx receiver: 
;; swapping without stx-receiver: u8 no stx receiver : good
;; making a bid to self: same sender error: good
;; taking bid from a bid that has none but different stx-sender:ERR_INVALID_STX_SENDER u12 good
;; taking bid from a bid that has none but same stx-sender: good
;; making bid with swap id but stx-sender is wrong: should not be allowed, but let's try taking it from correct sender differing from the one in bid: invalid sender
;; errored out if swap-id populated in make-bid, then stx-sender should match swap's

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  collateralize-and-make-ask 
  u30000000000 
  0x001497cae3c32126ba01bbd5a2823de67cedf398f1 
  u50000000 
  (some 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5))

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  collateralize-and-make-ask 
  u30000000000 
  0x001497cae3c32126ba01bbd5a2823de67cedf398f1 
  u50000000 
  none)

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  get-burn-block)

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc 
  mint-to  
  u100000000
  'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc 
  mint-to  
  u100000000
  'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate  
  claim-penalty u0)
  

::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
::get_assets_maps
::advance_chain_tip 14 7 14 3 7
::advance_chain_tip 100
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  take-ask
  u0)

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate
  simulate-swap
  u0)

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate
  get-swap
  u0)

;; trying to change the ask after it's taken
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  make-ask
  u0
  u40000000
  0x001497cae3c32126ba01bbd5a2823de67cedf398f1
  (some 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
  u100000000
  )

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  make-bid
  (some u0)
  (some 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
  (some u30000000000)
  u20000000
  )

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  make-bid
  none
  (some 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
  (some u30000000000)
  u20000000
  )

  (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  make-bid
  none
  none
  (some u30000000000)
  u20000000
  )


(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  take-bid
  u0
  (some u0)
  u20000000
  'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
  )

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  take-bid
  u0
  none
  u20000000
  'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
  )

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  take-bid
  u0
  none
  u20000000
  u100000000
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
  )

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  cancel-bid
    none
  )

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  cancel-bid
    (some u0)
  )

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  cancel-ask
    u0)

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
;; get-swap
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate
  get-swap
  u0)

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate
  get-bid
  u0)

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  claim-collateral
  u0)

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate
  simulate-swap
  u0)

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  submit-swap
  u0
  u100000
  0x00000000000000000000000000000000000000000000000000000000000000  ;; Corrected to 32 bytes
  {
    version: 0x01000000,
    ins: (list 
      {
        outpoint: {
          hash: 0x0000000000000000000000000000000000000000000000000000000000000000,
          index: 0x00000000
        },
        scriptSig: 0x,
        sequence: 0xffffffff
      }
    ),
    outs: (list 
      {
        value: 0x0000000000000000,
        scriptPubKey: 0x001497cae3c32126ba01bbd5a2823de67cedf398f1
      }
    ),
    locktime: 0x00000000
  }
  {
    tx-index: u0,
    hashes: (list 0x0000000000000000000000000000000000000000000000000000000000000000),
    tree-depth: u0
  }
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.fees
)

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  submit-swap-segwit
  u0  ;; id
  u100000  ;; height
  {  ;; wtx
    version: 0x01000000,
    ins: (list 
      {
        outpoint: {
          hash: 0x0000000000000000000000000000000000000000000000000000000000000000,
          index: 0x00000000
        },
        scriptSig: 0x,
        sequence: 0xffffffff
      }
    ),
    outs: (list 
      {
        value: 0x0000000000000000,
        scriptPubKey: 0x001497cae3c32126ba01bbd5a2823de67cedf398f1
      }
    ),
    locktime: 0x00000000
  }
  0x  ;; witness-data (1650 bytes)
  0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000  ;; header (80 bytes)
  u0  ;; tx-index
  u0  ;; tree-depth
  (list 0x0000000000000000000000000000000000000000000000000000000000000000)  ;; wproof (list of 14 32-byte buffers)
  0x0000000000000000000000000000000000000000000000000000000000000000  ;; witness-merkle-root (32 bytes)
  0x0000000000000000000000000000000000000000000000000000000000000000  ;; witness-reserved-value (32 bytes)
  0x  ;; ctx (1024 bytes)
  (list 0x0000000000000000000000000000000000000000000000000000000000000000)  ;; cproof (list of 14 32-byte buffers)
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.fees
)


