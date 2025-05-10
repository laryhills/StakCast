
Product Requirements Document (PRD)
Project Name: StakCast
Prepared By: 
Last Updated: May 5, 2025


Updates Notes:




1. Introduction
StakCast is a prediction platform that allows users to purchase units in real-world prediction markets. Users earn rewards if they purchase units aligned with the correct outcome. StakCast uses StarkNet for transparency and auditability, enabling trustless resolution of future events.

2. Objectives
Enable users to create and participate in prediction markets


Facilitate unit-based market entry (no staking terminology)


Ensure on-chain validation and reward distribution


Capture and reflect public sentiment on key topics


Lay groundwork for token incentives and validator governance



3. Target Audience
Crypto enthusiasts


Gen Z & millennials


Public sentiment researchers


Forecasting analysts


Tech-savvy Web3 natives



4. User Personas
Market Creator
Initiates prediction markets on real-world events.
Market Participant
Purchases units in outcome(s) of a prediction market.
Validator
Confirms the final outcome of the market (admin in MVP, decentralized later).

5. Key Features
User Features
Feature
Description
Wallet Connection
Users connect or create a wallet
Market Creation
Define a question and potential outcomes
Market Participation
Buy prediction units tied to specific outcomes
Transaction History
View records of purchases and rewards
Reward Claiming
Redeem payout after a market is resolved
Account Deletion
Users can disconnect wallet and delete profile info (frontend only)


Business Requirements
Requirement
Description
Market Creation
Market with multiple outcomes and unit pricing
Unit Purchase Logic
Purchase fixed units per outcome
Market Resolution
Admin/Validator resolves market outcome
Funds Holding & Disbursement
Hold user purchases and release to winners after resolution
Reward Calculation
Proportional to unit ownership of the correct outcome


6. Technical Architecture
Frontend
Framework: TypeScript + Next.js


Features:


Wallet authentication (Braavos, ArgentX)


Create/join market interface


Purchase unit flow


Market view with outcome volumes


Claim and history panel


Backend / Smart Contracts
Language: Cairo (Starknet)


Responsibilities:


Market and outcome storage


Unit purchase tracking


Outcome resolution and reward logic


Events for market creation, unit purchase, resolution



7. Smart Contract Design
Core Contract: PredictionMarket.cairo
Modular layout:
Interface.cairo


Utils.cairo (optional)


Tests/ for full coverage


Key Functions
Function
Description
create_market()
Admin or user creates market with question and multiple outcomes
purchase_units()
User buys prediction units for a selected outcome
resolve_market()
Validator sets final correct outcome
claim_rewards()
Winning users claim rewards proportional to units held
get_markets()
View list of all open/closed markets
get_user_positions()
View how many units a user purchased per market/outcome


Storage Schema
markets: map<market_id, Market>


balances: map<wallet, map<market_id, map<outcome_id, units>>>


validators: map<address, bool>


outcomes: map<market_id, outcome_id>


total_units: map<market_id, map<outcome_id, total_units>>



Reward Distribution Formula
reward = (user_units / total_winning_units) × total_market_volume


8. Token Economics
Platform Token: SK


Unit Purchase Rate: $1 = SK1000


No fees or commissions in MVP


Smart contracts will not enforce fees; they are off-chain or deferred for now.



9. Revenue Model (Post-MVP)
Revenue Stream
Description
Market Creation Fees
Charge for setting up a new market (e.g. 1–2% fee)
Transaction Fees
Apply on unit purchases and cashouts
Validator Rewards
Funded by platform commissions or DAO treasury in future


10. User Growth & Adoption
Strategy
Description
Referral Bonuses
Give SK tokens for referring new users
Web3 Meetups
Host events and webinars on forecasting and predictions
Community Challenges
Run seasonal leaderboards and high-accuracy contests
Ads & Partnerships
Collaborate with influencers and DeFi platforms


