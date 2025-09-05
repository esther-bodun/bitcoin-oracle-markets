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