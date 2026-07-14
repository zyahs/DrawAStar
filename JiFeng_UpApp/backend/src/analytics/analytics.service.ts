import { Injectable } from '@nestjs/common';
import { GameKind, Prisma } from '@prisma/client';
import { PrismaService } from '../common/prisma.service';
import { AnalyticsEventDto } from './analytics.dto';

type GameMetricAccumulator = {
  kind: GameKind;
  clicks: number;
  clickUsers: Set<string>;
  sessions: number;
  users: Set<string>;
  completedSessions: number;
  abandonedSessions: number;
  endedSessions: number;
  durationMs: number;
  rounds: number;
  roundUsers: Set<string>;
  userSessionCounts: Map<string, number>;
};

@Injectable()
export class AnalyticsService {
  private readonly timezoneOffsetMs = 8 * 60 * 60 * 1000;

  constructor(private readonly prisma: PrismaService) {}

  async ingest(userId: string, events: AnalyticsEventDto[]) {
    const deduped = [...new Map(events.map((event) => [event.eventId, event])).values()];
    const existing = await this.prisma.analyticsEvent.findMany({
      where: { eventId: { in: deduped.map((event) => event.eventId) } },
      select: { eventId: true },
    });
    const existingIds = new Set(existing.map((event) => event.eventId));
    const fresh = deduped.filter((event) => !existingIds.has(event.eventId));

    if (fresh.length === 0) {
      return { accepted: 0, duplicates: events.length };
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.analyticsEvent.createMany({
        data: fresh.map((event) => ({
          eventId: event.eventId,
          userId,
          appSessionId: event.appSessionId,
          gameSessionId: event.gameSessionId,
          name: event.name,
          kind: event.kind,
          platform: event.platform,
          appVersion: event.appVersion,
          properties: event.properties as Prisma.InputJsonValue | undefined,
          occurredAt: this.normalizedDate(event.occurredAt),
        })),
        skipDuplicates: true,
      });

      for (const event of fresh.sort((a, b) => a.occurredAt.localeCompare(b.occurredAt))) {
        await this.applySessionEvent(tx, userId, event);
      }

      await tx.user.update({
        where: { id: userId },
        data: { lastActiveAt: new Date() },
      });
    });

