;; (use-trait fungible-token .ft-trait.sip-010-trait)
(use-trait fungible-token .sip-010-trait-ft-standard.sip-010-trait)

(define-trait fees-trait
 ((get-fees (uint <fungible-token>) (response uint uint))
  (hold-fees (uint <fungible-token>) (response bool uint))
  (release-fees (uint <fungible-token> principal) (response bool uint))
  (pay-fees (uint <fungible-token>) (response bool uint))))