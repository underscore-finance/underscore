# Underscore Documentation

Welcome to the Underscore documentation. This guide provides comprehensive information about the Underscore protocol, which enables AI agents to operate in DeFi within user-defined boundaries.

## Documentation Structure

The documentation is organized into three main sections:

1. **Technical Reference**: Core concepts and architecture
2. **Developer Guides**: Step-by-step instructions for common tasks
3. **API Reference**: Detailed documentation for each contract

## Technical Reference

These documents explain the core concepts and architecture of the Underscore protocol:

- [**Core Components**](technical/CORE_COMPONENTS.md): Overview of the core smart contracts and their relationships
- [**Interfaces**](technical/INTERFACES.md): System interfaces and interaction patterns
- [**Legos**](technical/LEGOS.md): Modular protocol integrations for DeFi protocols

## Developer Guides

These guides provide step-by-step instructions for common tasks:

- [**Getting Started**](guides/GETTING_STARTED.md): Create your first User AI Wallet
- [**Testing Guide**](guides/TESTING.md): Test the Underscore system

## API Reference

Detailed documentation for each contract in the Underscore protocol:

- [**AgentFactory**](api/AgentFactory.md): Creates and manages user wallets and agents
- [**AgentTemplate**](api/AgentTemplate.md): Template for AI agents and their actions
- [**WalletConfig**](api/WalletConfig.md): Manages wallet configuration settings
- [**WalletFunds**](api/WalletFunds.md): Handles user funds management
- [**LegoRegistry**](api/LegoRegistry.md): Registry for DeFi protocol integrations with governance controls
- [**OracleRegistry**](api/OracleRegistry.md): Registry for price oracles with governance controls
- [**AddyRegistry**](api/AddyRegistry.md): Registry for system component addresses with governance controls
- [**PriceSheets**](api/PriceSheets.md): Handles price data and calculations
- [**LegoHelper**](api/LegoHelper.md): Helper functions for lego operations

## Registry and Governance System

The Underscore protocol implements a robust registry and governance system, with these key features:

1. **Two-Step Governance**: Critical operations require initiation followed by confirmation after a delay
2. **Registry Pattern**: Consistent implementation across all registries (Lego, Oracle, Address)
3. **Upgrade Path**: Secure mechanism for updating contract addresses and implementations
4. **Type Management**: Specialized handling for different component types (e.g., yield vs. DEX legos)

For more details on the governance mechanism, see the Core Components documentation.
