import { BigNumberish, shortString, num } from 'starknet';
import { MarketType as PrismaMarketType, ChoiceIndex } from '../types';
import { ApiMarket } from '../types';
import { Market as PrismaMarket } from '@prisma/client';
import Decimal from 'decimal.js';

export function felt252ToString(felt: BigNumberish): string {
    if (typeof felt === 'string' && felt.startsWith('0x')) {
        return shortString.decodeShortString(felt);
    }
    return shortString.decodeShortString(num.toHex(felt));
}

export function stringToFelt252(str: string): BigNumberish {
    return shortString.encodeShortString(str);
}

export function u256ToDecimalString(value: BigNumberish): string {
    return value.toString();
}

export function u64ToDate(timestamp: number | BigInt): Date {
    return new Date(Number(timestamp) * 1000);
}

export function dateToU64(date: Date): number {
    return Math.floor(date.getTime() / 1000);
}

export function cairoMarketTypeToPrisma(type: number): PrismaMarketType {
    switch (type) {
        case 0:
            return PrismaMarketType.GENERAL;
        case 1:
            return PrismaMarketType.CRYPTO;
        case 2:
            return PrismaMarketType.SPORTS;
        case 3:
            return PrismaMarketType.BUSINESS;
        default:
            throw new Error(`Unknown market type: ${type}`);
    }
}

export function cairoChoiceIndexToPrisma(choice: number): ChoiceIndex {
    switch (choice) {
        case 0:
            return ChoiceIndex.CHOICE_0;
        case 1:
            return ChoiceIndex.CHOICE_1;
        default:
            throw new Error(`Unknown choice index: ${choice}`);
    }
}

export function prismaMarketToApiMarket(market: PrismaMarket): ApiMarket {
    return {
        id: market.id,
        title: market.title,
        description: market.description,
        marketType: market.marketType,
        category: market.category,
        imageUrl: market.imageUrl,
        endTime: Number(market.endTime) * 1000,
        isResolved: market.isResolved,
        isOpen: market.isOpen,
        winningChoice: market.winningChoice === ChoiceIndex.CHOICE_0 ? 0 : market.winningChoice === ChoiceIndex.CHOICE_1 ? 1 : undefined,
        totalPool: market.totalPool.toString(),
        creator: market.creator,
        createdAt: market.createdAt.getTime(),
        updatedAt: market.updatedAt.getTime(),
        choice0Label: market.choice0Label,
        choice0Staked: market.choice0Staked.toString(),
        choice1Label: market.choice1Label,
        choice1Staked: market.choice1Staked.toString(),
        ...(market.marketType === PrismaMarketType.CRYPTO && {
            comparisonType: market.comparisonType || undefined,
            assetKey: market.assetKey || undefined,
            targetValue: market.targetValue ? market.targetValue.toString() : undefined,
        }),
        ...(market.marketType === PrismaMarketType.SPORTS && {
            eventId: market.eventId ? Number(market.eventId) : undefined,
            teamFlag: market.teamFlag || undefined,
        }),
        ...(market.marketType === PrismaMarketType.BUSINESS && {
            eventId: market.eventId ? Number(market.eventId) : undefined,
        }),
    };
}
