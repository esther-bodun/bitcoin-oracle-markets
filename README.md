# Bitcoin Oracle Markets Protocol

[![Stacks](https://img.shields.io/badge/Stacks-purple?logo=stacks&logoColor=white)](https://stacks.co)
[![Clarity](https://img.shields.io/badge/Clarity-3.0-blue)](https://docs.stacks.co/clarity)
[![License](https://img.shields.io/badge/License-ISC-green.svg)](LICENSE)

> An innovative decentralized prediction marketplace that transforms collective market sentiment into precise Bitcoin price forecasts through stake-weighted consensus mechanisms on the Stacks blockchain.

## 🎯 Overview

Bitcoin Oracle Markets revolutionizes price discovery by creating trustless prediction markets where participants stake STX tokens on Bitcoin price movements. The protocol combines oracle-verified price feeds with sophisticated reward algorithms to incentivize accurate predictions, featuring automated market resolution, proportional reward distribution, and configurable market parameters that adapt to changing market conditions.

Built with institutional-grade security and designed for seamless integration with Bitcoin's Layer 2 ecosystem, this protocol enables transparent, decentralized price prediction markets with verifiable outcomes.

## ✨ Key Features

- **🏛️ Trustless Infrastructure**: Fully decentralized prediction market without intermediaries
- **🔮 Oracle Integration**: Transparent settlement using verified Bitcoin price feeds
- **💰 Dynamic Rewards**: Sophisticated algorithms for proportional reward distribution
- **⏰ Flexible Markets**: Configurable timeframes and market parameters
- **🏦 Treasury Management**: Automated fee collection and protocol treasury
- **👥 Consensus Mechanisms**: Multi-participant stake-weighted predictions
- **🔒 Institutional Security**: Battle-tested smart contract security patterns
- **⚡ Bitcoin L2 Ready**: Optimized for Bitcoin Layer 2 ecosystem integration

## 🏗️ Architecture

### Core Components

```text
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Market        │    │   Position      │    │   Oracle        │
│   Management    │────│   Tracking      │────│   Integration   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Reward        │
                    │   Distribution  │
                    └─────────────────┘
```

### Data Structures

- **Markets**: Track opening/closing prices, stakes, and resolution status
- **Positions**: Record individual trader predictions and stake amounts
- **Oracle**: Manages price feed verification and market settlement

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) >= 2.0
- [Node.js](https://nodejs.org/) >= 18
- [Git](https://git-scm.com/)

### Installation

```bash
# Clone the repository
git clone https://github.com/esther-bodun/bitcoin-oracle-markets.git
cd bitcoin-oracle-markets

# Install dependencies
npm install

# Check contract syntax
clarinet check

# Run tests
npm test
```

### Development Setup

```bash
# Start Clarinet console
clarinet console

# Run tests with coverage
npm run test:report

# Watch mode for development
npm run test:watch
```

## 📖 Usage Guide

### Creating a Market

Markets can only be created by the protocol owner:

```clarity
;; Create a new prediction market
(contract-call? .bitcoin-oracle-markets create-market 
  u50000000000  ;; Initial Bitcoin price (in satoshis)
  u1000         ;; Start block
  u2000)        ;; End block
```

### Placing Predictions

Participants can stake STX on Bitcoin price direction:

```clarity
;; Place a bullish prediction
(contract-call? .bitcoin-oracle-markets place-prediction 
  u0            ;; Market ID
  "bull"        ;; Price direction
  u5000000)     ;; Stake amount (5 STX)

;; Place a bearish prediction  
(contract-call? .bitcoin-oracle-markets place-prediction
  u0            ;; Market ID
  "bear"        ;; Price direction  
  u3000000)     ;; Stake amount (3 STX)
```

### Market Resolution

Oracle resolves markets with final Bitcoin price:

```clarity
;; Oracle resolves the market
(contract-call? .bitcoin-oracle-markets resolve-market
  u0            ;; Market ID
  u52000000000) ;; Final Bitcoin price
```

### Claiming Rewards

Winners can claim their proportional rewards:

```clarity
;; Claim rewards for winning predictions
(contract-call? .bitcoin-oracle-markets claim-rewards u0)
```

## 🔧 Configuration

### Protocol Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| `minimum-stake` | 1,000,000 µSTX | Minimum stake per prediction (1 STX) |
| `protocol-fee-rate` | 300 (3%) | Platform fee on winnings |
| `oracle-address` | Set by owner | Authorized oracle for price feeds |

### Administrative Functions

```clarity
;; Update oracle address
(contract-call? .bitcoin-oracle-markets set-oracle 'NEW_ORACLE_ADDRESS)

;; Adjust minimum stake
(contract-call? .bitcoin-oracle-markets set-minimum-stake u2000000)

;; Update protocol fee (max 10%)
(contract-call? .bitcoin-oracle-markets set-protocol-fee u500)
```

## 📊 API Reference

### Public Functions

#### `create-market`

Creates a new Bitcoin price prediction market.

- **Parameters**: `initial-price`, `start-block`, `end-block`
- **Returns**: Market ID
- **Access**: Protocol owner only

#### `place-prediction`

Stakes STX tokens on Bitcoin price direction.

- **Parameters**: `market-id`, `price-direction`, `stake-amount`
- **Returns**: Success boolean
- **Access**: Any user with sufficient STX balance

#### `resolve-market`

Settles market with final Bitcoin price.

- **Parameters**: `market-id`, `final-price`  
- **Returns**: Success boolean
- **Access**: Authorized oracle only

#### `claim-rewards`

Claims proportional rewards from winning predictions.

- **Parameters**: `market-id`
- **Returns**: Net payout amount
- **Access**: Market participants with winning positions

### Read-Only Functions

#### `get-market-info`

Returns complete market information including stakes and resolution status.

#### `get-position`

Retrieves trader's position details for a specific market.

#### `get-treasury-balance`

Returns current protocol treasury balance.

#### `get-market-metrics`

Provides market analytics including volume and bull/bear ratios.

## 🧪 Testing

The protocol includes comprehensive test coverage:

```bash
# Run all tests
npm test

# Run with detailed reporting
npm run test:report

# Development mode with auto-reload
npm run test:watch

# Check contract syntax
clarinet check
```

### Test Coverage

- ✅ Market creation and validation
- ✅ Prediction placement and stake management
- ✅ Oracle integration and market resolution
- ✅ Reward calculation and distribution
- ✅ Administrative functions
- ✅ Error handling and edge cases
- ✅ Gas optimization verification

## 🔒 Security

### Security Features

- **Access Control**: Role-based permissions for sensitive operations
- **Input Validation**: Comprehensive parameter checking and bounds validation
- **Integer Overflow Protection**: Safe arithmetic operations throughout
- **Reentrancy Protection**: Proper state management and external call handling
- **Oracle Security**: Single authorized oracle with validation checks

### Audit Status

The protocol implements security best practices including:

- Fail-safe defaults
- Comprehensive error handling
- Minimal external dependencies
- Clear separation of concerns

## 🛣️ Roadmap

- [x] **Phase 1**: Core prediction market functionality
- [x] **Phase 2**: Oracle integration and automated settlement
- [x] **Phase 3**: Advanced reward distribution algorithms
- [ ] **Phase 4**: Multi-oracle support and price aggregation
- [ ] **Phase 5**: Governance token integration
- [ ] **Phase 6**: Cross-chain bridge compatibility
- [ ] **Phase 7**: Advanced market types (binary options, ranges)

## 🤝 Contributing

We welcome contributions from the community! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes and add tests
4. Ensure all tests pass (`npm test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Standards

- Follow Clarity best practices
- Include comprehensive tests for new features
- Update documentation for API changes
- Maintain backwards compatibility when possible

## 📄 License

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Documentation**: [Full API Documentation](docs/)
- **Stacks Explorer**: [View Contract](https://explorer.stacks.co/)
- **Community**: [Discord](https://discord.gg/stacks)
- **Support**: [GitHub Issues](https://github.com/esther-bodun/bitcoin-oracle-markets/issues)

## 🏆 Acknowledgments

- Stacks Foundation for the robust blockchain infrastructure
- Clarity language team for the secure smart contract platform
- Bitcoin community for inspiration and support
- Contributors and early adopters

