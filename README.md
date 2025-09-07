# 🌍 Blockchain-based Disaster Relief NFT Platform

Welcome to a transparent and impactful Web3 solution for disaster relief! This project addresses the real-world problem of opacity and inefficiency in charitable donations, particularly for communities affected by natural disasters like floods, earthquakes, or wildfires. By leveraging NFT auctions of art created by affected community members, funds are raised and distributed traceably on the Stacks blockchain using Clarity smart contracts. Proceeds are channeled directly to rebuilding efforts, ensuring donors can track every step—no middlemen, no corruption.

## ✨ Features

🎨 Mint NFTs from community-submitted art  
💰 Auction NFTs with automated bidding and settlement  
🔍 Traceable fund distribution to verified rebuilding projects  
🛡️ Artist verification to ensure authenticity from affected areas  
📊 Governance for community voting on fund allocation  
🔄 Royalty system for ongoing artist support  
✅ Immutable audit trails for all transactions  
🚫 Anti-fraud measures to prevent duplicate or fake submissions

## 🛠 How It Works

This platform uses 8 Clarity smart contracts to create a secure, decentralized ecosystem. Here's a high-level overview:

### Smart Contracts Overview
1. **ArtistRegistry.clar**: Registers and verifies artists from affected communities (e.g., via simple proof-of-residency hashes or admin approval).  
2. **NFTMinter.clar**: Handles minting of NFTs from uploaded art hashes, linking them to verified artists.  
3. **AuctionHouse.clar**: Manages NFT auctions with timed bidding, highest-bid tracking, and automatic winner selection.  
4. **EscrowVault.clar**: Holds auction proceeds in escrow until the auction ends, ensuring secure fund handling.  
5. **FundDistributor.clar**: Distributes funds to predefined rebuilding wallets or projects, with transparent release conditions (e.g., milestones).  
6. **GovernanceDAO.clar**: Allows token holders (e.g., donors or artists) to vote on fund allocation proposals.  
7. **RoyaltySplitter.clar**: Enforces royalties on secondary NFT sales, splitting proceeds between artists and relief funds.  
8. **AuditLogger.clar**: Logs all key events immutably for public verification and compliance.

**For Artists (from Affected Communities)**  
- Register yourself via ArtistRegistry with a proof hash (e.g., location or ID anonymized).  
- Submit your art's SHA-256 hash, title, and description to NFTMinter to create an NFT.  
- List your NFT for auction using AuctionHouse, setting a starting bid and duration.  

Boom! Your art is tokenized and ready to raise funds.

**For Bidders/Donors**  
- Browse active auctions via AuctionHouse.  
- Place bids using STX (Stacks' native token).  
- If you win, funds go to EscrowVault, then automatically to FundDistributor for traceable release.  

Instant impact with full transparency.

**For Verifiers/Communities**  
- Use AuditLogger to check transaction histories and fund flows.  
- Participate in GovernanceDAO to propose or vote on how funds are used (e.g., "Allocate 50% to housing rebuild in Region X").  
- Verify artist authenticity through ArtistRegistry queries.  

That's it! Funds are tracked from auction to real-world rebuilding, solving trust issues in disaster aid.