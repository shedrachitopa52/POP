# 🌟 Proof of Presence (PoP) Smart Contract

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Platform: Stacks](https://img.shields.io/badge/Platform-Stacks-purple.svg)](https://www.stacks.co/)
[![Language: Clarity](https://img.shields.io/badge/Language-Clarity-blue.svg)](https://clarity-lang.org/)

A decentralized location-based check-in system that rewards users with NFTs and STX tokens for verifying their physical presence at specific locations.

## Features

- 📍 **Location-Based Check-ins**: Verify and record user presence at registered locations
- 🏆 **Dual Reward System**: 
  - NFT badges as proof of presence
  - STX token rewards for check-ins
- 🔒 **Security Features**:
  - Anti-duplicate check-in protection
  - Role-based access control
  - Secure treasury management
- 🎨 **SIP-009 NFT Standard**: Fully compliant with Stacks NFT standard

## Contract Functions

### User Functions

```clarity
;; Check in at a location
(check-in (location-id uint))

;; Transfer NFT to another user
(transfer (id uint) (sender principal) (recipient principal))

;; Get NFT metadata
(get-token-uri (id uint))
(get-owner (id uint))
```

### Admin Functions

```clarity
;; Location Management
(add-location (location-id uint) (name (string-ascii 40)) (reward-nft bool) (reward-stx (optional uint)))
(deactivate-location (location-id uint))

;; Admin Control
(set-admin (new-admin principal))

;; Treasury Management
(withdraw-stx (amount uint) (to principal))
```

## Development Setup

1. **Install Dependencies**
```bash
# Install Clarinet
curl --proto '=https' --tlsv1.2 -sSf https://sh.clarinet.com | sh

# Clone the repository
git clone https://github.com/yourusername/pop-contract
cd pop-contract
```

2. **Test the Contract**
```bash
clarinet test
```

3. **Deploy to Testnet**
```bash
clarinet deploy --testnet
```

## Usage Examples

### Adding a New Location
```clarity
(contract-call? .pop add-location 
    u1                           ;; location ID
    "Times Square"              ;; location name
    true                        ;; NFT reward enabled
    (some u1000))              ;; STX reward amount
```

### Checking In
```clarity
(contract-call? .pop check-in u1)
```

## Data Structures

### Location
```clarity
{
  name: (string-ascii 40),    ;; Location name
  active: bool,               ;; Location status
  reward-nft: bool,          ;; NFT reward flag
  reward-stx: (optional uint) ;; STX reward amount
}
```

## Error Codes

| Code | Description |
|------|-------------|
| `u100` | Not authorized |
| `u101` | Location not found |
| `u102` | Location inactive |
| `u103` | Already checked in |
| `u403` | Not token owner |
| `u404` | Token not found |

## Security Considerations

- Only admin can add/deactivate locations
- Users can only check in once per location
- STX transfers are protected with proper authorization
- NFT transfers require owner verification

## Testing

Run the test suite:
```bash
clarinet test tests/pop_test.clar
```





