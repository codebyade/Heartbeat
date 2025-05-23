
;; title: challenge-management
;; version:
;; summary:
;; description:

;; Challenge Management Contract

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-challenge-not-found (err u101))
(define-constant err-already-participated (err u102))
(define-constant err-not-participant (err u103))
(define-constant err-challenge-ended (err u104))
(define-constant err-invalid-goal (err u105))

;; Define data maps
(define-map challenges
  { id: uint }
  {
    organizer: principal,
    name: (string-ascii 64),
    description: (string-ascii 256),
    start-time: uint,
    end-time: uint,
    goal: uint,
    token-reward: uint,
    participants: uint,
    total-completed: uint
  }
)

(define-map challenge-participants
  { challenge-id: uint, participant: principal }
  {
    joined: uint,
    completed: bool,
    progress: uint
  }
)

(define-map leaderboards
  { challenge-id: uint }
  {
    top-performers: (list 10 { participant: principal, score: uint })
  }
)

;; Define variables
(define-data-var challenge-counter uint u0)

;; Create a new challenge
(define-public (create-challenge (name (string-ascii 64)) (description (string-ascii 256)) (start-time uint) (end-time uint) (goal uint) (token-reward uint))
  (let
    (
      (challenge-id (+ (var-get challenge-counter) u1))
    )
    (asserts! (> end-time start-time) (err err-invalid-goal))
    (asserts! (> goal u0) (err err-invalid-goal))
    (map-set challenges
      { id: challenge-id }
      {
        organizer: tx-sender,
        name: name,
        description: description,
        start-time: start-time,
        end-time: end-time,
        goal: goal,
        token-reward: token-reward,
        participants: u0,
        total-completed: u0
      }
    )
    (var-set challenge-counter challenge-id)
    (ok challenge-id)
  )
)

;; Join a challenge
(define-public (join-challenge (challenge-id uint))
  (let
    (
      (challenge (unwrap! (map-get? challenges { id: challenge-id }) (err err-challenge-not-found)))
      (current-block stacks-block-height)
    )
    (asserts! (< current-block (get end-time challenge)) (err err-challenge-ended))
    (asserts! (is-none (map-get? challenge-participants { challenge-id: challenge-id, participant: tx-sender })) (err err-already-participated))
    (map-set challenge-participants
      { challenge-id: challenge-id, participant: tx-sender }
      {
        joined: current-block,
        completed: false,
        progress: u0
      }
    )
    (map-set challenges
      { id: challenge-id }
      (merge challenge { participants: (+ (get participants challenge) u1) })
    )
    (ok true)
  )
)