11. Roadmap
Phase
Features
MVP
Basic unit purchase market + validator outcome resolution
v1.1
Token dashboard + custom outcome types
v1.2
Private markets and early market exit logic
v2.0
Fully decentralized validator system with on-chain disputes
v2.5
AI-integrated oracles + arbitrage detection and market auto-freezing


12. Key Questions & Suggested Answers
Question
Answer
Who provides liquidity?
Users fund market by buying units (no external LP needed for MVP)
Where are funds held?
On-chain, escrowed in the market contract until resolved
Can users exit early?
Not in MVP; future upgrade may allow secondary unit sales
How is reward calculated?
Based on unit ownership ratio among winners (see formula above)


13. Deployment Plan
Step 1: Local Development
Set up devnet for StarkNet


Write and test Cairo contract logic with mocked resolution


Step 2: Frontend Integration
Connect frontend to wallet (ArgentX, Braavos)


Render markets, enable unit purchase and claim flow


Step 3: StarkNet Testnet
Deploy contract to testnet


Connect frontend to testnet version


Gather test users, collect feedback


Step 4: Audit & Security Review
Internal review followed by third-party audit


Review upgradability and initialization logic


Step 5: Mainnet Launch
Deploy verified contract


Set up multisig for upgrades


Launch marketing campaign



14. Development Guidelines
Use simple types (u32, u64) to minimize serialization errors


Avoid u256 unless absolutely required


One upgradeable core contract


Deployment, upgrade, and rollback paths should be documented


Exclude all fee logic from MVP smart contracts



Would you like this PRD exported as a downloadable PDF, a Google Doc, or added to Notion or GitHub?

	USER FEATURES
	- can create account/wallet
	- create markets
	- view previous transactions 
	- stake on market
	- delete account
TECHNICAL COMPONENTS
-Frontend 
-Backend /Smart contract
	Detailed Components
	Frontend: 
	written in  Typescript and next.js
	it allows sign in/ sign
	view all wallets
	allows routing to other parts of the application 
	recent activity panel
	Backend/ Smart Contracts: 
		 written in Cairo
		- rewards logic,
		- issue rewards
REVENUE MODELS
 Transaction fees on stakes and withdrawals
 Market creation fees
TARGET AUDIENCE
crypto enthusiasts 
young individuals
People interested in viewing public sentiment
Analysts or consultants
Tech savvy individuals
USER ADOPTION STRATEGIES
	- Social media 
	-  Word of mouth
	- *Referral Bonuses
	- Webinars and meetups
	- Partnerships
 	- Ads

Future
Private market
Token integration
Full AI integration


Questions

Who provides the initial liquidity for the market?

How do we handle/track funds? Where should we keep it?

Should users be able to exit the market early?

Share calculation.

$1 = SK1000



	
	
Functions


Create market

Purchase units — Hardcode the token

Cashout - Claim/withdraw their investment to wallet to the wallet address that purchased.



2 ways
When a market is resolved


Helper functions(deposit from wallet etc)


Storage:

Markets: market_id and Market_Type
Balances: User balance tracking for market investors/creators etc (map of wallet and amount)
Validators: validators
Outcomes

Total stakes: The total volume so far in the market


Validators
Resolve a market — approval
Disputes




Getter functions
Getmarkets
Get balances
Get validators
Track loss and wins including amount/markets






Note: An answer in a market can have two options. 

In creating a market, we can allow creating a market with multiple outcomes.

For example,

Who will be the president of Nigeria in 2027


Outcomes -
Tinubu: Options (e.g yes. no)
Peter: Options (e.g yes, no)
Atiku: 
Fishon


In this scenario, each of the outcome volumes will be tracked and then the entire market.



Types
Prediction market.cairo

Interface.cairo

Utils.cairo (if needed)

Tests.

We should have one function.

Avoid using u256 where not necessary. Use less rigid types to avoid serialization issues.


One contract for prediction market. If except if extremely impossible

Remove fees and any stake token references in the contracts. We shouldn’t charge fees right now

The contract should be upgradeable. Clearly

Clear pattern of deployment and upgrades — documentation etc

A clear path to mainnet deployment










