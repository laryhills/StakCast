import { MigrationInterface, QueryRunner, Table } from "typeorm";

export class CreateMarketTable1751574987801 implements MigrationInterface {
    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.createTable(
            new Table({
                name: "markets",
                columns: [
                    { name: "market_id", type: "varchar", isPrimary: true, length: "255" },
                    { name: "title", type: "varchar" },
                    { name: "description", type: "varchar" },
                    { name: "marketType", type: "enum", enum: ["general", "crypto", "sports", "business"], default: "'general'" },
                    { name: "category", type: "varchar" },
                    { name: "imageUrl", type: "varchar" },
                    { name: "endTime", type: "bigint" },
                    { name: "isResolved", type: "boolean", default: false },
                    { name: "isOpen", type: "boolean", default: true },
                    { name: "winningChoice", type: "enum", enum: ["CHOICE_0", "CHOICE_1"], isNullable: true },
                    { name: "totalPool", type: "decimal", precision: 78, scale: 0, default: "'0'" },
                    { name: "creator", type: "varchar", length: "256" },
                    { name: "createdAt", type: "timestamp", default: "now()" },
                    { name: "updatedAt", type: "timestamp", default: "now()" },
                    { name: "choice0Label", type: "varchar" },
                    { name: "choice0Staked", type: "decimal", precision: 78, scale: 0, default: "'0'" },
                    { name: "choice1Label", type: "varchar" },
                    { name: "choice1Staked", type: "decimal", precision: 78, scale: 0, default: "'0'" },
                    { name: "comparisonType", type: "int", isNullable: true },
                    { name: "assetKey", type: "varchar", isNullable: true },
                    { name: "targetValue", type: "bigint", isNullable: true },
                    { name: "eventId", type: "bigint", isNullable: true },
                    { name: "teamFlag", type: "boolean", isNullable: true },
                ],
            })
        );
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.dropTable("markets");
    }
}
