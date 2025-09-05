;; Title: Bitcoin Oracle Markets Protocol
;;
;; Summary: An innovative decentralized prediction marketplace that transforms 
;;          collective market sentiment into precise Bitcoin price forecasts through 
;;          stake-weighted consensus mechanisms on the Stacks blockchain.
;;
;; Description: Bitcoin Oracle Markets revolutionizes price discovery by creating 
;;              trustless prediction markets where participants stake STX tokens 
;;              on Bitcoin price movements. The protocol combines oracle-verified 
;;              price feeds with sophisticated reward algorithms to incentivize 
;;              accurate predictions. Features include automated market resolution,
;;              proportional reward distribution, and configurable market parameters
;;              that adapt to changing market conditions. Built with institutional-
;;              grade security and designed for seamless integration with Bitcoin's
;;              Layer 2 ecosystem.
;;
;; Key Features:
;;   - Trustless prediction market infrastructure
;;   - Oracle-verified transparent settlement
;;   - Dynamic reward distribution algorithms  
;;   - Configurable market timeframes and parameters
;;   - Automated fee collection and treasury management
;;   - Multi-participant consensus mechanisms

;; PROTOCOL CONSTANTS & ERROR DEFINITIONS

;; Administrative Authority
(define-constant PROTOCOL_OWNER tx-sender)

;; Error Code Registry
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_MARKET_NOT_FOUND (err u101))
(define-constant ERR_INVALID_PREDICTION (err u102))
(define-constant ERR_MARKET_CLOSED (err u103))
(define-constant ERR_REWARDS_CLAIMED (err u104))
(define-constant ERR_INSUFFICIENT_BALANCE (err u105))
(define-constant ERR_INVALID_PARAMETER (err u106))
(define-constant ERR_UNRESOLVED_MARKET (err u107))
(define-constant ERR_MARKET_RESOLVED (err u108))

;; PROTOCOL STATE VARIABLES

