import { PrismaClient } from '@prisma/client';
import {
    ApiMarket,
    MarketCreatedEvent,
    MarketResolvedEvent,
    WagerPlacedEvent,
    PrismaMarketType,
    ChoiceIndex,
} from '../types/backend.types';
import {
    u256ToDecimalString,
    u64ToDate,
    cairoChoiceIndexToPrisma,
    prismaMarketToApiMarket,
} from '../utils/converters';
import { BigNumberish, num } from 'starknet';
import Decimal from 'decimal.js';

const prisma = new PrismaClient();

export class MarketService {
    async createMarket(marketDetails: any, blockTimestamp: number): Promise<ApiMarket> {
        const newMarket = await prisma.market.create({
            data: {
                id: num.toHex(marketDetails.market_id),
                creator: num.toHex(marketDetails.creator),
                marketType: marketDetails.market_type,
                title: marketDetails.title,
                description: marketDetails.description,
                category: marketDetails.category,
                imageUrl: marketDetails.image_url,
                endTime: BigInt(marketDetails.end_time),
                isResolved: marketDetails.is_resolved,
                isOpen: marketDetails.is_open,
                totalPool: new Decimal(u256ToDecimalString(marketDetails.total_pool)),
                createdAt: u64ToDate(blockTimestamp),
                updatedAt: u64ToDate(blockTimestamp),
                choice0Label: marketDetails.choice0Label,
                choice0Staked: new Decimal(u256ToDecimalString(marketDetails.choice0Staked || 0)),
                choice1Label: marketDetails.choice1Label,
                choice1Staked: new Decimal(u256ToDecimalString(marketDetails.choice1Staked || 0)),
                comparisonType: marketDetails.comparison_type,
                assetKey: marketDetails.asset_key,
                targetValue: marketDetails.target_value ? BigInt(marketDetails.target_value) : null,
                eventId: marketDetails.event_id ? BigInt(marketDetails.event_id) : null,
                teamFlag: marketDetails.team_flag,
            },
        });
        return prismaMarketToApiMarket(newMarket);
    }

    async updateMarketResolution(event: MarketResolvedEvent, blockTimestamp: number): Promise<ApiMarket> {
        const marketIdHex = num.toHex(event.market_id);
        const winningChoicePrisma = cairoChoiceIndexToPrisma(event.winning_choice);

        const updatedMarket = await prisma.market.update({
            where: { id: marketIdHex },
            data: {
                isResolved: true,
                isOpen: false,
                winningChoice: winningChoicePrisma,
                updatedAt: u64ToDate(blockTimestamp),
            },
        });
        return prismaMarketToApiMarket(updatedMarket);
    }

    async updateMarketWager(event: WagerPlacedEvent, blockTimestamp: number): Promise<void> {
        const marketIdHex = num.toHex(event.market_id);
        const wagerAmount = new Decimal(u256ToDecimalString(event.amount));
        const choicePrisma = cairoChoiceIndexToPrisma(event.choice);

        const updateData: any = {
            totalPool: {
                increment: wagerAmount,
            },
        };

        if (choicePrisma === ChoiceIndex.CHOICE_0) {
            updateData.choice0Staked = {
                increment: wagerAmount,
            };
        } else {
            updateData.choice1Staked = {
                increment: wagerAmount,
            };
        }

        await prisma.market.update({
            where: { id: marketIdHex },
            data: updateData,
        });
    }

    async getMarkets(
        status?: 'open' | 'resolved' | 'all',
        marketType?: PrismaMarketType,
        category?: string,
        creator?: string,
        search?: string,
        limit?: number,
        offset?: number
    ): Promise<ApiMarket[]> {
        const where: any = {};

        if (status === 'open') {
            where.isOpen = true;
            where.isResolved = false;
        } else if (status === 'resolved') {
            where.isResolved = true;
        }

        if (marketType) {
            where.marketType = marketType;
        }
        if (category) {
            where.category = category;
        }
        if (creator) {
            where.creator = creator;
        }
        if (search) {
            where.OR = [
                { title: { contains: search, mode: 'insensitive' } },
                { description: { contains: search, mode: 'insensitive' } },
            ];
        }

        const markets = await prisma.market.findMany({
            where,
            take: limit,
            skip: offset,
            orderBy: {
                createdAt: 'desc',
            },
        });

        return markets.map(prismaMarketToApiMarket);
    }

    async getMarketById(marketId: string): Promise<ApiMarket | null> {
        const market = await prisma.market.findUnique({
            where: { id: marketId },
        });
        return market ? prismaMarketToApiMarket(market) : null;
    }
}
