import { Request, Response, NextFunction } from 'express';
import { MarketService } from '../services/market.service';
import { StarknetService } from '../services/starknet.service';
import { CreateMarketRequest, PrismaMarketType } from '../types';
import { stringToFelt252, dateToU64 } from '../utils/converters';
import { predictionHubContract } from '../config/starknet';
import { BigNumberish } from 'starknet';

const marketService = new MarketService();
const starknetService = new StarknetService();

export class MarketController {
    async getMarkets(req: Request, res: Response, next: NextFunction) {
        try {
            const { status, type, category, creator, search, limit, offset } = req.query;
            const parsedLimit = limit ? parseInt(limit as string) : undefined;
            const parsedOffset = offset ? parseInt(offset as string) : undefined;
            let prismaMarketType: PrismaMarketType | undefined;
            if (typeof type === 'string') {
                switch (type.toLowerCase()) {
                    case 'general':
                        prismaMarketType = PrismaMarketType.GENERAL;
                        break;
                    case 'crypto':
                        prismaMarketType = PrismaMarketType.CRYPTO;
                        break;
                    case 'sports':
                        prismaMarketType = PrismaMarketType.SPORTS;
                        break;
                    case 'business':
                        prismaMarketType = PrismaMarketType.BUSINESS;
                        break;
                }
            }
            const markets = await marketService.getMarkets(
                status as 'open' | 'resolved' | 'all',
                prismaMarketType,
                category as string,
                creator as string,
                search as string,
                parsedLimit,
                parsedOffset
            );
            res.json(markets);
        } catch (error) {
            next(error);
        }
    }

    async getMarketById(req: Request, res: Response, next: NextFunction) {
        try {
            const { id } = req.params;
            const market = await marketService.getMarketById(id);
            if (market) {
                res.json(market);
            } else {
                res.status(404).send('Market not found');
            }
        } catch (error) {
            next(error);
        }
    }

    async createMarket(req: Request, res: Response, next: NextFunction) {
        const marketRequest: CreateMarketRequest = req.body;
        try {
            if (!marketRequest.title || !marketRequest.description || !marketRequest.choices || marketRequest.choices.length !== 2 || !marketRequest.type || !marketRequest.endTime) {
                return res.status(400).send('Missing required market creation fields.');
            }
            const commonArgs = [
                stringToFelt252(marketRequest.title),
                stringToFelt252(marketRequest.description),
                [stringToFelt252(marketRequest.choices[0]), stringToFelt252(marketRequest.choices[1])] as [BigNumberish, BigNumberish],
                stringToFelt252(marketRequest.category),
                stringToFelt252(marketRequest.imageUrl),
                dateToU64(new Date(marketRequest.endTime * 1000)),
            ];
            let contractCallArgs: (BigNumberish | boolean)[];
            let entrypoint: string;
            let marketTypeU8: number;
            switch (marketRequest.type) {
                case 'general':
                    entrypoint = 'create_prediction';
                    contractCallArgs = commonArgs;
                    marketTypeU8 = 0;
                    break;
                case 'crypto':
                    entrypoint = 'create_crypto_prediction';
                    const cryptoReq = marketRequest as CreateMarketRequest & { type: 'crypto' };
                    contractCallArgs = [
                        ...commonArgs,
                        cryptoReq.comparisonType,
                        stringToFelt252(cryptoReq.assetKey),
                        BigInt(cryptoReq.targetValue),
                    ];
                    marketTypeU8 = 1;
                    break;
                case 'sports':
                    entrypoint = 'create_sports_prediction';
                    const sportsReq = marketRequest as CreateMarketRequest & { type: 'sports' };
                    contractCallArgs = [
                        ...commonArgs,
                        sportsReq.eventId,
                        sportsReq.teamFlag,
                    ];
                    marketTypeU8 = 2;
                    break;
                case 'business':
                    entrypoint = 'create_business_prediction';
                    const businessReq = marketRequest as CreateMarketRequest & { type: 'business' };
                    contractCallArgs = [
                        ...commonArgs,
                        businessReq.eventId,
                    ];
                    marketTypeU8 = 3;
                    break;
                default:
                    return res.status(400).send('Invalid market type for creation.');
            }
            res.status(200).json({
                message: 'Market creation transaction data prepared for frontend.',
                contractAddress: predictionHubContract.address,
                entrypoint: entrypoint,
                calldata: contractCallArgs,
                marketType: marketTypeU8,
            });
        } catch (error) {
            next(error);
        }
    }
}
