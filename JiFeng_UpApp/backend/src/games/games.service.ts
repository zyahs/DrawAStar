import { Injectable } from '@nestjs/common';
import { GameKind, Prisma } from '@prisma/client';
import { PrismaService } from '../common/prisma.service';
import { CreateGameRecordDto } from './games.dto';

@Injectable()
export class GamesService {
  constructor(private readonly prisma: PrismaService) {}

  async record(userId: string, dto: CreateGameRecordDto) {
    const addScore = Math.max(0, dto.score);
    const coinsGain = 5 + (dto.win === false ? 0 : 5) + Math.floor(addScore / 10) + (dto.difficulty || 0) * 3;

    return this.prisma.$transaction(async (tx) => {
      const record = await tx.gameRecord.create({
        data: {
          userId,
          kind: dto.kind,
          score: dto.score,
          difficulty: dto.difficulty || 0,
          durationMs: dto.durationMs || 0,
          win: dto.win !== false,
          extra: dto.extra as Prisma.InputJsonValue | undefined,
        },
      });

      const user = await tx.user.findUniqueOrThrow({ where: { id: userId } });
      const coins = user.coins + coinsGain;
      await tx.user.update({
        where: { id: userId },
        data: {
          coins,
          totalScore: user.totalScore + addScore,
          totalGames: user.totalGames + 1,
          level: this.levelForCoins(coins),
          lastActiveAt: new Date(),
        },
      });

      return record;
    });
  }

  leaderboard(kind: GameKind, take = 50) {
    return this.prisma.gameRecord.findMany({
      where: { kind },
      orderBy: [{ score: 'desc' }, { createdAt: 'asc' }],
      take: Math.min(Math.max(take, 1), 100),
      include: {
        user: {
          select: {
            id: true,
            displayName: true,
            avatarUrl: true,
            avatarSymbol: true,
            background: true,
          },
        },
      },
    });
  }

  configs() {
    return this.prisma.gameConfig.findMany({ orderBy: { key: 'asc' } });
  }

  private levelForCoins(coins: number) {
    let level = 1;
    while (this.coinsRequiredForLevel(level + 1) <= coins) {
      level++;
      if (level > 999) break;
    }
    return level;
  }

  private coinsRequiredForLevel(level: number) {
    if (level <= 1) return 0;
    const n = level - 1;
    return n * n * 50 + n * 50;
  }
}
