import { RpcProvider, hash, num } from 'starknet';
import { starknetProvider, predictionHubContract } from '../config/starknet';
import { MarketService } from '../services/market.service';
import { StarknetService } from '../services/starknet.service';
import fs from 'fs';
import path from 'path';

const marketService = new MarketService();
const starknetService = new StarknetService();

const LAST_BLOCK_FILE = path.resolve(__dirname, '../../last_processed_block.txt');

function readLastProcessedBlock(): number {
    try {
        if (fs.existsSync(LAST_BLOCK_FILE)) {
            return parseInt(fs.readFileSync(LAST_BLOCK_FILE, 'utf-8').trim());
        }
    } catch (error) {
        console.error('Error reading last processed block file, starting from 0:', error);
    }
    return 0;
}

function writeLastProcessedBlock(blockNumber: number) {
    try {
        fs.writeFileSync(LAST_BLOCK_FILE, blockNumber.toString());
    } catch (error) {
        console.error('Error writing last processed block file:', error);
    }
}

const MARKET_CREATED_EVENT_HASH = hash.getSelectorFromName('MarketCreated');
const MARKET_RESOLVED_EVENT_HASH = hash.getSelectorFromName('MarketResolved');
const WAGER_PLACED_EVENT_HASH = hash.getSelectorFromName('WagerPlaced');

export async function startStarknetEventListener() {
    let lastProcessedBlock = readLastProcessedBlock();
    const POLLING_INTERVAL_MS = 10000;

    const fetchAndProcessEvents = async () => {
        try {
            const latestBlock = await starknetProvider.getBlock('latest');
            const newLatestBlockNumber = latestBlock.block_number;

            if (newLatestBlockNumber > lastProcessedBlock) {
                for (let blockNum = lastProcessedBlock + 1; blockNum <= newLatestBlockNumber; blockNum++) {
                    const block = await starknetProvider.getBlockWithTxHashes(blockNum);
                    const blockTimestamp = block.timestamp;

                    const { events } = await starknetProvider.getEvents({
                        address: predictionHubContract.address,
                        from_block: { block_number: blockNum },
                        to_block: { block_number: blockNum },
                        chunk_size: 100,
                    });

                    for (const event of events) {
                        const eventSelector = event.keys[0];
                        const txHash = event.transaction_hash;
                        try {
                            if (eventSelector === MARKET_CREATED_EVENT_HASH) {
                                const parsedEvents = predictionHubContract.parseEvents([event]);
                                const marketCreatedData = parsedEvents.MarketCreated?.[0];
                                if (marketCreatedData) {
                                    const fullMarketDetails = await starknetService.getMarketDetailsFromContract(
                                        marketCreatedData.market_id,
                                        marketCreatedData.market_type
                                    );
                                    await marketService.createMarket(fullMarketDetails, blockTimestamp);
                                }
                            } else if (eventSelector === MARKET_RESOLVED_EVENT_HASH) {
                                const parsedEvents = predictionHubContract.parseEvents([event]);
                                const marketResolvedData = parsedEvents.MarketResolved?.[0];
                                if (marketResolvedData) {
                                    await marketService.updateMarketResolution(marketResolvedData, blockTimestamp);
                                }
                            } else if (eventSelector === WAGER_PLACED_EVENT_HASH) {
                                const parsedEvents = predictionHubContract.parseEvents([event]);
                                const wagerPlacedData = parsedEvents.WagerPlaced?.[0];
                                if (wagerPlacedData) {
                                    await marketService.updateMarketWager(wagerPlacedData, blockTimestamp);
                                }
                            }
                        } catch (eventProcessingError) {
                            console.error(`Error processing event in TX ${txHash}:`, eventProcessingError);
                        }
                    }
                    writeLastProcessedBlock(blockNum);
                }
                lastProcessedBlock = newLatestBlockNumber;
            }
        } catch (error) {
            console.error('Error in Starknet event listener loop:', error);
        } finally {
            setTimeout(fetchAndProcessEvents, POLLING_INTERVAL_MS);
        }
    };
    fetchAndProcessEvents();
}