;; Oracle Configuration
(define-data-var oracle-address principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Market Parameters
(define-data-var minimum-stake uint u1000000) ;; 1 STX minimum stake
(define-data-var protocol-fee-rate uint u300) ;; 3% platform fee
(define-data-var market-counter uint u0) ;; Global market ID counter

;; DATA STRUCTURES

;; Market Configuration Schema
(define-map markets
  uint ;; market-id
  {
    opening-price: uint, ;; Bitcoin price at market creation
    closing-price: uint, ;; Final settlement price
    bull-stakes: uint, ;; Total stakes on price increase
    bear-stakes: uint, ;; Total stakes on price decrease
    start-height: uint, ;; Market activation block
    end-height: uint, ;; Market expiration block
    resolved: bool, ;; Settlement status
  }
)

;; Participant Position Registry
(define-map positions
  {
    market-id: uint,
    trader: principal,
  }
  {
    direction: (string-ascii 4), ;; "bull" or "bear"
    amount: uint, ;; Stake amount in STX
    claimed: bool, ;; Reward claim status
  }
)

;; CORE MARKET OPERATIONS

;; Initialize New Prediction Market
;; Creates a new Bitcoin price prediction market with specified parameters
(define-public (create-market
    (initial-price uint)
    (start-block uint)
    (end-block uint)
  )
  (let ((market-id (var-get market-counter)))
    ;; Validate authorization and parameters
    (asserts! (is-eq tx-sender PROTOCOL_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> end-block start-block) ERR_INVALID_PARAMETER)
    (asserts! (> initial-price u0) ERR_INVALID_PARAMETER)

    ;; Register new market
    (map-set markets market-id {
      opening-price: initial-price,
      closing-price: u0,
      bull-stakes: u0,
      bear-stakes: u0,
      start-height: start-block,
      end-height: end-block,
      resolved: false,
    })

    ;; Increment market counter
    (var-set market-counter (+ market-id u1))
    (ok market-id)
  )
)

;; Submit Price Prediction
;; Allows participants to stake STX tokens on Bitcoin price direction
(define-public (place-prediction
    (market-id uint)
    (price-direction (string-ascii 4))
    (stake-amount uint)
  )
  (let (
      (market (unwrap! (map-get? markets market-id) ERR_MARKET_NOT_FOUND))
      (current-block stacks-block-height)
    )
    ;; Validate market timing
    (asserts!
      (and
        (>= current-block (get start-height market))
        (< current-block (get end-height market))
      )
      ERR_MARKET_CLOSED
    )

    ;; Validate prediction parameters
    (asserts! (or (is-eq price-direction "bull") (is-eq price-direction "bear"))
      ERR_INVALID_PREDICTION
    )
    (asserts! (>= stake-amount (var-get minimum-stake)) ERR_INVALID_PARAMETER)
    (asserts! (<= stake-amount (stx-get-balance tx-sender))
      ERR_INSUFFICIENT_BALANCE
    )

    ;; Transfer stake to protocol vault
    (try! (stx-transfer? stake-amount tx-sender (as-contract tx-sender)))

    ;; Record participant position
    (map-set positions {
      market-id: market-id,
      trader: tx-sender,
    } {
      direction: price-direction,
      amount: stake-amount,
      claimed: false,
    })

    ;; Update market liquidity pools
    (map-set markets market-id
      (merge market {
        bull-stakes: (if (is-eq price-direction "bull")
          (+ (get bull-stakes market) stake-amount)
          (get bull-stakes market)
        ),
        bear-stakes: (if (is-eq price-direction "bear")
          (+ (get bear-stakes market) stake-amount)
          (get bear-stakes market)
        ),
      })
    )

    (ok true)
  )
)

;; Market Resolution
;; Oracle settles market with final Bitcoin price data
(define-public (resolve-market
    (market-id uint)
    (final-price uint)
  )
  (let ((market (unwrap! (map-get? markets market-id) ERR_MARKET_NOT_FOUND)))
    ;; Validate oracle authorization
    (asserts! (is-eq tx-sender (var-get oracle-address)) ERR_UNAUTHORIZED)
    (asserts! (>= stacks-block-height (get end-height market)) ERR_MARKET_CLOSED)
    (asserts! (not (get resolved market)) ERR_MARKET_RESOLVED)
    (asserts! (> final-price u0) ERR_INVALID_PARAMETER)

    ;; Finalize market with settlement price
    (map-set markets market-id
      (merge market {
        closing-price: final-price,
        resolved: true,
      })
    )

    (ok true)
  )
)

;; Reward Distribution
;; Winners claim proportional rewards from the total prize pool
(define-public (claim-rewards (market-id uint))
  (let (
      (market (unwrap! (map-get? markets market-id) ERR_MARKET_NOT_FOUND))
      (position (unwrap!
        (map-get? positions {
          market-id: market-id,
          trader: tx-sender,
        })
        ERR_MARKET_NOT_FOUND
      ))
    )
    ;; Validate claim eligibility
    (asserts! (get resolved market) ERR_UNRESOLVED_MARKET)
    (asserts! (not (get claimed position)) ERR_REWARDS_CLAIMED)

    (let (
        (price-rose (> (get closing-price market) (get opening-price market)))
        (winning-side (if price-rose
          "bull"
          "bear"
        ))
        (total-stakes (+ (get bull-stakes market) (get bear-stakes market)))
        (winning-stakes (if price-rose
          (get bull-stakes market)
          (get bear-stakes market)
        ))
      )
      ;; Verify winning prediction
      (asserts! (is-eq (get direction position) winning-side)
        ERR_INVALID_PREDICTION
      )

      (let (
          (gross-payout (/ (* (get amount position) total-stakes) winning-stakes))
          (protocol-fee (/ (* gross-payout (var-get protocol-fee-rate)) u10000))
          (net-payout (- gross-payout protocol-fee))
        )
        ;; Execute reward distribution
        (try! (as-contract (stx-transfer? net-payout (as-contract tx-sender) tx-sender)))
        (try! (as-contract (stx-transfer? protocol-fee (as-contract tx-sender) PROTOCOL_OWNER)))

        ;; Mark rewards as claimed
        (map-set positions {
          market-id: market-id,
          trader: tx-sender,
        }
          (merge position { claimed: true })
        )

        (ok net-payout)
      )
    )
  )
)

;; QUERY FUNCTIONS

;; Retrieve Market Information
(define-read-only (get-market-info (market-id uint))
  (map-get? markets market-id)
)

;; Get Trader Position Details  
(define-read-only (get-position
    (market-id uint)
    (trader principal)
  )
  (map-get? positions {
    market-id: market-id,
    trader: trader,
  })
)

;; Protocol Treasury Balance
(define-read-only (get-treasury-balance)
  (stx-get-balance (as-contract tx-sender))
)

;; Market Analytics
(define-read-only (get-market-metrics (market-id uint))
  (match (map-get? markets market-id)
    market-data (let ((total-volume (+ (get bull-stakes market-data) (get bear-stakes market-data))))
      (some {
        volume: total-volume,
        bull-ratio: (if (> total-volume u0)
          (/ (* (get bull-stakes market-data) u100) total-volume)
          u0
        ),
        bear-ratio: (if (> total-volume u0)
          (/ (* (get bear-stakes market-data) u100) total-volume)
          u0
        ),
      })
    )
    none
  )
)

;; ADMINISTRATIVE FUNCTIONS

;; Update Oracle Provider
(define-public (set-oracle (new-oracle principal))
  (begin
    (asserts! (is-eq tx-sender PROTOCOL_OWNER) ERR_UNAUTHORIZED)
    (var-set oracle-address new-oracle)
    (ok true)
  )
)

;; Adjust Minimum Stake Requirement
(define-public (set-minimum-stake (new-minimum uint))
  (begin
    (asserts! (is-eq tx-sender PROTOCOL_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> new-minimum u0) ERR_INVALID_PARAMETER)
    (var-set minimum-stake new-minimum)
    (ok true)
  )
)

;; Update Protocol Fee Structure
(define-public (set-protocol-fee (new-fee-rate uint))
  (begin
    (asserts! (is-eq tx-sender PROTOCOL_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= new-fee-rate u1000) ERR_INVALID_PARAMETER) ;; Maximum 10%
    (var-set protocol-fee-rate new-fee-rate)
    (ok true)
  )
)

;; Treasury Management
(define-public (withdraw-treasury (amount uint))
  (begin
    (asserts! (is-eq tx-sender PROTOCOL_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= amount (stx-get-balance (as-contract tx-sender)))
      ERR_INSUFFICIENT_BALANCE
    )
    (try! (as-contract (stx-transfer? amount (as-contract tx-sender) PROTOCOL_OWNER)))
    (ok amount)
  )
)