    return {
      accepted: fresh.length,
      duplicates: events.length - fresh.length,
    };
  }

  async overview(requestedDays: number) {
    const days = this.clampDays(requestedDays);
    const now = new Date();
    const today = this.dayStart(now, 0);
    const week = this.dayStart(now, 6);
    const month = this.dayStart(now, 29);
    const rangeStart = this.dayStart(now, days - 1);
    const activityStart = rangeStart < month ? rangeStart : month;

    const [appSessions, gameSessions, rangeUsers, totalUsers] = await Promise.all([
      this.prisma.appSession.findMany({
        where: { startedAt: { gte: activityStart } },
        select: { userId: true, startedAt: true, endedAt: true, durationMs: true },
      }),
      this.prisma.gameSession.findMany({
        where: { startedAt: { gte: rangeStart } },
        select: { startedAt: true, endedAt: true, durationMs: true, completed: true },
      }),
      this.prisma.user.findMany({
        where: { createdAt: { gte: rangeStart } },
        select: { createdAt: true },
      }),
      this.prisma.user.count(),
    ]);

    const activeUsersSince = (start: Date) => new Set(
      appSessions.filter((session) => session.startedAt >= start).map((session) => session.userId),
    ).size;
    const rangedAppSessions = appSessions.filter((session) => session.startedAt >= rangeStart);
    const completedAppSessions = rangedAppSessions.filter((session) => session.endedAt && session.durationMs > 0);
    const endedGames = gameSessions.filter((session) => session.endedAt && session.durationMs > 0);
    const completedGames = gameSessions.filter((session) => session.completed).length;

    const trend = new Map<string, {
      activeUsers: Set<string>;
      appSessions: number;
      gameSessions: number;
      newUsers: number;
    }>();
    for (let index = days - 1; index >= 0; index--) {
      trend.set(this.dayKey(this.dayStart(now, index)), {
        activeUsers: new Set<string>(),
        appSessions: 0,
        gameSessions: 0,
        newUsers: 0,
      });
    }
    for (const session of rangedAppSessions) {
      const bucket = trend.get(this.dayKey(session.startedAt));
      if (!bucket) continue;
      bucket.activeUsers.add(session.userId);
      bucket.appSessions++;
    }
    for (const session of gameSessions) {
      const bucket = trend.get(this.dayKey(session.startedAt));
      if (bucket) bucket.gameSessions++;
    }
    for (const user of rangeUsers) {
      const bucket = trend.get(this.dayKey(user.createdAt));
      if (bucket) bucket.newUsers++;
    }

    return {
      generatedAt: now.toISOString(),
      rangeDays: days,
      metrics: {
        dau: activeUsersSince(today),
        wau: activeUsersSince(week),
        mau: activeUsersSince(month),
        totalUsers,
        newUsers: rangeUsers.length,
        appSessions: rangedAppSessions.length,
        averageAppSessionDurationMs: this.average(completedAppSessions.map((session) => session.durationMs)),
        gameSessions: gameSessions.length,
        completedGameSessions: completedGames,
        gameCompletionRate: gameSessions.length > 0 ? completedGames / gameSessions.length : 0,
        averageGameDurationMs: this.average(endedGames.map((session) => session.durationMs)),
        totalGameDurationMs: endedGames.reduce((sum, session) => sum + session.durationMs, 0),
      },
      trend: [...trend.entries()].map(([day, bucket]) => ({
        day,
        activeUsers: bucket.activeUsers.size,
        appSessions: bucket.appSessions,
        gameSessions: bucket.gameSessions,
        newUsers: bucket.newUsers,
      })),
    };
  }

  async gameMetrics(requestedDays: number) {
    const days = this.clampDays(requestedDays);
    const since = this.dayStart(new Date(), days - 1);
    const [sessions, clicks, records] = await Promise.all([
      this.prisma.gameSession.findMany({
        where: { startedAt: { gte: since } },
        select: {
          userId: true,
          kind: true,
          endedAt: true,
          durationMs: true,
          completed: true,
        },
      }),
      this.prisma.analyticsEvent.findMany({
        where: { name: 'game_card_click', occurredAt: { gte: since }, kind: { not: null } },
        select: { userId: true, kind: true },
      }),
      this.prisma.gameRecord.findMany({
        where: { createdAt: { gte: since } },
        select: { userId: true, kind: true },
      }),
    ]);

    const metrics = new Map<GameKind, GameMetricAccumulator>();
    const bucketFor = (kind: GameKind) => {
      let bucket = metrics.get(kind);
      if (!bucket) {
        bucket = {
          kind,
          clicks: 0,
          clickUsers: new Set<string>(),
          sessions: 0,
          users: new Set<string>(),
          completedSessions: 0,
          abandonedSessions: 0,
          endedSessions: 0,
          durationMs: 0,
          rounds: 0,
          roundUsers: new Set<string>(),
          userSessionCounts: new Map<string, number>(),
        };
        metrics.set(kind, bucket);
      }
      return bucket;
    };

    for (const click of clicks) {
      if (!click.kind) continue;
      const bucket = bucketFor(click.kind);
      bucket.clicks++;
      bucket.clickUsers.add(click.userId);
    }
    for (const session of sessions) {
      const bucket = bucketFor(session.kind);
      bucket.sessions++;
      bucket.users.add(session.userId);
      bucket.userSessionCounts.set(session.userId, (bucket.userSessionCounts.get(session.userId) || 0) + 1);
      if (session.completed) bucket.completedSessions++;
      if (session.endedAt) {
        bucket.endedSessions++;
        bucket.durationMs += Math.max(0, session.durationMs);
        if (!session.completed) bucket.abandonedSessions++;
      }
    }
    for (const record of records) {
      const bucket = bucketFor(record.kind);
      bucket.rounds++;
      bucket.roundUsers.add(record.userId);
    }

    return {
      generatedAt: new Date().toISOString(),
      rangeDays: days,
      games: [...metrics.values()]
        .map((bucket) => ({
          kind: bucket.kind,
          clicks: bucket.clicks,
          clickUsers: bucket.clickUsers.size,
          sessions: bucket.sessions,
          uniqueUsers: bucket.users.size,
          repeatUsers: [...bucket.userSessionCounts.values()].filter((count) => count > 1).length,
          completedSessions: bucket.completedSessions,
          abandonedSessions: bucket.abandonedSessions,
          rounds: bucket.rounds,
          roundUsers: bucket.roundUsers.size,
          completionRate: bucket.sessions > 0 ? bucket.completedSessions / bucket.sessions : 0,
          abandonRate: bucket.sessions > 0 ? bucket.abandonedSessions / bucket.sessions : 0,
          averageDurationMs: bucket.endedSessions > 0 ? Math.round(bucket.durationMs / bucket.endedSessions) : 0,
          totalDurationMs: bucket.durationMs,
        }))
        .sort((a, b) => b.sessions - a.sessions || b.clicks - a.clicks || b.rounds - a.rounds),
    };
  }

  private async applySessionEvent(
    tx: Prisma.TransactionClient,
    userId: string,
    event: AnalyticsEventDto,
  ) {
    const occurredAt = this.normalizedDate(event.occurredAt);
    const durationMs = this.numberProperty(event.properties, 'durationMs', 24 * 60 * 60 * 1000);

    if (event.name === 'app_session_start' || event.name === 'app_session_end') {
      const existing = await tx.appSession.findUnique({ where: { id: event.appSessionId } });
      if (existing && existing.userId !== userId) return;

      if (!existing) {
        await tx.appSession.create({
          data: {
            id: event.appSessionId,
            userId,
            platform: event.platform,
            appVersion: event.appVersion,
            startedAt: event.name === 'app_session_start'
              ? occurredAt
              : new Date(occurredAt.getTime() - durationMs),
            endedAt: event.name === 'app_session_end' ? occurredAt : undefined,
            durationMs: event.name === 'app_session_end' ? durationMs : 0,
          },
        });
      } else if (event.name === 'app_session_end') {
        await tx.appSession.update({
          where: { id: event.appSessionId },
          data: { endedAt: occurredAt, durationMs: Math.max(existing.durationMs, durationMs) },
        });
      }
      return;
    }

    if (!event.gameSessionId || !event.kind) return;
    if (!['game_start', 'game_finish', 'game_exit'].includes(event.name)) return;

    const existing = await tx.gameSession.findUnique({ where: { id: event.gameSessionId } });
    if (existing && existing.userId !== userId) return;
    const source = this.stringProperty(event.properties, 'source', 'home', 32);

    if (!existing) {
      const isStart = event.name === 'game_start';
      await tx.gameSession.create({
        data: {
          id: event.gameSessionId,
          userId,
          appSessionId: event.appSessionId,
          kind: event.kind,
          source,
          platform: event.platform,
          appVersion: event.appVersion,
          startedAt: isStart ? occurredAt : new Date(occurredAt.getTime() - durationMs),
          endedAt: event.name === 'game_exit' ? occurredAt : undefined,
          durationMs,
          completed: event.name === 'game_finish',
          win: event.name === 'game_finish' ? this.booleanProperty(event.properties, 'win') : undefined,
          score: event.name === 'game_finish' ? this.numberProperty(event.properties, 'score', 100000000) : undefined,
          difficulty: event.name === 'game_finish' ? this.numberProperty(event.properties, 'difficulty', 10) : undefined,
          exitReason: event.name === 'game_exit'
            ? this.stringProperty(event.properties, 'reason', 'unknown', 40)
            : undefined,
          properties: event.properties as Prisma.InputJsonValue | undefined,
        },
      });
      return;
    }

    if (event.name === 'game_finish') {
      await tx.gameSession.update({
        where: { id: event.gameSessionId },
        data: {
          completed: true,
          durationMs: Math.max(existing.durationMs, durationMs),
          win: this.booleanProperty(event.properties, 'win'),
          score: this.numberProperty(event.properties, 'score', 100000000),
          difficulty: this.numberProperty(event.properties, 'difficulty', 10),
          properties: event.properties as Prisma.InputJsonValue | undefined,
        },
      });
    } else if (event.name === 'game_exit') {
      await tx.gameSession.update({
        where: { id: event.gameSessionId },
        data: {
          endedAt: occurredAt,
          durationMs: Math.max(existing.durationMs, durationMs),
          exitReason: this.stringProperty(event.properties, 'reason', 'unknown', 40),
        },
      });
    }
  }

  private normalizedDate(value: string) {
    const parsed = new Date(value);
    const now = Date.now();
    const minimum = now - 30 * 24 * 60 * 60 * 1000;
    const maximum = now + 10 * 60 * 1000;
    if (!Number.isFinite(parsed.getTime()) || parsed.getTime() < minimum || parsed.getTime() > maximum) {
      return new Date(now);
    }
    return parsed;
  }

  private numberProperty(properties: Record<string, unknown> | undefined, key: string, max: number) {
    const value = properties?.[key];
    if (typeof value !== 'number' || !Number.isFinite(value)) return 0;
    return Math.min(Math.max(Math.round(value), 0), max);
  }

  private booleanProperty(properties: Record<string, unknown> | undefined, key: string) {
    const value = properties?.[key];
    return typeof value === 'boolean' ? value : undefined;
  }

  private stringProperty(
    properties: Record<string, unknown> | undefined,
    key: string,
    fallback: string,
    maxLength: number,
  ) {
    const value = properties?.[key];
    if (typeof value !== 'string') return fallback;
    const trimmed = value.trim();
    return trimmed.length > 0 ? trimmed.slice(0, maxLength) : fallback;
  }

  private clampDays(days: number) {
    if (!Number.isFinite(days)) return 30;
    return Math.min(Math.max(Math.round(days), 1), 90);
  }

  private dayStart(date: Date, daysAgo: number) {
    const shifted = new Date(date.getTime() + this.timezoneOffsetMs);
    const utc = Date.UTC(
      shifted.getUTCFullYear(),
      shifted.getUTCMonth(),
      shifted.getUTCDate() - daysAgo,
    );
    return new Date(utc - this.timezoneOffsetMs);
  }

  private dayKey(date: Date) {
    return new Date(date.getTime() + this.timezoneOffsetMs).toISOString().slice(0, 10);
  }

  private average(values: number[]) {
    if (values.length === 0) return 0;
    return Math.round(values.reduce((sum, value) => sum + value, 0) / values.length);
  }
}
