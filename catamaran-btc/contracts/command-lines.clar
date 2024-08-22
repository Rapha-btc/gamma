(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  collateralize-and-make-ask 
  u30000000000 
  0x001497cae3c32126ba01bbd5a2823de67cedf398f1 
  u50000000 
  none)

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc 
  mint-to  
  u100000000
  'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)

::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
::get_assets_maps
::advance_chain_tip 7
::advance_chain_tip 100
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  take-ask
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
  (some 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
  (some u30000000000)
  u20000000
  u100000000
  )

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  make-bid
  none
  none
  (some u30000000000)
  u20000000
  u100000000
  )

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  take-bid
  u0
  (some u0)
  u20000000
  u100000000
  'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
  )

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-stx-swap-simulate 
  take-bid
  u0
  none
  u20000000
  u100000000
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


