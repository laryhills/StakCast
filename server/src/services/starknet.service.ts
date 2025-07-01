import { RpcProvider, Contract, BigNumberish, num } from 'starknet';
// 
import { predictionHubContract, starknetProvider } from '../config/starknet';
import { felt252ToString } from '../utils/converters';
import { MarketType as PrismaMarketType } from '@prisma/client';

export class StarknetService {
    private readonly provider: RpcProvider;
    private readonly predictionHub: Contract;

    constructor() {
        this.provider = starknetProvider;
        this.predictionHub = predictionHubContract;
    }

    async getMarketDetailsFromContract(marketId: BigNumberish, marketType: number): Promise<any> {
        try {
            let marketData: any;
            let methodName: string;

            switch (marketType) {
                case 0:
                    methodName = 'get_prediction';
                    break;
                case 1:
                    methodName = 'get_crypto_prediction';
                    break;
                case 2:
                    methodName = 'get_sports_prediction';
                    break;
                case 3:
                    methodName = 'get_business_prediction';
                    break;
                default:
                    throw new Error(`Invalid market type (${marketType}) for contract query.`);
            }

            const response = await this.predictionHub.call(methodName, [marketId]);
            marketData = response; // Use response directly, or destructure if you know the shape

            const parsedMarket = {
                market_id: num.toBigInt(marketData.market_id),
                title: felt252ToString(marketData.title),
                description: felt252ToString(marketData.description),
                choice0Label: felt252ToString(marketData.choices.label0),
                choice1Label: felt252ToString(marketData.choices.label1),
                choice0Staked: num.toBigInt(marketData.choices.staked_amount0),
                choice1Staked: num.toBigInt(marketData.choices.staked_amount1),
                category: felt252ToString(marketData.category),
                image_url: felt252ToString(marketData.image_url),
                is_resolved: marketData.is_resolved,
                is_open: marketData.is_open,
                end_time: marketData.end_time,
                winning_choice: marketData.winning_choice.is_some ? marketData.winning_choice.v0 : null,
                total_pool: num.toBigInt(marketData.total_pool),
                creator: num.toHex(marketData.creator),
                market_type: marketType,
            };

            if (marketType === 1) {
                return {
                    ...parsedMarket,
                    comparison_type: marketData.comparison_type,
                    asset_key: felt252ToString(marketData.asset_key),
                    target_value: num.toBigInt(marketData.target_value),
                };
            } else if (marketType === 2) {
                return {
                    ...parsedMarket,
                    event_id: marketData.event_id,
                    team_flag: marketData.team_flag,
                };
            } else if (marketType === 3) {
                return {
                    ...parsedMarket,
                    event_id: marketData.event_id,
                };
            }
            return parsedMarket;

        } catch (error) {
            console.error(`Error fetching market ${marketId} (type ${marketType}) from contract:`, error);
            throw new Error(`Failed to fetch market details from contract.`);
        }
    }
}
